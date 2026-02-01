# CodeBase Submission: Market Structure Indicator

## Title
Market Structure Indicator — HH/HL/LH/LL + BOS + CHoCH

## Description

A visual market structure analysis tool for MetaTrader 5 that automatically detects and labels swing points, structure breaks, and trend changes directly on your chart.

### What it does

This indicator identifies swing highs and swing lows using a configurable lookback period, then classifies each swing point relative to the previous one:

- **HH** (Higher High) — bullish continuation
- **HL** (Higher Low) — bullish confirmation  
- **LH** (Lower High) — bearish signal
- **LL** (Lower Low) — bearish continuation

On top of that, it detects:
- **BOS** (Break of Structure) — trend continuation confirmed by breaking previous structure
- **CHoCH** (Change of Character) — potential trend reversal when structure breaks in the opposite direction

### Features

- Automatic swing point detection with configurable lookback (bars on each side)
- Sequential classification of ALL swing points (not just the last two)
- BOS and CHoCH detection with visual dashed lines and labels
- Dotted structure lines connecting consecutive swing highs and swing lows
- Color-coded labels: green (HH), blue (HL), orange (LH), red (LL)
- Configurable colors, font size, line width
- Optional alerts on BOS and CHoCH
- Efficient: full recalculation on load, incremental updates on new bars
- Max history parameter to limit processing on large charts

### Input Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| Swing_Lookback | 5 | Bars to check on each side of a swing point |
| Max_History | 500 | Maximum bars to analyze from current |
| Show_HH_HL | true | Display Higher Highs and Higher Lows |
| Show_LH_LL | true | Display Lower Highs and Lower Lows |
| Show_BOS | true | Display Break of Structure lines |
| Show_CHoCH | true | Display Change of Character lines |
| Draw_Lines | true | Draw dotted lines between swing points |
| Font_Size | 9 | Label font size |
| Enable_Alerts | false | Alert on BOS/CHoCH |

### How to use

1. Attach the indicator to any chart and timeframe
2. Swing points will be labeled automatically (HH, HL, LH, LL)
3. Dotted lines connect consecutive highs and consecutive lows
4. BOS/CHoCH dashed lines appear when structure breaks
5. Use for confluence with your existing strategy — works on any instrument

### Best timeframes

Works on all timeframes. H1 and H4 tend to produce the cleanest structure on most instruments.

### Source code

Full source code also available on GitHub:
https://github.com/jimmer89/mql5-portfolio/tree/master/03-market-structure-ea

---
*Copy-paste into MQL5 CodeBase submission form*
