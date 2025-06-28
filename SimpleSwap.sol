// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title SimpleSwap
/// @notice A minimalistic token swap and liquidity pool for two ERC20 tokens
/// @dev Works similarly to Uniswap V1, using constant product formula (x * y = k)
contract SimpleSwap is ReentrancyGuard {
    /// @notice Address of token A in the pool
    address public tokenA;

    /// @notice Address of token B in the pool
    address public tokenB;

    /// @notice Current reserve of token A
    uint256 public reserveA;

    /// @notice Current reserve of token B
    uint256 public reserveB;

    /// @notice Total liquidity issued to providers
    uint256 public totalLiquidity;

    /// @notice Mapping of user addresses to their provided liquidity
    mapping(address => uint256) public liquidityProvided;

    /// @notice Emitted when liquidity is added
    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice Emitted when liquidity is removed
    event LiquidityRemoved(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice Emitted when tokens are swapped
    event TokensSwapped(
        address indexed swapper,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @notice Add liquidity to the pool
    /// @param _tokenA The address of token A
    /// @param _tokenB The address of token B
    /// @param amountADesired Desired amount of token A to deposit
    /// @param amountBDesired Desired amount of token B to deposit
    /// @param amountAMin Minimum acceptable amount of token A (for slippage protection)
    /// @param amountBMin Minimum acceptable amount of token B (for slippage protection)
    /// @param to Address that receives the liquidity tokens
    /// @param deadline Expiration time for the transaction
    /// @return amountA Actual amount of token A deposited
    /// @return amountB Actual amount of token B deposited
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
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(block.timestamp <= deadline, "Expired");
        require(to != address(0), "Invalid recipient");

        if (tokenA == address(0) && tokenB == address(0)) {
            require(_tokenA != _tokenB, "Tokens must differ");
            tokenA = _tokenA;
            tokenB = _tokenB;
        } else {
            require((_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA), "Invalid token pair");
        }

        bool reversed = (_tokenA != tokenA);
        uint256 currentReserveA = reversed ? reserveB : reserveA;
        uint256 currentReserveB = reversed ? reserveA : reserveB;

        if (currentReserveA == 0 && currentReserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
            liquidity = Math.sqrt(amountA * amountB);
        } else {
            uint256 amountBOptimal = (amountADesired * currentReserveB) / currentReserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Slippage B");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint256 amountAOptimal = (amountBDesired * currentReserveA) / currentReserveB;
                require(amountAOptimal >= amountAMin, "Slippage A");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
            liquidity = Math.min((amountA * totalLiquidity) / currentReserveA, (amountB * totalLiquidity) / currentReserveB);
        }

        require(liquidity > 0, "Liquidity = 0");

        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), amountB);

        if (reversed) {
            reserveB += amountA;
            reserveA += amountB;
        } else {
            reserveA += amountA;
            reserveB += amountB;
        }

        totalLiquidity += liquidity;
        liquidityProvided[to] += liquidity;

        emit LiquidityAdded(to, _tokenA, _tokenB, amountA, amountB);
    }

    /// @notice Remove liquidity from the pool
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    /// @param liquidity Amount of liquidity to remove
    /// @param amountAMin Minimum acceptable amount of token A to receive
    /// @param amountBMin Minimum acceptable amount of token B to receive
    /// @param to Address to receive the withdrawn tokens
    /// @param deadline Expiration time for the transaction
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
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        require(block.timestamp <= deadline, "Expired");
        require(to != address(0), "Invalid recipient");
        require((_tokenA == tokenA && _tokenB == tokenB) || (_tokenA == tokenB && _tokenB == tokenA), "Invalid token pair");
        require(liquidityProvided[msg.sender] >= liquidity, "Not enough liquidity");

        bool reversed = (_tokenA != tokenA);
        uint256 currentReserveA = reversed ? reserveB : reserveA;
        uint256 currentReserveB = reversed ? reserveA : reserveB;

        amountA = (liquidity * currentReserveA) / totalLiquidity;
        amountB = (liquidity * currentReserveB) / totalLiquidity;

        require(amountA >= amountAMin, "Slippage A");
        require(amountB >= amountBMin, "Slippage B");

        if (reversed) {
            reserveB -= amountA;
            reserveA -= amountB;
        } else {
            reserveA -= amountA;
            reserveB -= amountB;
        }

        totalLiquidity -= liquidity;
        liquidityProvided[msg.sender] -= liquidity;

        IERC20(_tokenA).transfer(to, amountA);
        IERC20(_tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /// @notice Swap a fixed amount of tokens for the corresponding amount of another token
    /// @param amountIn Exact amount of input tokens
    /// @param amountOutMin Minimum acceptable amount of output tokens (for slippage protection)
    /// @param path The swap path (must be of length 2: [inputToken, outputToken])
    /// @param to Recipient of the output tokens
    /// @param deadline Expiration time for the transaction
    /// @return amounts Array with input and output amounts: [amountIn, amountOut]
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256[] memory amounts) {
        require(path.length == 2, "Path must be length 2");
        require(block.timestamp <= deadline, "Expired");

        address input = path[0];
        address output = path[1];
        require((input == tokenA && output == tokenB) || (input == tokenB && output == tokenA), "Invalid pair");

        (uint256 reserveIn, uint256 reserveOut) = input == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 amountOut = getAmountOut(amountIn, reserveIn, reserveOut);
        require(amountOut >= amountOutMin, "Slippage too high");

        IERC20(input).transferFrom(msg.sender, address(this), amountIn);
        IERC20(output).transfer(to, amountOut);

        if (input == tokenA) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit TokensSwapped(msg.sender, input, output, amountIn, amountOut);

        amounts = new uint256[](2) ;
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    /// @notice Get the price of token A in terms of token B
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    /// @return price Current price scaled by 1e18
    function getPrice(address _tokenA, address _tokenB) external view returns (uint256 price) {
        require((_tokenA == tokenA && _tokenB == tokenB), "Invalid pair");
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        price = (reserveB * 1e18) / reserveA;
    }

    /// @notice Internal utility to calculate output amount for a given input using constant product formula
    /// @param amountIn Input amount
    /// @param reserveIn Input token reserve
    /// @param reserveOut Output token reserve
    /// @return amountOut Output amount after 0.3% fee
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid inputs");
        uint256 amountInWithFee = (amountIn * 997) / 1000;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn + amountInWithFee);
    }
}
