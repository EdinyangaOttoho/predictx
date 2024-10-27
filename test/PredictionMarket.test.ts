import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { time } from "@nomicfoundation/hardhat-network-helpers";

describe("PredictionMarket", function () {
  async function deployFixture() {
    const [owner, user1, user2] = await ethers.getSigners();
    const PredictionMarket = await ethers.getContractFactory("PredictionMarket");
    const predictionMarket = await PredictionMarket.deploy();
    return { predictionMarket, owner, user1, user2 };
  }

  it("Should create an event", async function () {
    const { predictionMarket, owner } = await loadFixture(deployFixture);
    const startTime = await time.latest() + 3600; // 1 hour from now
    const endTime = startTime + 3600; // 2 hours from now

    await expect(predictionMarket.createEvent("Test Event", startTime, endTime))
      .to.emit(predictionMarket, "EventCreated")
      .withArgs(0, "Test Event", startTime, endTime);

    const event = await predictionMarket.getEvent(0);
    expect(event.title).to.equal("Test Event");
  });

  it("Should place a prediction", async function () {
    const { predictionMarket, owner, user1 } = await loadFixture(deployFixture);
    const startTime = await time.latest();
    const endTime = startTime + 3600;

    await predictionMarket.createEvent("Test Event", startTime, endTime);
    await time.increase(1); // Move past start time

    const predictionAmount = ethers.parseEther("1");
    await expect(predictionMarket.connect(user1).placePrediction(0, true, { value: predictionAmount }))
      .to.emit(predictionMarket, "PredictionPlaced")
      .withArgs(0, user1.address, true, predictionAmount);
  });

  it("Should resolve event and allow winners to claim", async function () {
    const { predictionMarket, owner, user1, user2 } = await loadFixture(deployFixture);
    const startTime = await time.latest();
    const endTime = startTime + 3600;

    await predictionMarket.createEvent("Test Event", startTime, endTime);
    await time.increase(1);

    await predictionMarket.connect(user1).placePrediction(0, true, { value: ethers.parseEther("1") });
    await predictionMarket.connect(user2).placePrediction(0, false, { value: ethers.parseEther("1") });

    await time.increase(3601);
    await predictionMarket.resolveEvent(0, true);

    await expect(predictionMarket.connect(user1).claimRewards(0))
      .to.emit(predictionMarket, "RewardsClaimed")
      .withArgs(0, user1.address, ethers.parseEther("1.96")); // 2 ETH total - 2% platform fee
  });
});