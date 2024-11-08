// SPDX-License-Identifier: MIT
pragma solidity >=0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    uint8 decimals_ = 6;

    constructor(uint256 initialSupply) ERC20("Circle USD", "USDC") {
        _mint(msg.sender, initialSupply * (10 ** decimals_));
    }
    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }
}