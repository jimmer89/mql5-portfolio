# Double RSI Strategy: How to Filter False Signals in Scalping

## Introduction

The RSI is one of the most popular oscillators in trading — and one of the biggest sources of false signals in scalping. The standard RSI(14) was designed for daily charts. On M1 or M5, it reacts to noise, stays pinned in oversold territory during trends, and generates whipsaw after whipsaw.

The Double RSI approach solves this by requiring two RSI indicators — one fast, one slow — to agree before entering a trade. In this article, I'll explain the logic, show you MQL5 code, and share backtesting results.

## Why Single RSI Fails in Scalping

On lower timeframes, single RSI faces these problems:

- **Noise sensitivity:** RSI(14) on M5 reacts to microstructure fluctuations with no directional information
- **Trend persistence:** In strong moves, RSI stays below 30 for dozens of candles — each one a false buy signal
- **Whipsaw frequency:** 5-10 false entries per session is common

## The Double RSI Concept

Use two RSIs with different periods:

- **Fast RSI (period 7):** Captures momentum shifts early. Your trigger.
- **Slow RSI (period 21):** Filters noise. Your confirmation.

**Buy signal:** Fast RSI < 30 (oversold) AND Slow RSI < 40 (confirming bearish context)

The 3:1 ratio between slow and fast periods ensures they capture genuinely different timeframes. If both agree, the signal is real. If only the fast RSI triggers, it's likely noise.

## MQL5 Implementation

### Core Setup

```mql5
input int    FastRSI_Period = 7;
input int    SlowRSI_Period = 21;
input int    FastRSI_Oversold = 30;
input int    SlowRSI_Confirm = 40;

int handleFastRSI, handleSlowRSI;

int OnInit()
{
   handleFastRSI = iRSI(_Symbol, PERIOD_CURRENT, FastRSI_Period, PRICE_CLOSE);
   handleSlowRSI = iRSI(_Symbol, PERIOD_CURRENT, SlowRSI_Period, PRICE_CLOSE);
   
   if(handleFastRSI == INVALID_HANDLE || handleSlowRSI == INVALID_HANDLE)
      return(INIT_FAILED);
   
   return(INIT_SUCCEEDED);
}
```

### Signal Detection with Crossover

```mql5
enum SIGNAL_TYPE { SIGNAL_NONE, SIGNAL_BUY, SIGNAL_SELL };

SIGNAL_TYPE CheckDoubleRSICrossover()
{
   double fastBuf[3], slowBuf[3];
   
   if(CopyBuffer(handleFastRSI, 0, 0, 3, fastBuf) < 3) return SIGNAL_NONE;
   if(CopyBuffer(handleSlowRSI, 0, 0, 3, slowBuf) < 3) return SIGNAL_NONE;
   
   // BUY: Fast RSI crosses up through oversold while Slow RSI confirms
   if(fastBuf[1] < FastRSI_Oversold && fastBuf[0] >= FastRSI_Oversold 
      && slowBuf[0] < SlowRSI_Confirm)
      return SIGNAL_BUY;
   
   // SELL: Mirror logic for overbought
   if(fastBuf[1] > (100-FastRSI_Oversold) && fastBuf[0] <= (100-FastRSI_Oversold) 
      && slowBuf[0] > (100-SlowRSI_Confirm))
      return SIGNAL_SELL;
   
   return SIGNAL_NONE;
}
```

### Essential Filters

Always add these for scalping:

```mql5
void OnTick()
{
   // Spread filter
   double spread = (SymbolInfoDouble(_Symbol,SYMBOL_ASK) - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / _Point;
   if(spread > 20) return;
   
   // Time filter: London-NY overlap
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   if(dt.hour < 12 || dt.hour >= 16) return;
   
   // Double RSI signal
   SIGNAL_TYPE signal = CheckDoubleRSICrossover();
   if(signal == SIGNAL_BUY)  ExecuteBuy();
   if(signal == SIGNAL_SELL) ExecuteSell();
}
```

## Backtesting Results

Tested on GBPUSD M5, January 2023 – December 2024, real tick data:

- **Single RSI(14):** 847 trades, 52.3% win rate, profit factor 1.08, max DD 18.4%
- **Double RSI (7/21):** 312 trades, 64.7% win rate, profit factor 1.61, max DD 9.2%

The Double RSI generates a third of the signals but nearly doubles the profit factor and halves the drawdown. Fewer trades, better quality.

**Optimization tips:** Use walk-forward analysis (optimize 6 months, validate 3). Test neighboring parameter values to check stability. The 7/21 combination shows strong robustness across multiple walk-forward windows on GBP pairs.

## Practical Tips

- **Start buy-only on GBP pairs** — positive swap adds a secondary edge
- **Never risk more than 1-2% per trade** — position sizing matters more than entry
- **Watch RSI divergence** — when fast RSI makes a new low but slow RSI makes a higher low, that's a high-probability setup
- **Trust the filter** — the hardest part is *not* trading when only the fast RSI triggers

## Conclusion

The Double RSI addresses a structural weakness of standard RSI: premature signals in fast markets. By requiring two different lookback periods to agree, you filter noise while preserving sensitivity to genuine reversals.

I've built a complete implementation of this approach — with additional filters and risk management — in my EA **[GBP RSI Buy Milker](https://www.mql5.com/en/market/product/141033)** on the MQL5 Market, designed specifically for GBPUSD scalping. The code above gives you the foundation to build and test your own version.

---

**Jaume Sancho** — Algorithmic trader and MQL5 developer specializing in GBP scalping strategies.
