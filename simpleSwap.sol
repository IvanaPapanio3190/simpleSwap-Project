// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";



/**
 * @title SimpleSwap
 * @notice A simplified Uniswap V2-like decentralized exchange for ERC20 tokens.
 * Allows adding/removing liquidity, swapping tokens, and price queries.
 */


 contract simpleSwap is ERC20 {
    // Tokens in the pair
    address public tokenA;
    address public tokenB;

    // Reserves of tokens in the pool
    uint256 private reserveA;
    uint256 private reserveB;

    // Fee numerator (e.g., 997) and denominator (1000) for 0.3% fee
    uint256 public constant FEE_NUMERATOR = 997;
    uint256 public constant FEE_DENOMINATOR = 1000;

    // Events
    event LiquidityAdded(address indexed provider, uint amountA, uint amountB, uint liquidityMinted);
    event LiquidityRemoved(address indexed provider, uint amountA, uint amountB, uint liquidityBurned);
    event TokensSwapped(address indexed swapper, uint amountIn, uint amountOut, address tokenIn, address tokenOut);

 /**
     * @notice Constructor sets the token pair and creates LP token with name and symbol.
     * @param _tokenA Address of token A
     * @param _tokenB Address of token B
     */

      constructor(address _tokenA, address _tokenB) ERC20("SimpleSwap LP Token", "SSLP") {
        require(_tokenA != _tokenB, "Tokens must be different");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }



      /**
     * @notice Returns the current reserves of tokenA and tokenB.
     */
    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }


      /**
     * @notice Adds liquidity to the pool.
     * @param amountADesired Desired amount of token A to add
     * @param amountBDesired Desired amount of token B to add
     * @param amountAMin Minimum acceptable amount of token A (slippage protection)
     * @param amountBMin Minimum acceptable amount of token B (slippage protection)
     * @param to Recipient of LP tokens
     * @param deadline Unix timestamp after which transaction reverts
     * @return amountA Actual amount of token A added
     * @return amountB Actual amount of token B added
     * @return liquidity Amount of LP tokens minted
     */



     function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    
    {
        require(block.timestamp <= deadline, "SimpleSwap: EXPIRED");

        // If this is the first liquidity added, set amounts directly
        if (reserveA == 0 && reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            // Calculate optimal amountB given amountADesired to keep ratio
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal <= amountADesired, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        require(amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");

        // Transfer tokens from sender to this contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Calculate liquidity to mint
        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min((amountA * totalSupply()) / reserveA, (amountB * totalSupply()) / reserveB);
        }
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");

        // Mint LP tokens to 'to' address
        _mint(to, liquidity);

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }


    /**
     * @notice Removes liquidity from the pool.
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of token A to receive
     * @param amountBMin Minimum amount of token B to receive
     * @param to Recipient address for tokens
     * @param deadline Transaction expiration timestamp
     * @return amountA Amount of token A returned
     * @return amountB Amount of token B returned
     */


      function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (uint256 amountA, uint256 amountB)
    {
        require(block.timestamp <= deadline, "SimpleSwap: EXPIRED");
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        uint256 _totalSupply = totalSupply();

        // Calculate amounts to return
        amountA = (liquidity * reserveA) / _totalSupply;
        amountB = (liquidity * reserveB) / _totalSupply;

        require(amountA >= amountAMin, "SimpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SimpleSwap: INSUFFICIENT_B_AMOUNT");

        // Burn LP tokens from sender
        _burn(msg.sender, liquidity);

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens to recipient
        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }





 /**
     * @notice Swap exact amountIn of tokens for as many tokens out as possible (min amountOut enforced)
     * @param amountIn Amount of input tokens to swap
     * @param amountOutMin Minimum amount of output tokens to receive (slippage protection)
     * @param path Array of token addresses (should be length 2: input token and output token)
     * @param to Recipient address for output tokens
     * @param deadline Transaction expiration timestamp
     * @return amounts Array of amounts for each token in path (input and output)
     */



    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        returns ( uint256[] memory amounts)
    {
        require(block.timestamp <= deadline, "SimpleSwap: EXPIRED");
        require(path.length == 2, "SimpleSwap: INVALID_PATH");
        address inputToken = path[0];
        address outputToken = path[1];

        require((inputToken == tokenA && outputToken == tokenB) || (inputToken == tokenB && outputToken == tokenA), "SimpleSwap: INVALID_TOKEN_PAIR");

        // Transfer input tokens from sender
        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        // Get reserves for input and output tokens
        (uint256 reserveIn, uint256 reserveOut) = inputToken == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        // Calculate output amount
        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        // Update reserves
        if (inputToken == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        // Transfer output tokens to recipient
        IERC20(outputToken).transfer(to, amountOut);


        // Create amounts array with correct size 2
        amounts = new uint256 [](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(msg.sender, amountIn, amountOut, inputToken, outputToken);
    }


 

    /**
     * @notice Returns the price of tokenA in terms of tokenB
     * @param _tokenA Address of token A
     * @param _tokenB Address of token B
     * @return price Price of 1 tokenA expressed in tokenB units (with 18 decimals)
     */


    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require(
            (_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA),
            "SimpleSwap: INVALID_PAIR"
        );

        if (_tokenA == tokenA) {
            require(reserveA > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");
            // price = reserveB / reserveA scaled to 1e18
            price = (reserveB * 1e18) / reserveA;
        } else {
            require(reserveB > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");
            price = (reserveA * 1e18) / reserveB;
        }
    }



    /**
     * @notice Given an input amount of a token and pair reserves, returns the maximum output amount of the other token
     * @param amountIn Amount of input tokens
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @return amountOut Calculated output token amount
     */



      function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
        amountOut = numerator / denominator;
    }


    // --- Helpers ---


      /**
     * @notice Returns the minimum of two values.
     * @param a First number
     * @param b Second number
     * @return The smaller of the two input values
     */

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


     /**
     * @notice Computes the square root of a given number using the Babylonian method.
     * @dev Used to calculate initial liquidity token amount.
     * @param y Input value
     * @return z Approximate square root of the input value
     */

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
}
