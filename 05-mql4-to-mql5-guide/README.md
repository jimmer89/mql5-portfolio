# MQL4 to MQL5 Migration Guide

A comprehensive guide for developers transitioning from MQL4 to MQL5, featuring key differences, function equivalencies, practical code examples, and a complete migration checklist.

## Overview

MQL5 represents a significant evolution from MQL4, bringing object-oriented programming capabilities, improved performance, and enhanced trading functionality. This guide provides everything you need to successfully migrate your MQL4 code to MQL5.

## Key Differences

### 1. **Programming Paradigm**

| Aspect | MQL4 | MQL5 |
|--------|------|------|
| Programming Style | Procedural | Object-Oriented + Procedural |
| Type Safety | Weak | Strong |
| Classes | Limited | Full OOP support |
| Pointers | No | Yes |
| Templates | No | Yes |

### 2. **Account & Order Management**

**MQL4:** Uses simple functions like `OrderSend()`, `OrderModify()`, `OrderClose()`

**MQL5:** Uses position-based trading with CTrade class:
- Positions are separate from orders
- Orders can generate multiple positions (partial fills)
- Position tracking via ticket system

### 3. **Indicator Handling**

**MQL4:** Direct buffer access
```mql4
double ma = iMA(Symbol(), PERIOD_H1, 14, 0, MODE_SMA, PRICE_CLOSE, 0);
```

**MQL5:** Handle-based system
```mql5
int ma_handle = iMA(Symbol(), PERIOD_H1, 14, 0, MODE_SMA, PRICE_CLOSE);
double ma[];
CopyBuffer(ma_handle, 0, 0, 1, ma);
```

### 4. **Event Handling Functions**

| MQL4 | MQL5 | Purpose |
|------|------|---------|
| `init()` | `OnInit()` | Initialization |
| `deinit()` | `OnDeinit()` | Deinitialization |
| `start()` | `OnTick()` (EA) / `OnCalculate()` (Indicator) | Main execution |

## Function Equivalency Table

### Order/Position Functions

| MQL4 Function | MQL5 Equivalent | Notes |
|---------------|-----------------|-------|
| `OrderSend()` | `CTrade::Buy()` / `CTrade::Sell()` | Use CTrade class |
| `OrderClose()` | `CTrade::PositionClose()` | Close by ticket |
| `OrderModify()` | `CTrade::PositionModify()` | Modify SL/TP |
| `OrderSelect()` | `PositionSelect()` / `CPositionInfo::SelectByTicket()` | Position selection |
| `OrdersTotal()` | `PositionsTotal()` | Count open positions |
| `OrderTicket()` | `PositionGetTicket()` | Get position ticket |
| `OrderProfit()` | `PositionGetDouble(POSITION_PROFIT)` | Get profit |
| `OrderLots()` | `PositionGetDouble(POSITION_VOLUME)` | Get volume |

### Account Functions

| MQL4 Function | MQL5 Equivalent | Notes |
|---------------|-----------------|-------|
| `AccountBalance()` | `AccountInfoDouble(ACCOUNT_BALANCE)` | Account balance |
| `AccountEquity()` | `AccountInfoDouble(ACCOUNT_EQUITY)` | Account equity |
| `AccountFreeMargin()` | `AccountInfoDouble(ACCOUNT_MARGIN_FREE)` | Free margin |
| `AccountProfit()` | `AccountInfoDouble(ACCOUNT_PROFIT)` | Current profit |

### Symbol/Market Functions

| MQL4 Function | MQL5 Equivalent | Notes |
|---------------|-----------------|-------|
| `MarketInfo()` | `SymbolInfoDouble()` / `SymbolInfoInteger()` | Symbol properties |
| `Bid` | `SymbolInfoDouble(_Symbol, SYMBOL_BID)` | Current Bid |
| `Ask` | `SymbolInfoDouble(_Symbol, SYMBOL_ASK)` | Current Ask |
| `Point` | `SymbolInfoDouble(_Symbol, SYMBOL_POINT)` | Point size |
| `Digits` | `SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)` | Decimal places |

