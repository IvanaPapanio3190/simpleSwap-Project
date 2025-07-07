// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap {
    // Reserves
    mapping(address => mapping(address => uint256)) private reserves;

    // LP tokens balance simplificado (no ERC20, solo para demo)
    mapping(address => uint256) public liquidityBalances;
    uint256 public totalLiquidity;


    /// Events

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed swapper, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut);

   

    /// @notice Add liquidity to the pool for a given token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Desired amount of token A to add
    /// @param amountBDesired Desired amount of token B to add
    /// @param amountAMin Minimum acceptable amount of token A (slippage protection)
    /// @param amountBMin Minimum acceptable amount of token B (slippage protection)
    /// @param to Address to receive liquidity tokens
    /// @param deadline Timestamp after which the transaction will revert
    /// @return amountA Actual amount of token A added
    /// @return amountB Actual amount of token B added
    /// @return liquidity Amount of liquidity tokens minted 


    function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
    // Check the deadline to avoid transaction replay after expiry
    require(block.timestamp <= deadline, "Expired");

    // Read current reserves for token pair
    uint256 reserveA = reserves[tokenA][tokenB];
    uint256 reserveB = reserves[tokenB][tokenA];

    // If no liquidity exists yet, use desired amounts as is
    if (reserveA == 0 && reserveB == 0) {
        amountA = amountADesired;
        amountB = amountBDesired;
    } else {
        // Calculate optimal amount of token B to deposit based on current reserves ratio
        uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            amountA = amountADesired;
            amountB = amountBOptimal;
        } else {
            // Otherwise, calculate optimal amount of token A based on desired token B
            uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
            require(amountAOptimal <= amountADesired, "Insufficient A");
            amountA = amountAOptimal;
            amountB = amountBDesired;
        }
    }

    // Check that calculated amounts meet minimum thresholds (slippage protection)
    require(amountA >= amountAMin, "Insufficient A");
    require(amountB >= amountBMin, "Insufficient B");

    // Transfer tokens from the user to the contract
    IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
    IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

    // Calculate liquidity tokens to mint using square root of product of amounts
    liquidity = sqrt(amountA * amountB);
    require(liquidity > 0, "Insufficient liquidity");

    // Update internal liquidity balances and total supply
    liquidityBalances[to] += liquidity;
    totalLiquidity += liquidity;

    // Update reserves for the token pair
    reserves[tokenA][tokenB] += amountA;
    reserves[tokenB][tokenA] += amountB;

    emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
}




    /// @notice Remove liquidity from the pool
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidity Amount of liquidity tokens to burn
    /// @param amountAMin Minimum amount of token A to receive (slippage protection)
    /// @param amountBMin Minimum amount of token B to receive (slippage protection)
    /// @param to Recipient address of withdrawn tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Amount of token A returned to the user
    /// @return amountB Amount of token B returned to the user

    function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
) external returns (uint256 amountA, uint256 amountB) {
    // Check transaction deadline
    require(block.timestamp <= deadline, "Expired");

    // Check that sender has enough liquidity tokens to burn
    require(liquidityBalances[msg.sender] >= liquidity, "Not enough liquidity");

    // Get current reserves of tokens A and B
    uint256 reserveA = reserves[tokenA][tokenB];
    uint256 reserveB = reserves[tokenB][tokenA];

    // Calculate amount of tokens to return proportional to liquidity burned
    amountA = (liquidity * reserveA) / totalLiquidity;
    amountB = (liquidity * reserveB) / totalLiquidity;

    // Ensure amounts meet minimum thresholds
    require(amountA >= amountAMin, "Insufficient A");
    require(amountB >= amountBMin, "Insufficient B");

    // Update liquidity balances and total liquidity
    liquidityBalances[msg.sender] -= liquidity;
    totalLiquidity -= liquidity;

    // Update reserves
    reserves[tokenA][tokenB] -= amountA;
    reserves[tokenB][tokenA] -= amountB;

    // Transfer tokens back to user
    IERC20(tokenA).transfer(to, amountA);
    IERC20(tokenB).transfer(to, amountB);

    emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
}




    /// @notice Calcula la cantidad de tokens que se recibirán al hacer swap
    /// @param amountIn Cantidad de tokens que el usuario quiere intercambiar
    /// @param reserveIn Reserva actual del token de entrada en el pool
    /// @param reserveOut Reserva actual del token de salida en el pool
    /// @return amountOut Cantidad de tokens que se recibirán en el swap
    function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
) public pure returns (uint amountOut) {
    require(amountIn > 0, "Input amount must be greater than zero");
    require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

    // 
    amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
}



    /// @notice Swap an exact amount of input tokens for output tokens
    /// @param amountIn Exact amount of input tokens to send
    /// @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
    /// @param path Array of token addresses [inputToken, outputToken]
    /// @param to Recipient address for output tokens
    /// @param deadline Transaction expiration timestamp
    /// @return amounts Array with input and output amounts: [amountIn, amountOut]
function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
) external returns (uint256[] memory amounts) {
    // Check deadline to avoid stale transactions
    require(block.timestamp <= deadline, "Expired");
    // Validate path length: must be exactly 2 tokens (input and output)
    require(path.length == 2, "Invalid path");

    address tokenIn = path[0];
    address tokenOut = path[1];

    // Get current reserves for the token pair
    uint256 reserveIn = reserves[tokenIn][tokenOut];
    uint256 reserveOut = reserves[tokenOut][tokenIn];

    // Transfer input tokens from sender to contract
    IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

    // Calculate output token amount based on reserves and input amount
    uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);

    // Ensure output amount meets minimum expected (slippage control)
    require(amountOut >= amountOutMin, "Insufficient output");

    // Update reserves after the swap
    reserves[tokenIn][tokenOut] += amountIn;
    reserves[tokenOut][tokenIn] -= amountOut;

    // Transfer output tokens to recipient
    IERC20(tokenOut).transfer(to, amountOut);


    emit TokensSwapped(msg.sender, amountIn, amountOut, tokenIn, tokenOut);

    // Prepare return amounts array
    amounts = new uint256[](2);
    amounts[0] = amountIn;
    amounts[1] = amountOut;

    return amounts;

    
}



    /// @notice Get the price of tokenA in terms of tokenB
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @return price Price of tokenA expressed in tokenB, scaled by 1e18
    function getPrice(address tokenA, address tokenB) external view returns (uint256 price) {
    // Retrieve reserves for the token pair
    uint256 reserveA = reserves[tokenA][tokenB];
    uint256 reserveB = reserves[tokenB][tokenA];

    // Require that both reserves have liquidity
    require(reserveA > 0 && reserveB > 0, "No liquidity");

    // Calculate price with scaling factor to preserve decimals
    // price = (reserveB * 1e18) / reserveA
    price = (reserveB * 1e18) / reserveA;
}


  
    /// @notice Efficient square root calculation using iterative approximation
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



    /// @notice Returns the name of the contract author
    function author() external pure returns (string memory) {
        return "Ivana Papanio";
    }
}
