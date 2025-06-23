# SimpleSwap - Decentralized Token Swap Contract



## Project Overview
SimpleSwap is a simplified decentralized exchange contract inspired by Uniswap V2, allowing users to add and remove liquidity, swap ERC20 tokens, and query token prices.
This project was developed as the final assignment for Module 3 of the Solidity course.

---
The contract implements essential functions such as:

**addLiquidity()**

**removeLiquidity()**

**swapExactTokensForTokens()**

**getPrice()**

**getAmountOut()**

---
## Description

SimpleSwap allows users to:
- Add and remove liquidity from token pools
- Swap one ERC-20 token for another
- Get real-time prices based on reserves
- Calculate expected output amounts before swapping

The contract replicates basic Uniswap V2 logic without relying on the actual Uniswap protocol.

---


 
 ## Features
 
**🔹addLiquidity(...)** : Adds liquidity to the token pool by depositing a pair of ERC20 tokens.

This function allows a user to provide liquidity by depositing two ERC20 tokens (Token A and Token B) into a liquidity pool. 
In exchange, the user receives LP tokens that represent their share of the pool.

By adding liquidity, the user enables others to swap tokens, and in return, earns a share of the swap fees.

**Parameters:**

address tokenA: Address of token A.

address tokenB: Address of token B.

uint256 amountADesired: Amount of token A the user wants to deposit.

uint256 amountBDesired: Amount of token B the user wants to deposit.

uint256 amountAMin: Minimum amount of token A accepted (slippage protection).

uint256 amountBMin: Minimum amount of token B accepted (slippage protection).

address to: Address that will receive the LP (liquidity provider) tokens.

uint256 deadline: Timestamp after which the transaction will fail.

**Returns:**

uint256 amountA: Actual amount of token A added.

uint256 amountB: Actual amount of token B added.

uint256 liquidity: Amount of LP tokens minted.

---

**🔹 removeLiquidity(...)**: Removes liquidity from the pool, returning the underlying tokens to the user.

When users no longer want to participate as liquidity providers, they can burn their LP tokens (representing their share of the pool) and receive back the underlying ERC20 tokens (tokenA and tokenB) in proportion to their contribution.

**Parameters:**

address tokenA: Address of token A.

address tokenB: Address of token B.

uint256 liquidity: Amount of LP tokens to burn.

uint256 amountAMin: Minimum amount of token A to receive.

uint256 amountBMin: Minimum amount of token B to receive.

address to: Address to receive the tokens.

uint256 deadline: Timestamp after which the transaction will fail.

**Returns:**

uint256 amountA: Amount of token A returned.

uint256 amountB: Amount of token B returned.
