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

    mapping(uint=>address) markets;

    mapping(address=>uint) public volumes;

    mapping(address=>bool) knownMarkets;

    mapping(string=>bool) categoryExists;

    mapping(address=>bool) uniqueWallets;

    Statistics public statistics;

    constructor(address USDCAddress_) {
        USDCAddress = USDCAddress_;
    }

    function createMarket (address USDCAddress_, string memory title_, string memory description_, uint endDate_, string[] memory categories_) external returns (address) {
        address owner_ = msg.sender;
        Market marketContract = new Market(USDCAddress_, title_, description_, endDate_, categories_, owner_, address(this));
        address contractAddress = address(marketContract);
        for (uint i = 0; i < categories_.length; i++) {
            if (categoryExists[categories_[i]] == false) {
                categoryExists[categories_[i]] = true;
                categories.push(categories_[i]);
            }
        }
        knownMarkets[contractAddress] = true;
        statistics.totalPools++;
        statistics.activeEvents++;
        markets[statistics.totalPools] = contractAddress;
        return contractAddress;
    }

    function getCategories() external view returns (string[] memory) {
        return categories;
    }

    function getMarketInfo(address contractAddress, address account) external view returns (Market.Information memory, Market.Shares memory, uint) {
        (Market.Information memory info, Market.Shares memory shares) = Market(contractAddress).getInfo(account);
        uint volume = volumes[contractAddress];
        return (info, shares, volume);
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

    function recordStats(uint amount, address account, string memory statType) external returns(bool) {
        require(knownMarkets[msg.sender] == true, "Call must be made from known market contract");
        if (stringToBytes32(statType) == stringToBytes32("volume")) {
            volumes[msg.sender] += amount;
            statistics.volume += amount;
            if (uniqueWallets[account] == false) {
                uniqueWallets[account] = true;
                statistics.uniqueWallets++;
            }
        }
        else if (stringToBytes32(statType) == stringToBytes32("resolve")) {
            statistics.activeEvents--;
        }
        return true;
    }

    function fetchMarkets(uint page, uint itemPerPage, address account) external view returns (Market.Information[] memory, address[] memory) {
        
        require(page > 0, "Page must be greater than 0");
        require(itemPerPage > 0, "Items per page must be greater than 0");

        uint totalMarkets = statistics.totalPools;
        uint startIndex = (page - 1) * itemPerPage;
        uint endIndex = startIndex + itemPerPage;

        if (endIndex > totalMarkets) {
            endIndex = totalMarkets;
        }

        uint numberOfItems = endIndex - startIndex;

        require(numberOfItems > 0, "No markets found for this page");

        Market.Information[] memory paginatedMarkets = new Market.Information[](numberOfItems);

        address[] memory contractAddresses = new address[](numberOfItems);

        // Populate the paginated array
        uint count = 0;
        for (uint i = startIndex + 1; i <= endIndex; i++) {
            contractAddresses[count] = markets[startIndex + i];
            (Market.Information memory info, Market.Shares memory shares) = Market(markets[startIndex + i]).getInfo(account);
            shares;
            paginatedMarkets[count] = info;
            count++;
        }

        return (paginatedMarkets, contractAddresses); // Return the paginated results
    }

}