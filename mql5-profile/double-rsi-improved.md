# Double RSI Buy — Improved Description

## Improved Description

### Double RSI Buy — Mean-Reversion EA for GBP/USD M1

A lightweight Expert Advisor that trades GBP/USD on the 1-minute timeframe using dual RSI logic to catch oversold bounces.

**Simple strategy. Clean execution. No tricks.**

---

#### Strategy Logic

The EA uses two RSI indicators with different periods to identify high-probability entry points:

1. **Entry condition:** Both RSI readings must be in oversold territory simultaneously — this double confirmation reduces false signals compared to single-RSI approaches
2. **Exit condition:** Position closes when RSI reaches overbought levels, capturing the mean-reversion move
3. **Execution:** Trades at candle open only — no mid-candle entries, no order duplication
4. **Position management:** One trade at a time, clean and predictable

#### Why dual RSI?

A single RSI can stay oversold for extended periods during strong trends. By requiring TWO RSI readings (different periods) to agree, the EA filters out most false oversold signals and enters only when momentum exhaustion is more likely.

#### Features

- **Dual RSI confirmation** — fewer false signals than single-RSI systems
- **Candle-open execution** — reproducible results, no tick-dependent behavior
- **No order stacking** — maximum one position at a time
- **Configurable parameters** — RSI periods, levels, lot size all adjustable
- **Low resource usage** — minimal CPU/memory footprint

#### Key Parameters

| Parameter | Description |
|-----------|-------------|
| RSI Period 1 | First RSI calculation period |
| RSI Period 2 | Second RSI calculation period |
| Oversold Level | Entry threshold |
| Overbought Level | Exit threshold |
| Lot Size | Position sizing |
| MagicNumber | Trade identifier |

#### Requirements

- MetaTrader 5
- GBP/USD M1 chart
- Low-spread broker recommended (scalping strategy)
- Demo testing recommended

#### Important

This EA trades on M1 — it's a scalping approach. Make sure your broker allows scalping and has competitive spreads on GBP/USD. Slippage and spread will directly impact results.

---
*Replace current MQL5 Market description with this*
