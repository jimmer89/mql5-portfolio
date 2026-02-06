# MQL5 Proposals — 2 Feb 2026
> Copy-paste ready. Adaptar si hace falta.

---

## 1. EMA50/200 Trend + Pullback EA ($40+, 16 apps)
**Proyecto:** Convertir estrategia específica en EA automatizado. H1 trend (EMA50/200), M15 entry en pullback, SL en high/low, TP 2x SL.

```
Hi,

I can build this EA exactly as described. The strategy is clean and well-defined — I've built similar multi-timeframe EAs using EMA trend filters with pullback entries before.

Here's what I'll deliver:
- Full MT5 EA with H1 trend detection (EMA50 vs EMA200)
- M15 pullback entry logic with candlestick confirmation
- Dynamic SL (last swing high/low) and TP at 2× SL (1:2 RR)
- Clean input panel for all parameters (EMA periods, lot size, max spread, etc.)
- Tested in Strategy Tester before delivery

Timeline: 5-7 days
Budget: $40

I can start right away. Happy to discuss any details about the entry logic or additional features you'd like.

Best regards,
Jaume
```

---

## 2. Object-based ZigZag & Running Fibonacci ($30+, 11 apps) ⭐ LOW COMPETITION
**Proyecto:** EA que dibuje ZigZag custom con objetos (NO usar indicador built-in) + Fibonacci dinámico.

```
Hi,

I understand the requirements clearly — custom object-based ZigZag drawn by the EA itself, no external indicators needed. I've worked with chart objects extensively in MQL5 (lines, trendlines, Fibonacci objects).

What I'll deliver:
- EA draws ZigZag directly on chart using OBJ_TREND objects
- Custom swing detection logic (configurable sensitivity)
- Running Fibonacci levels auto-drawn between latest ZigZag pivots
- All objects managed by the EA (created, updated, cleaned on removal)
- User attaches EA → ZigZag + Fib appear automatically

I read all your conditions carefully. If you'd like, I can share a quick prototype within 2-3 days so you can verify the ZigZag logic before I complete the Fibonacci part.

Timeline: 7 days
Budget: $30+

Let me know if you have additional specs to share.

Best,
Jaume
```

---

## 3. Candlestick & High/Low EA with Panel ($30-60, 23 apps)
**Proyecto:** EA basado en candlesticks y highs/lows, con panel visual. Cliente tiene especificaciones completas.

```
Hi,

Professional MQL5 developer here. I'd be happy to build your EA based on candlestick patterns and high/low logic.

Since you have full specifications ready, I can follow them precisely. I have experience building EAs with:
- Candlestick pattern recognition (engulfing, pin bars, doji, etc.)
- High/low structure detection and breakout logic
- Custom visual panels with real-time trade info

I'd love to see your detailed specs to give you an accurate timeline and confirm the scope. Please feel free to message me directly.

Timeline: 5-7 days (depending on panel complexity)
Budget: $50

Looking forward to your specifications.

Best regards,
Jaume
```

---

## 4. Supertrend + Moving Average EA ($50+, 37 apps)
**Proyecto:** EA que opere con SuperTrend + EMA rápida/lenta (200). Solo trades cuando SuperTrend cruza fast MA y precio está del lado correcto del 200 EMA.

```
Hi,

The strategy logic is clear — I can build this EA combining SuperTrend crossover with EMA200 as trend confirmation filter. I understand the key rules:

- BUY: SuperTrend flips bullish + crosses fast MA + price above EMA200
- SELL: SuperTrend flips bearish + crosses fast MA + price below EMA200
- Skip trade if SuperTrend crosses the slow EMA200

I'll deliver:
- Full MT5 EA with all parameters configurable (SuperTrend period/multiplier, fast/slow MA periods)
- Entry, SL, and TP logic as per your specifications
- Visual arrows/markers on chart for signal confirmation
- Strategy Tester compatible for backtesting

Timeline: 5-7 days
Budget: $50

Ready to start immediately. Let me know if there are additional conditions I should review.

Best,
Jaume
```

---

## 5. XAUUSD Scalping EA — MQL4/MQL5 ($300+, 31 apps) 💰
**Proyecto:** EA de scalping para Gold (XAUUSD), M1/M5, con gestión de riesgo completa.

```
Hi,

I specialize in building scalping EAs for volatile instruments like XAUUSD. I can develop this for both MT4 and MT5.

What I'll deliver:
- Scalping EA optimized for XAUUSD on M1/M5
- Fixed SL/TP with configurable values
- Risk management: lot sizing by balance % OR fixed lot (user selects)
- Max trades per day limiter
- Spread filter (skip entries during high spread)
- Slippage protection
- Trading session filter (configurable hours)
- Full input panel for all parameters
- Backtested results on XAUUSD before delivery

I have published EAs on the MQL5 Market (Tokyo Trigger, GBP RSI Buy Milker) and maintain a GitHub portfolio with additional projects.

Timeline: 10-14 days
Budget: $300

I take scalping precision seriously — happy to discuss the specific entry/exit logic you have in mind.

Best regards,
Jaume
Portfolio: github.com/jimmer89/mql5-portfolio
MQL5: mql5.com/en/users/whitechocolate
```

---

