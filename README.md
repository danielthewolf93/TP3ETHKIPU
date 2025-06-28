# SimpleSwap

A minimal decentralized exchange (DEX) called **SimpleSwap**, enabling liquidity provision and swapping between two custom ERC20 tokens: **TokenTik (TIK)** and **TokenTok (TOK)**.

> Developed as part of TP3 assignment for ethKipu – Módulo 3.

---

## Contracts

- **SimpleSwap.sol**: Token swap and liquidity pool using constant product formula (x * y = k) with 0.3% fee.
- **TokenTik.sol** & **TokenTok.sol**: ERC20 tokens mintable by owner.

---

## Features

- Add/remove liquidity with slippage and deadline protection.
- Swap tokens with fee and slippage controls.
- Query token prices.
- Compatible with any EVM chain (e.g., Sepolia).

---

## Key Functions (SimpleSwap.sol)

| Function                        | Description                                    |
|---------------------------------|------------------------------------------------|
| `addLiquidity(...)`             | Deposit tokens to add liquidity.               |
| `removeLiquidity(...)`          | Withdraw tokens by burning liquidity tokens.   |
| `swapExactTokensForTokens(...)` | Swap exact input tokens for output tokens.     |
| `getPrice(tokenA, tokenB)`      | Get price of tokenA in terms of tokenB.        |
| `getAmountOut(...)`             | Calculate output token amount for a swap.      |

---

## Events

- `LiquidityAdded(provider, tokenA, tokenB, amountA, amountB)`
- `LiquidityRemoved(provider, amountA, amountB)`
- `TokensSwapped(swapper, tokenIn, tokenOut, amountIn, amountOut)`


---

## Deployment Info

Network: Sepolia Testnet
Contract Address - SimpleSwap: 0x4F34A3D8cb89B37B9076144D6624F6717f54a6B8
Link Contract verified: https://sepolia.etherscan.io/address/0x4F34A3D8cb89B37B9076144D6624F6717f54a6B8#code

Contract Address - TokenTik: 0x6d3152323D9F87FAB13BFE37A7539587f83e4a22
Link Contract verified: https://sepolia.etherscan.io/address/0x6d3152323D9F87FAB13BFE37A7539587f83e4a22#code

Contract Address - TokenTok: 0xe5cad0Cf39F1E44CA43c966b45e9dbe938aaA70d
Link Contract verified: https://sepolia.etherscan.io/address/0xe5cad0Cf39F1E44CA43c966b45e9dbe938aaA70d#code

---

Notes
Supports a single token pair fixed at first liquidity addition.

Enforces slippage limits and transaction deadlines.

Swap fee: 0.3% (Uniswap V2 style).

Reserves maintain constant product invariant.

---

License
MIT License.
