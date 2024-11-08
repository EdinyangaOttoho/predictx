// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import "./Market.sol";

contract Factory {

    address public USDCAddress;

    string[] public categories;

    struct Statistics {
        uint volume;
        uint totalPools;
        uint uniqueWallets;
        uint activeEvents;
    }

    event Trade(
        address indexed market,
        address indexed account,
        uint variant,
        uint buyOrSell,
        uint price,
        uint volume
    );

    event Category(
        string indexed name
    );

    mapping(uint=>address) markets;

    mapping(address=>uint) public volumes;

    mapping(address=>bool) knownMarkets;

    mapping(string=>bool) categoryExists;

    mapping(address=>bool) uniqueWallets;

    mapping(address=>string[]) public media;

    mapping(address=>bool) private adminsMap;

    address[] public admins;

    Statistics public statistics;

    constructor(address USDCAddress_) {
        USDCAddress = USDCAddress_;
        adminsMap[msg.sender] = true;
        admins.push(msg.sender);
    }

    function createMarket (string memory title_, string memory description_, uint endDate_, string[] memory categories_, string[] memory media_) external returns (address) {
        address owner_ = msg.sender;
        require(adminsMap[owner_] == true, "Only admins can create markets");
        Market marketContract = new Market(USDCAddress, title_, description_, endDate_, categories_, owner_, address(this));
        address contractAddress = address(marketContract);
        for (uint i = 0; i < categories_.length; i++) {
            if (categoryExists[categories_[i]] == false) {
                categoryExists[categories_[i]] = true;
                categories.push(categories_[i]);
                emit Category(categories_[i]);
            }
        }
        knownMarkets[contractAddress] = true;
        statistics.totalPools++;
        statistics.activeEvents++;
        markets[statistics.totalPools] = contractAddress;
        media[contractAddress] = media_;
        return contractAddress;
    }

    function addAdmin(address account) external returns (bool) {
        require(adminsMap[msg.sender] == true, "Caller must be an admin");
        if (adminsMap[account] == false) {
            adminsMap[account] = true;
            admins.push(account);
        }
        return true;
    }

    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    function getCategories() external view returns (string[] memory) {
        return categories;
    }

    function getMarketInfo(address contractAddress, address account) external view returns (Market.Information memory, Market.Shares memory, uint, string[] memory) {
        (Market.Information memory info, Market.Shares memory shares) = Market(contractAddress).getInfo(account);
        uint volume = volumes[contractAddress];
        return (info, shares, volume, media[contractAddress]);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function recordStats(uint amount, address account, string memory statType, uint[] memory data) external returns(bool) {
        
        require(knownMarkets[msg.sender] == true, "Call must be made from known market contract");

        if (stringToBytes32(statType) == stringToBytes32("volume")) {

            // data holds [variant, buyOrSell, price]

            volumes[msg.sender] += amount;
            statistics.volume += amount;
            if (uniqueWallets[account] == false) {
                uniqueWallets[account] = true;
                statistics.uniqueWallets++;
            }
            emit Trade(msg.sender, account, data[0], data[1], data[2], amount);
        }
        else if (stringToBytes32(statType) == stringToBytes32("resolve")) {
            statistics.activeEvents--;
        }

        return true;

    }

    function fetchMarkets(uint page, uint itemsPerPage, address account) external view returns (Market.Information[] memory, address[] memory) {
        
        require(page > 0, "Page must be greater than 0");
        require(itemsPerPage > 0, "Items per page must be greater than 0");

        uint totalMarkets = statistics.totalPools;

        uint numberOfPages;

        if (totalMarkets % itemsPerPage == 0) {
            numberOfPages = totalMarkets / itemsPerPage;
        }
        else {
            numberOfPages = (totalMarkets / itemsPerPage) + 1;
        }

        require(page <= numberOfPages, "Page is out of bounds");

        require(totalMarkets > 0, "No market exists at the moment");
        
        uint startIndex = totalMarkets - ((page - 1) * itemsPerPage);
        uint endIndex;
        
        if (startIndex < itemsPerPage) {
            endIndex = 1;
        }
        else {
            endIndex = (startIndex - itemsPerPage) + 1;
        }

        uint numberOfItems = (startIndex - endIndex) + 1;

        require(numberOfItems > 0, "No markets found for this page");

        Market.Information[] memory paginatedMarkets = new Market.Information[](numberOfItems);

        address[] memory contractAddresses = new address[](numberOfItems);

        // Populate the paginated array
        uint count = 0;
        for (uint i = startIndex; i >= endIndex; i--) {
            contractAddresses[count] = markets[i];
            (Market.Information memory info, Market.Shares memory shares) = Market(markets[i]).getInfo(account);
            shares;
            paginatedMarkets[count] = info;
            count++;
        }

        return (paginatedMarkets, contractAddresses); // Return the paginated results
    }

}