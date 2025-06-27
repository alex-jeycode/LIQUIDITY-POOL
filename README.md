# LIQUIDITY-POOL

An automated market maker (AMM) enabling decentralized token swapping and liquidity provision on Stacks.

## Overview

LIQUIDITY-POOL implements a constant product AMM formula allowing users to trade tokens and earn fees by providing liquidity to the pool.

## Features

- **Liquidity Provision**: Add token pairs to earn LP tokens and trading fees
- **Token Swapping**: Trade between token pairs with automated pricing
- **Slippage Protection**: Minimum output guarantees for trades
- **LP Token System**: Proportional ownership of pool liquidity
- **Trading Fees**: 0.3% fee distributed to liquidity providers
- **Price Discovery**: Automatic price adjustment based on supply and demand

## Contract Functions

### Public Functions

- `add-liquidity(amount-a, amount-b)` - Provide liquidity and receive LP tokens
- `remove-liquidity(lp-amount)` - Withdraw liquidity by burning LP tokens
- `swap-a-for-b(input-amount, min-output)` - Swap token A for token B
- `swap-b-for-a(input-amount, min-output)` - Swap token B for token A
- `set-token-balance(user, token, amount)` - Admin function to set balances

### Read-Only Functions

- `get-reserves()` - Get current token reserves in the pool
- `get-lp-balance(user)` - Get user's LP token balance
- `get-token-balance(user, token)` - Get user's token balance
- `calculate-swap-output(input, input-reserve, output-reserve)` - Calculate swap output

## Usage

### Providing Liquidity
1. Ensure you have both tokens in your balance
2. Call `add-liquidity` with desired amounts
3. Receive LP tokens representing your pool share
4. Earn fees from all trades proportional to your share

### Trading Tokens
1. Call `swap-a-for-b` or `swap-b-for-a` with input amount
2. Set `min-output` to protect against slippage
3. Tokens are automatically exchanged at current pool price

### Removing Liquidity
1. Call `remove-liquidity` with LP token amount
2. Receive proportional share of both tokens
3. Includes your share of accumulated trading fees

## Economics

- **Constant Product Formula**: x * y = k ensures liquidity
- **Trading Fees**: 0.3% fee on all swaps
- **Price Impact**: Large trades have higher price impact
- **Arbitrage**: Price differences create arbitrage opportunities

## Security

- Slippage protection prevents sandwich attacks
- Balance verification ensures sufficient funds
- Proportional withdrawals maintain pool integrity
- Admin functions for emergency management
