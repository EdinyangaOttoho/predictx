// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import "./Factory.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Market {

    IERC20 public USDC;

    address public owner;

    uint public resolvedTo;

    address public factory;

    struct Information {
        string title;
        string description;
        uint yesPrice;
        uint noPrice;
        uint yesLiquidity;
        uint noLiquidity;
        uint yesShares;
        uint noShares;
        uint marketCreated;
        uint marketEnd;
        string[] categories;
        bool resolved;
        uint liquidityShares;
    }

    struct Shares {
        uint yesShares;
        uint noShares;
        uint liquidityShares;
    }

    mapping (address=>Shares) public shares;

    Information public info;

    constructor(address USDCAddress_, string memory title_, string memory description_, uint endDate_, string[] memory categories, address owner_, address factory_) {

        require(endDate_ > block.timestamp, "Market resolution must be set to a date in the future");

        info.title = title_;
        info.description = description_;
        info.yesPrice = 0;
        info.noPrice = 0;
        info.yesLiquidity = 0;
        info.noLiquidity = 0;
        info.yesShares = 0;
        info.noShares = 0;
        info.marketCreated = block.timestamp;
        info.marketEnd = endDate_;
        info.categories = categories;
        info.liquidityShares = 0;

        USDC = IERC20(USDCAddress_);

        owner = owner_;
        factory = factory_;

    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function initializeLiquidity (uint yesPrice, uint liquidity) external returns (bool) {

        require(msg.sender == owner, "Only owner can initialize price");
        require(liquidity >= 10e6, "Liquidity must be up to 10 USD");
        require(info.resolved == false, "Market has already been resolved");
        require(info.yesPrice == 0, "Liquidity has already been initialized");
        require(yesPrice >= (1e3) && yesPrice <= 9 * (1e3), "Initial probability must be up to 10% and less than 100%");

        //In UI, any percentage amount will be multiplied by 1e4
    
        uint noPrice = 1e4 - yesPrice;

        info.yesPrice = yesPrice;

        info.noPrice = noPrice;

        uint yesLiquidity = (yesPrice * liquidity) / 1e4;
        uint noLiquidity = (noPrice * liquidity) / 1e4;

        info.yesLiquidity = yesLiquidity;
        info.noLiquidity = noLiquidity;

        uint sharesToGive = sqrt(yesLiquidity * noLiquidity);

        info.liquidityShares += sharesToGive;

        shares[msg.sender].liquidityShares += sharesToGive;

        require(USDC.transferFrom(msg.sender, address(this), liquidity), "USDC transfer failed");

        return true;

    }

    function getInfo (address account) external view returns (Information memory, Shares memory) {
        return (info, shares[account]);
    }

    function addLiquidity (uint amount) external returns (bool) {

        require(info.yesPrice != 0, "Liquidity has not been initialized");

        uint yesLiquidity = (info.yesPrice * amount) / 1e4;
        uint noLiquidity = (info.noPrice * amount) / 1e4;

        uint sharesToGive = min((yesLiquidity * info.liquidityShares) / info.yesLiquidity, (noLiquidity * info.liquidityShares) / info.noLiquidity);

        shares[msg.sender].liquidityShares += sharesToGive;
        
        info.liquidityShares += sharesToGive;

        require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

        return true;

    }

    function removeLiquidity (uint shares_) external returns (bool) {

        require(shares[msg.sender].liquidityShares >= shares_, "User must own up to the specified amount of shares");

        uint yesToRemove = (shares_ * info.yesLiquidity) / info.liquidityShares;

        uint noToRemove = (shares_ * info.noLiquidity) / info.liquidityShares;

        info.liquidityShares -= shares_;
        
        shares[msg.sender].liquidityShares -= shares_;

        require((info.yesLiquidity + info.noLiquidity) - (yesToRemove + noToRemove) >= 1e6, "There must be at least 10 USDC leftover");

        info.yesLiquidity -= yesToRemove;

        info.noLiquidity -= noToRemove;

        require(USDC.transfer(msg.sender, (yesToRemove + noToRemove)), "USDC transfer failed");

        return true;

    }

    function claim (uint variant) external returns (bool) {

        require(info.resolved == true, "Market must be resolved for user to claim");
        require(variant == resolvedTo, "Can only claim from resolved (won) market");

        if (variant == 1) { // Yes

            uint ownedShares = shares[msg.sender].yesShares;

            uint expectedUSDC = (ownedShares * info.yesPrice) / 1e4;

            require(USDC.transfer(msg.sender, expectedUSDC), "USDC transfer failed");

            info.yesShares -= ownedShares;

            info.yesLiquidity -= expectedUSDC;

            shares[msg.sender].yesShares -= ownedShares;

        }
        else if (variant == 0) { // No

            uint ownedShares = shares[msg.sender].noShares;

            uint expectedUSDC = (ownedShares * info.noPrice) / 1e4;

            require(USDC.transfer(msg.sender, expectedUSDC), "USDC transfer failed");

            info.noShares -= ownedShares;

            info.noLiquidity -= expectedUSDC;

            shares[msg.sender].noShares -= ownedShares;

        }

        return true;

    }

    function resolveMarket (uint variant) external returns (bool) {

        require(msg.sender == owner, "Only owner can resolve market");
        require(block.timestamp >= info.marketEnd, "Can only resolve when market has reached deadline");
        require(variant <= 1, "Variant must only be 0 (No) or 1 (Yes)");
        require(info.resolved == false, "Market already resolved");

        if (variant == 1) {
            info.yesPrice = 1e4;
            info.noPrice = 0;
        }
        else if (variant == 0) {
            info.noPrice = 1e4;
            info.yesPrice = 0;
        }

        info.resolved = true;
        resolvedTo = variant;

        Factory(factory).recordStats(0, msg.sender, "resolve");

        return true;
    }

    function placeOrder (uint variant, uint buyOrSell, uint amount) external returns (bool) {

        require(info.resolved == false, "Market has already been resolved");
        require(variant <= 1, "Variant must be 1 for Yes or 0 for No");
        require(buyOrSell <= 1, "Variant must be 1 for Buy or 0 for Sell");

        // Impact must not be up to 30%

        uint maxImpact = 3e4;

        if (variant == 1) { // Yes

            if (buyOrSell == 1) { // Buy
                
                (uint yesShares, uint profit, uint impact, uint price ) = this.quote(variant, buyOrSell, amount);

                require(impact <= maxImpact, "Price impact must not be up to 30%");

                Factory(factory).recordStats(amount, msg.sender, "volume");

                profit;
                
                shares[msg.sender].yesShares += yesShares;

                info.yesShares += yesShares;

                info.yesLiquidity += amount;

                info.yesPrice = price;

                info.noPrice = 1e4 - price;

                require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

            }
            else if (buyOrSell == 0) { // Sell
                
                shares[msg.sender].yesShares -= amount;

                info.yesShares -= amount;

                (uint amountUSDC, uint profit, uint impact, uint price ) = this.quote(variant, buyOrSell, amount);

                require(impact <= maxImpact, "Price impact must not be up to 30%");

                Factory(factory).recordStats(amountUSDC, msg.sender, "volume");

                profit;

                info.yesLiquidity -= amountUSDC;

                info.yesPrice = price;

                info.noPrice = 1e4 - price;

                require(USDC.transfer(msg.sender, amountUSDC), "USDC transfer failed");

            }

        }
        else if (variant == 0) { // No

            if (buyOrSell == 1) { // Buy

                (uint noShares, uint profit, uint impact, uint price ) = this.quote(variant, buyOrSell, amount);

                require(impact <= maxImpact, "Price impact must not be up to 30%");

                Factory(factory).recordStats(amount, msg.sender, "volume");

                profit;
                
                shares[msg.sender].noShares += noShares;

                info.noShares += noShares;

                info.noLiquidity += amount;

                info.noPrice = price;

                info.yesPrice = 1e4 - price;

                require(USDC.transferFrom(msg.sender, address(this), amount), "USDC transfer failed");

            }
            else if (buyOrSell == 0) { // Sell

                shares[msg.sender].noShares -= amount;

                info.noShares -= amount;

                (uint amountUSDC, uint profit, uint impact, uint price ) = this.quote(variant, buyOrSell, amount);

                require(impact <= maxImpact, "Price impact must not be up to 30%");

                Factory(factory).recordStats(amountUSDC, msg.sender, "volume");

                profit;

                info.noLiquidity -= amountUSDC;

                info.noPrice = price;

                info.yesPrice = 1e4 - price;

                require(USDC.transfer(msg.sender, amountUSDC), "USDC transfer failed");

            }

        }

        return true;

    }

    function calculateImpact(uint amountA, uint amountB) internal pure returns (uint) {
        uint newSum = amountA + amountB;
        uint ratio = (1e4 * newSum) / amountA;
        uint increment = ratio - 1e4;
        return increment;
    }

    function quote (uint variant, uint buyOrSell, uint amount) external view returns (uint, uint, uint, uint) {
        
        require(variant <= 1, "Variant must be 1 for Yes or 0 for No");
        require(buyOrSell <= 1, "Variant must be 1 for Buy or 0 for Sell");
        require(info.resolved == false, "Market already resolved");

        uint amountOut = 0;
        uint estimatedProfit = 0;
        uint impact = 0;
        uint price = 0;

        if (variant == 1) { // Yes

            if (buyOrSell == 1) { // Buy

                impact = calculateImpact(info.yesLiquidity, amount);

                uint newYesLiquidity = info.yesLiquidity + amount;
                uint newNoLiquidity = info.noLiquidity;

                uint newYesPrice = (1e4 * newYesLiquidity) / (newYesLiquidity + newNoLiquidity);

                price = newYesPrice;

                uint output = amount / newYesPrice;

                amountOut = (output - (output / 100)) * 1e4;

                estimatedProfit = (amountOut * 1e4) - amount;

            }
            else if (buyOrSell == 0) { // Sell
            
                uint expectedAmount = (amount * info.yesPrice) / 1e4;

                impact = calculateImpact(info.yesLiquidity, expectedAmount);

                uint newYesLiquidity = info.yesLiquidity - expectedAmount;
                uint newNoLiquidity = info.noLiquidity;

                uint newYesPrice = (1e4 * newYesLiquidity) / (newYesLiquidity + newNoLiquidity);

                price = newYesPrice;

                uint output = (amount * newYesPrice) / 1e4;

                amountOut = output - (output / 100);

            }

        }
        else if (variant == 0) { // No

            if (buyOrSell == 1) { // Buy

                impact = calculateImpact(info.noLiquidity, amount);

                uint newNoLiquidity = info.noLiquidity + amount;
                uint newYesLiquidity = info.yesLiquidity;

                uint newNoPrice = (1e4 * newNoLiquidity) / (newNoLiquidity + newYesLiquidity);

                price = newNoPrice;

                uint output = amount / newNoPrice;

                amountOut = (output - (output / 100)) * 1e4;

                estimatedProfit = (amountOut * 1e4) - amount;

            }
            else if (buyOrSell == 0) { // Sell

                uint expectedAmount = (amount * info.noPrice) / 1e4;

                impact = calculateImpact(info.noLiquidity, expectedAmount);

                uint newNoLiquidity = info.noLiquidity - expectedAmount;
                uint newYesLiquidity = info.yesLiquidity;

                uint newNoPrice = (1e4 * newNoLiquidity) / (newNoLiquidity + newYesLiquidity);

                price = newNoPrice;

                uint output = (amount * newNoPrice) / 1e4;

                amountOut = output - (output / 100);

            }

        }

        return (amountOut, estimatedProfit, impact, price);

    }
    
}