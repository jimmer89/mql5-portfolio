# MQL5 Trading Tools Portfolio

A collection of professional trading tools and expert advisors for MetaTrader 5, developed with a focus on algorithmic trading and market analysis.

## About

I'm Jaume Sancho, a developer specializing in algorithmic trading systems and market structure analysis. This portfolio showcases my work with MQL5, combining technical analysis concepts with robust code architecture for reliable automated trading solutions.

## Projects

### 1. [RSI Alert EA](01-rsi-alert-ea/)
Multi-channel alert system based on RSI indicators with visual feedback and customizable threshold notifications.

**Key Features:**
- Push notifications, email alerts, and sound alarms
- Visual arrows on chart when signals trigger
- Real-time dashboard showing current RSI status
- Fully customizable RSI parameters and alert levels

### 2. [MA Crossover EA](02-ma-crossover-ea/)
Classic moving average crossover strategy with comprehensive risk management and trade execution controls.

**Key Features:**
- Automated trading on MA crossover signals
- Configurable MA types (SMA/EMA/SMMA/LWMA)
- Built-in stop loss, take profit, and trailing stop
- Spread filtering and position management

### 3. [Market Structure Indicator](03-market-structure-ea/)
Advanced indicator for identifying market structure patterns including swing points, BOS (Break of Structure), and CHoCH (Change of Character).

**Key Features:**
- Automatic swing high/low detection
- HH, HL, LH, LL pattern identification
- Visual structure mapping with labels and lines
- BOS and CHoCH detection with optional alerts

### 4. [Breakout EA](04-breakout-ea/)
Range breakout trading system with false breakout filtering and session-based trade timing.

**Key Features:**
- Dynamic range calculation based on lookback period
- Session filtering (London/NY hours)
- Breakout confirmation with candle close
- Spread and minimum distance filters
- Visual range display on chart

### 5. [MQL4 to MQL5 Migration Guide](05-mql4-to-mql5-guide/)
Comprehensive guide for developers transitioning from MQL4 to MQL5, with practical examples and conversion checklist.

**Contents:**
- Key differences between MQL4 and MQL5
- Function equivalency table
- Practical conversion examples
- Step-by-step migration checklist

## Tech Stack

- **Language:** MQL5
- **Platform:** MetaTrader 5
- **Style:** C++ influenced, object-oriented where applicable
- **Libraries:** Native MQL5 classes (CTrade, CPositionInfo, CSymbolInfo, etc.)

## Installation

Each project folder contains specific installation instructions. General steps:

1. Copy the `.mq5` file to your MetaTrader 5 installation:
   - For EAs: `MQL5/Experts/`
   - For Indicators: `MQL5/Indicators/`
2. Compile the file in MetaEditor (F7)
3. Restart MetaTrader 5 or refresh the Navigator panel
4. Drag the tool onto your chart and configure parameters

## Backtesting

All EAs in this portfolio support MetaTrader 5's Strategy Tester. Refer to individual project READMEs for specific backtesting recommendations and parameter optimization tips.

## License

All projects in this portfolio are released under the MIT License. See [LICENSE](LICENSE) for details.

## Published on MQL5 Market

- **[Tokyo Trigger](https://www.mql5.com/en/market/product/141281)** — Stochastic breakout EA for USDJPY H1, backtested 2012-2025 ($199)
- **[GBP RSI Buy Milker](https://www.mql5.com/en/market/product/141033)** — Double RSI scalping EA for GBPUSD M1, backtested 2003-2025 ($50)

## Contact

- **MQL5:** [WhiteChocolate](https://www.mql5.com/en/users/whitechocolate)
- **GitHub:** [@jimmer89](https://github.com/jimmer89)
