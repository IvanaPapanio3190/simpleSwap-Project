// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC20 token interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256);
    event Approval(address indexed owner, address indexed spender, uint256);
}

/// @title Simplified ERC20 implementation (used for LP token)
contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 private _totalSupply;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: insufficient balance");
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}




/// @title SimpleSwap - Simplified Uniswap V2-like token swap contract
/// @notice Allows adding/removing liquidity, swapping tokens, and price queries
/// @dev Implements interface compatible with the provided SwapVerifier contract

contract simpleSwap is ERC20 {
    address public tokenA;
    address public tokenB;

    uint256 private reserveA;
    uint256 private reserveB;

    uint256 private constant FEE_NUMERATOR = 997;
    uint256 private constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event TokensSwapped(address indexed swapper, uint256 amountIn, uint256 amountOut, address tokenIn, address tokenOut);

    /// @notice Constructor sets the token pair
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    constructor(address _tokenA, address _tokenB) ERC20 ("simpleSwap LP Token", "SSLP") {
        require(_tokenA != _tokenB, "simpleSwap: IDENTICAL_ADDRESSES");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    /// @notice Returns current reserves of tokenA and tokenB
    /// @return _reserveA Reserve of tokenA
    /// @return _reserveB Reserve of tokenB
    function getReserves() public view returns (uint256 _reserveA, uint256 _reserveB) {
        _reserveA = reserveA;
        _reserveB = reserveB;
    }

    /// @notice Adds liquidity to the pool and mints liquidity tokens
    /// @param _tokenA Address of token A (must match contract tokenA)
    /// @param _tokenB Address of token B (must match contract tokenB)
    /// @param amountADesired Desired amount of token A to add
    /// @param amountBDesired Desired amount of token B to add
    /// @param amountAMin Minimum amount of token A to add (slippage protection)
    /// @param amountBMin Minimum amount of token B to add (slippage protection)
    /// @param to Address to receive liquidity tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA Actual amount of token A added
    /// @return amountB Actual amount of token B added
    /// @return liquidity Amount of liquidity tokens minted
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "simpleSwap: EXPIRED");
        require(to != address(0), "simpleSwap: INVALID_TO");
        require(_tokenA == tokenA && _tokenB == tokenB, "simpleSwap: INVALID_PAIR");

        if (reserveA == 0 && reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
            if (amountBOptimal <= amountBDesired) {
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                require(amountAOptimal <= amountADesired, "simpleSwap: INSUFFICIENT_A_AMOUNT");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        require(amountA >= amountAMin, "simpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "simpleSwap: INSUFFICIENT_B_AMOUNT");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Calculate liquidity tokens to mint
        if (liquidity == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min((amountA * totalSupply()) / reserveA, (amountB * totalSupply()) / reserveB);
        }
        require(liquidity > 0, "simpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");

        _mint(to, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Removes liquidity by burning liquidity tokens and returning tokens A and B
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    /// @param liquidity Amount of liquidity tokens to burn
    /// @param amountAMin Minimum amount of token A to receive
    /// @param amountBMin Minimum amount of token B to receive
    /// @param to Address to receive tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA Amount of token A returned
    /// @return amountB Amount of token B returned
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "simpleSwap: EXPIRED");
        require(to != address(0), "simpleSwap: INVALID_TO");
        require(_tokenA == tokenA && _tokenB == tokenB, "simpleSwap: INVALID_PAIR");
        require(liquidity > 0, "simpleSwap: INSUFFICIENT_LIQUIDITY");

        uint256 _totalSupply = totalSupply();
        amountA = (liquidity * reserveA) / _totalSupply;
        amountB = (liquidity * reserveB) / _totalSupply;

        require(amountA >= amountAMin, "simpleSwap: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "simpleSwap: INSUFFICIENT_B_AMOUNT");

        _burn(msg.sender, liquidity);

        reserveA -= amountA;
        reserveB -= amountB;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    /// @notice Swaps an exact amount of input tokens for a minimum amount of output tokens
    /// @param amountIn Exact amount of input tokens to swap
    /// @param amountOutMin Minimum amount of output tokens to receive
    /// @param path Array with two token addresses: [inputToken, outputToken]
    /// @param to Recipient address for output tokens
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amounts Array containing [amountIn, amountOut]
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(block.timestamp <= deadline, "simpleSwap: EXPIRED");
        require(path.length == 2, "simpleSwap: INVALID_PATH");
        require(to != address(0), "simpleSwap: INVALID_TO");

        address inputToken = path[0];
        address outputToken = path[1];

        require(
            (inputToken == tokenA && outputToken == tokenB) ||
            (inputToken == tokenB && outputToken == tokenA),
            "simpleSwap: INVALID_PAIR"
        );

        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        (uint256 reserveIn, uint256 reserveOut) = inputToken == tokenA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "simpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        if (inputToken == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        IERC20(outputToken).transfer(to, amountOut);

        amounts = new uint256[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;

        emit TokensSwapped(msg.sender, amountIn, amountOut, inputToken, outputToken);
    }

    /// @notice Returns price of tokenA in terms of tokenB or vice versa
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    /// @return price Price of 1 unit of tokenA in terms of tokenB scaled by 1e18
    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require(
            (_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA),
            "simpleSwap: INVALID_PAIR"
        );

        if (_tokenA == tokenA) {
            require(reserveA > 0, "simpleSwap: INSUFFICIENT_LIQUIDITY");
            price = (reserveB * 1e18) / reserveA;
        } else {
            require(reserveB > 0, "simpleSwap: INSUFFICIENT_LIQUIDITY");
            price = (reserveA * 1e18) / reserveB;
        }
    }

    /// @notice Calculates output amount for given input amount using AMM formula with fee
    /// @param amountIn Amount of input tokens to swap
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Calculated amount of output tokens
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, "simpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "simpleSwap: INSUFFICIENT_LIQUIDITY");

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;

        amountOut = numerator / denominator;
    }

    /// @notice Returns the smaller of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Babylonian method for computing square root
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }   
}