### Time/Bar Functions

| MQL4 Function | MQL5 Equivalent | Notes |
|---------------|-----------------|-------|
| `Time[]` | `iTime()` | Bar time |
| `Open[]` | `iOpen()` | Bar open price |
| `High[]` | `iHigh()` | Bar high price |
| `Low[]` | `iLow()` | Bar low price |
| `Close[]` | `iClose()` | Bar close price |
| `Volume[]` | `iVolume()` | Bar volume |
| `Bars` | `Bars(_Symbol, _Period)` | Total bars |

### Indicator Functions

All indicator functions now return handles instead of values:

| MQL4 | MQL5 Pattern |
|------|--------------|
| `iMA(...)` returns value | `iMA(...)` returns handle, use `CopyBuffer()` |
| `iRSI(...)` returns value | `iRSI(...)` returns handle, use `CopyBuffer()` |
| `iMACD(...)` returns value | `iMACD(...)` returns handle, use `CopyBuffer()` |

## Practical Example

See the [examples/](examples/) folder for a complete working example of an EA in both MQL4 and MQL5.

### Simple EA Comparison

**MQL4 Version:** [original_mql4.mq4](examples/original_mql4.mq4)
- Traditional procedural approach
- Direct function calls
- Simple order management

**MQL5 Version:** [converted_mql5.mq5](examples/converted_mql5.mq5)
- Uses CTrade class
- Handle-based indicators
- Modern position management

## Migration Workflow

1. **Read the Checklist:** Start with [MIGRATION_CHECKLIST.md](MIGRATION_CHECKLIST.md)
2. **Study Examples:** Compare the MQL4 and MQL5 example files
3. **Convert Step-by-Step:** Don't convert everything at once
4. **Test Frequently:** Compile and test after each major change
5. **Use Classes:** Leverage MQL5's OOP capabilities (CTrade, CPositionInfo, etc.)

## Common Pitfalls

### 1. **Assuming Direct Translation**
Don't try to directly replace MQL4 functions 1:1. Understand the new architecture.

### 2. **Ignoring Handles**
Always store and release indicator handles properly to avoid memory leaks.

### 3. **Old Order Selection Logic**
MQL5 uses positions, not orders. Your selection logic needs to change.

### 4. **Forgetting Array Direction**
MQL5 arrays are not series by default. Use `ArraySetAsSeries(array, true)` when needed.

### 5. **Not Using Standard Libraries**
MQL5 provides powerful classes. Use them instead of reinventing the wheel.

## Advantages of MQL5

✅ **Better Performance:** Optimized compiler, faster execution  
✅ **Modern Architecture:** Object-oriented, cleaner code structure  
✅ **Enhanced Debugging:** Better debugging tools and error handling  
✅ **Multi-Currency Testing:** Strategy Tester supports multiple symbols  
✅ **Economic Calendar:** Built-in access to news events  
✅ **More Timeframes:** 21 timeframes vs 9 in MQL4  
✅ **Better Backtesting:** More accurate historical simulation  

## Resources

- **Official Documentation:** [MQL5 Reference](https://www.mql5.com/en/docs)
- **Migration Article:** [MQL5 Wizard - MQL4 to MQL5](https://www.mql5.com/en/articles/81)
- **Community Forum:** [MQL5 Forum](https://www.mql5.com/en/forum)
- **Code Base:** [MQL5 Code Base](https://www.mql5.com/en/code)

## License

MIT License - See [LICENSE](../LICENSE) for details.

## Author

**Jaume Sancho**  
GitHub: [@jimmer89](https://github.com/jimmer89)

---

*This guide is based on years of experience migrating trading systems from MQL4 to MQL5. While comprehensive, always refer to official documentation for the latest updates.*
