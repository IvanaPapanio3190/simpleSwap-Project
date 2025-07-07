// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TokenA
/// @notice Example ERC20 token used for testing SimpleSwap
contract TokenA is ERC20 {
    constructor(uint256 initialSupply) ERC20("Token A", "TKA") {
        _mint(msg.sender, initialSupply);
    }
}
