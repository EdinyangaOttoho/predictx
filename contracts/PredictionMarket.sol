// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract PredictionMarket is ReentrancyGuard, Ownable, Pausable {
    struct Event {
        string title;
        uint256 startTime;
        uint256 endTime;
        uint256 totalStaked;
        bool resolved;
        bool outcome;
        mapping(bool => uint256) predictions; // true/false -> total amount
        mapping(address => Prediction) userPredictions;
    }

    struct Prediction {
        bool prediction;
        uint256 amount;
        bool claimed;
    }

    struct EventInfo {
        string title;
        uint256 startTime;
        uint256 endTime;
        uint256 totalStaked;
        bool resolved;
        bool outcome;
    }

    mapping(uint256 => Event) public events;
    uint256 public eventCount;
    uint256 public constant PLATFORM_FEE = 2; // 2% platform fee

    event EventCreated(uint256 indexed eventId, string title, uint256 startTime, uint256 endTime);
    event PredictionPlaced(uint256 indexed eventId, address indexed user, bool prediction, uint256 amount);
    event EventResolved(uint256 indexed eventId, bool outcome);
    event RewardsClaimed(uint256 indexed eventId, address indexed user, uint256 amount);

    constructor() Ownable(msg.sender) {}

    function createEvent(
        string memory _title,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime > block.timestamp, "Start time must be in the future");
        require(_endTime > _startTime, "End time must be after start time");

        uint256 eventId = eventCount++;
        Event storage newEvent = events[eventId];
        newEvent.title = _title;
        newEvent.startTime = _startTime;
        newEvent.endTime = _endTime;
        newEvent.resolved = false;

        emit EventCreated(eventId, _title, _startTime, _endTime);
    }

    function placePrediction(uint256 _eventId, bool _prediction) external payable nonReentrant whenNotPaused {
        Event storage predEvent = events[_eventId];
        require(block.timestamp >= predEvent.startTime, "Event not started");
        require(block.timestamp < predEvent.endTime, "Event ended");
        require(!predEvent.resolved, "Event already resolved");
        require(msg.value > 0, "Must stake some amount");
        require(predEvent.userPredictions[msg.sender].amount == 0, "Already predicted");

        predEvent.predictions[_prediction] += msg.value;
        predEvent.totalStaked += msg.value;
        predEvent.userPredictions[msg.sender] = Prediction({
            prediction: _prediction,
            amount: msg.value,
            claimed: false
        });

        emit PredictionPlaced(_eventId, msg.sender, _prediction, msg.value);
    }

    function resolveEvent(uint256 _eventId, bool _outcome) external onlyOwner {
        Event storage predEvent = events[_eventId];
        require(block.timestamp >= predEvent.endTime, "Event not ended");
        require(!predEvent.resolved, "Event already resolved");

        predEvent.resolved = true;
        predEvent.outcome = _outcome;

        emit EventResolved(_eventId, _outcome);
    }

    function claimRewards(uint256 _eventId) external nonReentrant {
        Event storage predEvent = events[_eventId];
        require(predEvent.resolved, "Event not resolved");
        
        Prediction storage userPred = predEvent.userPredictions[msg.sender];
        require(userPred.amount > 0, "No prediction made");
        require(!userPred.claimed, "Already claimed");
        require(userPred.prediction == predEvent.outcome, "Incorrect prediction");

        userPred.claimed = true;
        uint256 totalCorrectPredictions = predEvent.predictions[predEvent.outcome];
        uint256 reward = (predEvent.totalStaked * userPred.amount) / totalCorrectPredictions;
        
        // Apply platform fee
        uint256 platformFeeAmount = (reward * PLATFORM_FEE) / 100;
        uint256 userReward = reward - platformFeeAmount;

        (bool success, ) = msg.sender.call{value: userReward}("");
        require(success, "Transfer failed");

        emit RewardsClaimed(_eventId, msg.sender, userReward);
    }

    function getEvent(uint256 _eventId) external view returns (EventInfo memory) {
        Event storage predEvent = events[_eventId];
        return EventInfo({
            title: predEvent.title,
            startTime: predEvent.startTime,
            endTime: predEvent.endTime,
            totalStaked: predEvent.totalStaked,
            resolved: predEvent.resolved,
            outcome: predEvent.outcome
        });
    }

    function getUserPrediction(uint256 _eventId, address _user) 
        external 
        view 
        returns (bool prediction, uint256 amount, bool claimed) 
    {
        Prediction memory userPred = events[_eventId].userPredictions[_user];
        return (userPred.prediction, userPred.amount, userPred.claimed);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() external payable {}
}