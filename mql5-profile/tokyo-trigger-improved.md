# Tokyo Trigger — Improved Description

## Pricing Note
$199 with zero reviews is a tough sell. Suggested strategy:
- Drop to $79-99 until you get 2-3 reviews
- Then raise back to $149-199
- Or offer a limited-time launch price

## Improved Description

### Tokyo Trigger — Stochastic Breakout EA for USDJPY H1

A disciplined, single-pair Expert Advisor that trades USDJPY on the H1 timeframe using stochastic momentum + breakout confirmation.

**No martingale. No grid. No hedging. One position at a time.**

---

#### How it works

1. **Signal detection:** Identifies bearish stochastic %D crosses that indicate potential oversold conditions with bullish reversal potential
2. **Smart entry:** Instead of market orders, places a Buy Stop at the high of a defined technical period — only enters if price confirms the move
3. **Dynamic risk:** Stop Loss based on ATR with an optimized multiplier, adapting to current volatility
4. **Timed exit:** Positions close automatically after a set period if SL hasn't been hit
5. **Weekend protection:** Friday filter avoids exposure to weekend gaps (configurable)

#### Why this EA?

- **13 years of backtesting** (2012–2025) on real USDJPY data
- **Transparent logic** — no hidden layers, no neural networks, no curve-fitting tricks
- **One pair, one timeframe** — focused optimization beats scattered approaches
- **Plug and play** — attach to USDJPY H1, set your lot size, done
- **Auditable code** — clean, commented, nothing obscured

#### Key Parameters

| Parameter | Description |
|-----------|-------------|
| MagicNumber | Unique trade identifier |
| Lot Size | Position sizing |
| Exit at EOD | Auto-close at end of day |
| Friday Exit | Configurable weekend protection (default 22:55 UTC+2) |
| Max Range | Trading range limitation filter |

#### Requirements

- MetaTrader 5 (hedge mode)
- USDJPY H1 chart
- Low-spread ECN broker recommended
- Demo test recommended before live trading

#### What you won't find here

❌ Martingale or lot multiplication  
❌ Grid or averaging down  
❌ Overfitted parameters  
❌ "99% win rate" marketing nonsense

This is a technical tool built for traders who value transparency over hype.

---
*Replace current MQL5 Market description with this*
