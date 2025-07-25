# SimpleSwap - Decentralized Token Swap Contract

# Trabajo Práctico Final - Módulo N° 3

---

## Table of Contents
- [Project Overview](#project-overview)
- [Smart Contract Flow](#smart-contract-flow)
- [Description](#description)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Deployment](#deployment)
- [Contract Verification](#contract-verification)
- [Usage](#usage)
- [Contract Details](#contract-details)
- [Testing](#testing)
- [Limitations](#limitations)
- [License](#license)


---

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


## Smart Contract Flow

![SimpleSwap Flowchart](./SimpleSwap_flowchart.png)


---
## Description

SimpleSwap allows users to:
- Add and remove liquidity from token pools
- Swap one ERC-20 token for another
- Get real-time prices based on reserves
- Calculate expected output amounts before swapping

The contract replicates basic Uniswap V2 logic without relying on the actual Uniswap protocol.

---

## Prerequisites

- Solidity version: 0.8.20
- Remix IDE for compiling and deploying contracts
- OpenZeppelin Contracts for ERC20 interface (imported locally)
- Metamask with Sepolia testnet configured

---

## Installation

1. Clone or download this repository.
2. Open Remix IDE (https://remix.ethereum.org).
3. Load the contract file 'SimpleSwap.sol'.
4. Select Solidity compiler version 0.8.20.
5. Enable optimizer with 200 runs.
6. Compile the contract.
7. Deploy the contract to the Sepolia testnet using injected Web3 provider (Metamask).


---

## Deployment

The contract was deployed on the **Sepolia testnet**, but could not be properly verified on Etherscan due to errors related to OpenZeppelin imports and compilation issues outside of Remix.

**Contract address on Sepolia (deployed from Remix)**:

(https://sepolia.etherscan.io/verifyContract-solc?a=0x93A0c1f7d6a9162C59C16678Fc31e9639AfeA5Fc&c=v0.8.20%2bcommit.a1b79de6&lictype=3)

**Simple Swap**: 0x93A0c1f7d6a9162C59C16678Fc31e9639AfeA5Fc

**TokenA Contract**: 0x143Ce465ef5e2B1F3Fc3536C167Df7ac0f93D16C

**TokenB Contract**: 0xA6F2FF3c3268648F220E03403Cd32B5831A53944


---


## Contract Verification
The contract was deployed on Sepolia testnet using Remix IDE.

Verification on Etherscan was unsuccessful due to limitations importing OpenZeppelin contracts when compiling with Remix.

Despite the lack of on-chain verified source code on Etherscan, all functions were manually tested on Sepolia and verified via Remix and blockchain explorer.

The contract verification on Sepolia Etherscan was unsuccessful due to issues with OpenZeppelin imports and Remix’s external dependency limitations.
Below is a screenshot of the verification error message encountered:

<p align="center"> <img src="verifypublish.jpg" alt="Sepolia verify error" width="700"/> </p> 


**Error message received**:


```text
ParserError: Source "@openzeppelin/contracts/token/ERC20/IERC20.sol" not found: File import callback not supported
 --> myc:4:1:
  |
4 | import "@openzeppelin/contracts/token/ERC20/IERC20.sol"
  | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ParserError: Source "@openzeppelin/contracts/token/ERC20/ERC20.sol" not found: File import callback not supported
 --> myc:5:1:
  |
5 | import "@openzeppelin/contracts/token/ERC20/ERC20.sol"
  | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

```




<p align="center"> <img src="warning.jpg" alt="Etherscan Remix import error" width="700"/> </p> 



## Tested Functions

***addLiquidity(...)***
  
       Tested manually on Sepolia testnet using two deployed ERC20 tokens (TokenA and TokenB).
      
        Steps followed:

     - Executed approve() on both tokens to allow the SimpleSwap contract to spend user balances.

     - Called addLiquidity(...) with valid parameters (amountADesired, amountBDesired, amountAMin, amountBMin, etc.).

     - Verified in Remix that:

              - Tokens were correctly transferred to the contract.

              - Internal reserves were updated.

              - LP tokens were minted and assigned to the correct address.
     
     - The LiquidityAdded event was emitted as expected.





***removeLiquidity(...)***

    - could not be successfully tested due to a gas-related error during execution.
    - Investigation is pending; this function is implemented but remains unverified under current testing conditions.
  



---



## Usage

Use the following main functions:


**🔹 addLiquidity(...)**: Adds liquidity to the token pool by depositing a pair of ERC20 tokens.

This function allows a user to provide liquidity by depositing two ERC20 tokens (Token A and Token B) into a liquidity pool.  
In exchange, the user receives LP tokens that represent their share of the pool.

By adding liquidity, the user enables others to swap tokens, and in return, earns a share of the swap fees.

**Tasks:**

- Transfer tokens A and B from the user to the contract using `transferFrom`.
- Calculate the optimal amounts of tokens to add to maintain the pool ratio.
- Update the pool's internal reserves.
- Issue liquidity tokens (LP tokens) to the user to represent their stake.
- Validate that the transaction occurs before the deadline.
- Apply minimum thresholds to prevent excessive slippage (`amountAMin`, `amountBMin`).

**Parameters:**

- `address tokenA`: Address of token A.
- `address tokenB`: Address of token B.
- `uint256 amountADesired`: Amount of token A the user wants to deposit.
- `uint256 amountBDesired`: Amount of token B the user wants to deposit.
- `uint256 amountAMin`: Minimum amount of token A accepted (slippage protection).
- `uint256 amountBMin`: Minimum amount of token B accepted (slippage protection).
- `address to`: Address that will receive the LP (liquidity provider) tokens.
- `uint256 deadline`: Timestamp after which the transaction will fail.

**Returns:**

- `uint256 amountA`: Actual amount of token A added (may be lower than the desired amount due to the ratio).
- `uint256 amountB`: Actual amount of token B added (may be lower than the desired amount due to the ratio).
- `uint256 liquidity`: Amount of LP tokens issued to the user.

---



**🔹 removeLiquidity(...)**: Removes liquidity from the pool, returning the underlying tokens to the user.

When users no longer want to participate as liquidity providers, they can burn their LP tokens (representing their share of the pool) and receive back the underlying ERC20 tokens (tokenA and tokenB) in proportion to their contribution.

**Tasks:**

- Burn the user's liquidity tokens (LP tokens).
- Calculate the amounts of tokens A and B to return.
- Transfer tokens A and B back to the user.
- Validate that the transaction occurs before the deadline.
- Apply minimum thresholds (`amountAMin`, `amountBMin`) to protect against slippage.

**Parameters:**

- `address tokenA`: Address of token A.
- `address tokenB`: Address of token B.
- `uint256 liquidity`: Amount of LP tokens to burn.
- `uint256 amountAMin`: Minimum amount of token A to receive (slippage protection).
- `uint256 amountBMin`: Minimum amount of token B to receive (slippage protection).
- `address to`: Address that will receive the withdrawn tokens.
- `uint256 deadline`: Timestamp after which the transaction will fail.

**Returns:**

- `uint256 amountA`: Amount of token A returned to the user.
- `uint256 amountB`: Amount of token B returned to the user.

---



**🔹 swapExactTokensForTokens(...)**: Swaps a fixed amount of input token for the maximum possible amount of output token, respecting minimum output and deadline.

This function allows a user to swap an exact amount of one ERC20 token (inputToken) for another ERC20 token (outputToken) within the liquidity pool. It guarantees that the user will receive at least a minimum amount of the output token (amountOutMin) to protect against price slippage, and the swap must happen before the specified deadline.

**Tasks:**

- Transfer input tokens from the user to the contract using transferFrom.
- Calculate the output amount according to reserves and the constant product formula.
- Ensure output amount meets the minimum threshold (amountOutMin).
- Update the internal reserves to reflect the swap.
- Transfer output tokens to the recipient address.
- Validate that the transaction happens before the deadline.

**Parameters:**

- `uint256 amountIn`: Exact amount of input tokens to swap.
- `uint256 amountOutMin`: Minimum amount of output tokens to receive.
- `address[] path`: Array with two addresses — [inputToken, outputToken].
- `address to`: Recipient address of output tokens.
- `uint256 deadline`: Timestamp after which the transaction will fail.

**Returns:**

- `uint256[] amounts`: Array with the input and output token amounts: [amountIn, amountOut].


---

**🔹 getPrice(...)**: Returns the current price of tokenA in terms of tokenB or vice versa, based on the reserves.

This function calculates and returns the current exchange rate between two ERC20 tokens based on the liquidity pool reserves.  
It answers the question: “How much of tokenB is needed to get 1 unit of tokenA?”

It works bidirectionally:

- If tokenA is the input and tokenB is the quote token, it returns the price of tokenA in terms of tokenB.
- If reversed, it returns the price of tokenB in terms of tokenA.

**Tasks:**

- Retrieve the current reserves of tokenA and tokenB from the liquidity pool.
- Use the ratio of reserves to calculate the price of tokenA in terms of tokenB.
- Return the calculated price (scaled to 18 decimals).

**Parameters:**

- `address tokenA`: Address of token A.
- `address tokenB`: Address of token B.

**Returns:**

- `uint256 price`: Price of 1 unit of tokenA in terms of tokenB (scaled to 18 decimals).


---

**🔹 getAmountOut(...)**: Calculates the output amount a user would receive for a given input amount, using the AMM formula.

This function calculates how many output tokens a user will receive when swapping a specific amount of input tokens, based on the current liquidity reserves in the pool.

It uses the Automated Market Maker (AMM) formula, which maintains the product of the reserves constant (x * y = k).

**Tasks:**

- Take the input amount (`amountIn`) provided by the user.
- Retrieve the current reserves of input (`reserveIn`) and output (`reserveOut`) tokens.
- Use the constant product formula to calculate the output amount.
- Return the calculated output amount (`amountOut`).

**Parameters:**

- `uint256 amountIn`: Amount of tokens the user wants to swap into the pool.
- `uint256 reserveIn`: Current reserve of the input token in the liquidity pool.
- `uint256 reserveOut`: Current reserve of the output token in the liquidity pool.

**Returns:**

- `uint256 amountOut`: Maximum amount of output tokens the user will receive according to the AMM formula.


---

**🔹 sqrt(...)**: Computes the square root of a number using iterative approximation.
This internal helper function is used to calculate the square root of the product of token amounts when minting liquidity tokens.
It uses the Babylonian method for efficient approximation.

**Parameters**:

uint256 y: The input value to compute the square root of.


**Returns**:

uint256 z: The square root of the input value.


**Notes**:

- This function is internal and not accessible externally.

- It ensures precision for liquidity = sqrt(amountA * amountB) in addLiquidity.


---


 ### Events
The contract emits the following events to signal key state changes:

**- LiquidityAdded**(address provider, uint256 amountA, uint256 amountB, uint256 liquidity)
Emitted when a user adds liquidity to the pool.
It includes the provider’s address, token amounts added, and liquidity minted.

**- LiquidityRemoved**(address provider, uint256 amountA, uint256 amountB, uint256 liquidity)
Emitted when a user removes liquidity from the pool.
It includes the provider’s address, token amounts withdrawn, and liquidity burned.

**- TokensSwapped**(address swapper, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut)
Emitted when a token swap is executed.
It includes who performed the swap, input/output amounts, and token addresses.


---
## Contract Details


Los contratos actuales están en la carpeta `SimpleSwap_v2/` y son:

- `SimpleSwapContract.sol`: contrato principal para swap y liquidez.
- `TokenAv1.sol`: token ERC20 personalizado A.
- `TokenBv1.sol`: token ERC20 personalizado B.
- Located in: `SimpleSwap_v2/` folder in the repository root
- Uses OpenZeppelin's 'IERC20' interface for token interaction.
- Implements key functions with detailed NatSpec comments.
- Designed to replicate basic Uniswap V2 functionality without external dependencies.



---

## Testing

- Functions were manually tested on the Sepolia testnet with custom ERC20 tokens (TokenA and TokenB) deployed separately.

- Tests were conducted via Remix IDE using Injected Web3 with MetaMask.

- All core functionalities except removeLiquidity were executed successfully in Remix. The removeLiquidity function caused gas-related errors during testing.


   **Contract verification on Sepolia Etherscan was unsuccessful** due to issues with OpenZeppelin imports and limitations of Remix when compiling external dependencies.


---


## Limitations

- OpenZeppelin imports could not be verified on Etherscan due to import callback restrictions in Remix.
- Swap fee is fixed and simplified (no dynamic fee or fee distribution implemented).
- Does not implement advanced Uniswap features such as flash swaps or multi-hop swaps.
- Liquidity tokens are represented via a simplified internal balance mapping, not by a separate ERC20 contract.


---


## License

This project is licensed under the MIT License © 2025




---


Made by: [Ivana Papaño](https://github.com/IvanaPapanio3190)


---
