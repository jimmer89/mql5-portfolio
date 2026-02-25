# MQL4 to MQL5 Migration Checklist

Use this checklist to systematically migrate your MQL4 Expert Advisors, Indicators, and Scripts to MQL5.

## Pre-Migration Preparation

- [ ] **Backup Original Code** - Keep your working MQL4 version safe
- [ ] **Document Functionality** - List all features and behaviors
- [ ] **Review Dependencies** - Identify all custom indicators and libraries used
- [ ] **Understand Current Logic** - Make sure you know what the code does
- [ ] **Set Up MQL5 Environment** - Install MetaTrader 5 and MetaEditor

## Code Structure Changes

### File Header & Properties

- [ ] Change file extension from `.mq4` to `.mq5`
- [ ] Update `#property` directives:
  - [ ] `#property copyright`
  - [ ] `#property link`
  - [ ] `#property version`
  - [ ] `#property description`
  - [ ] `#property indicator_*` (for indicators)
- [ ] Add `#property strict` equivalent behavior (MQL5 is strict by default)

### Function Names

- [ ] Rename `init()` → `OnInit()`
- [ ] Rename `deinit()` → `OnDeinit(const int reason)`
- [ ] Rename `start()` → `OnTick()` (for EAs) or `OnCalculate()` (for indicators)
- [ ] Update return types:
  - [ ] `OnInit()` returns `int` (INIT_SUCCEEDED or INIT_FAILED)
  - [ ] `OnDeinit()` returns `void`, receives reason parameter
  - [ ] `OnTick()` returns `void`

## Order & Position Management

### Include Standard Libraries

- [ ] Add `#include <Trade\Trade.mqh>`
- [ ] Add `#include <Trade\PositionInfo.mqh>`
- [ ] Add `#include <Trade\SymbolInfo.mqh>`

### Create Class Instances

- [ ] Declare `CTrade trade;` global variable
- [ ] Declare `CPositionInfo position;` global variable
- [ ] Declare `CSymbolInfo symbol_info;` global variable

### Replace Order Functions

- [ ] Replace `OrderSend()` with:
  - [ ] `trade.Buy()` for buy orders
  - [ ] `trade.Sell()` for sell orders
  - [ ] `trade.BuyLimit()` / `trade.SellLimit()` for limit orders
  - [ ] `trade.BuyStop()` / `trade.SellStop()` for stop orders

- [ ] Replace `OrderClose()` with `trade.PositionClose(ticket)`

- [ ] Replace `OrderModify()` with `trade.PositionModify(ticket, sl, tp)`

- [ ] Replace `OrderDelete()` with `trade.OrderDelete(ticket)`

### Replace Order Selection

- [ ] Replace `OrderSelect()` loops with position/order loops:
  ```mql5
  for(int i = PositionsTotal() - 1; i >= 0; i--)
  {
     if(position.SelectByIndex(i))
     {
        // Access position properties via position object
     }
  }
  ```

### Replace Order Properties

- [ ] `OrderTicket()` → `position.Ticket()`
- [ ] `OrderType()` → `position.PositionType()`
- [ ] `OrderLots()` → `position.Volume()`
- [ ] `OrderOpenPrice()` → `position.PriceOpen()`
- [ ] `OrderStopLoss()` → `position.StopLoss()`
- [ ] `OrderTakeProfit()` → `position.TakeProfit()`
- [ ] `OrderProfit()` → `position.Profit()`
- [ ] `OrderSymbol()` → `position.Symbol()`
- [ ] `OrderMagicNumber()` → `position.Magic()`

### Magic Number Setup

- [ ] Set magic number: `trade.SetExpertMagicNumber(magic_number);`
- [ ] Filter positions by magic: `position.Magic() == magic_number`

## Account Information

- [ ] Replace `AccountBalance()` with `AccountInfoDouble(ACCOUNT_BALANCE)`
- [ ] Replace `AccountEquity()` with `AccountInfoDouble(ACCOUNT_EQUITY)`
- [ ] Replace `AccountFreeMargin()` with `AccountInfoDouble(ACCOUNT_MARGIN_FREE)`
- [ ] Replace `AccountProfit()` with `AccountInfoDouble(ACCOUNT_PROFIT)`
- [ ] Replace `AccountLeverage()` with `AccountInfoInteger(ACCOUNT_LEVERAGE)`

## Symbol/Market Information

- [ ] Initialize symbol info: `symbol_info.Name(_Symbol)`
- [ ] Replace `Bid` with `symbol_info.Bid()` or `SymbolInfoDouble(_Symbol, SYMBOL_BID)`
- [ ] Replace `Ask` with `symbol_info.Ask()` or `SymbolInfoDouble(_Symbol, SYMBOL_ASK)`
- [ ] Replace `Point` with `symbol_info.Point()` or `SymbolInfoDouble(_Symbol, SYMBOL_POINT)`
- [ ] Replace `Digits` with `symbol_info.Digits()` or `SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)`
- [ ] Replace `MarketInfo()` with `SymbolInfoDouble()` or `SymbolInfoInteger()`

## Time Series & Bar Data

### Array Setup

- [ ] Declare arrays for bar data
- [ ] Set arrays as series: `ArraySetAsSeries(array, true);`

### Replace Direct Array Access

- [ ] Replace `Time[index]` with `iTime(_Symbol, _Period, index)`
- [ ] Replace `Open[index]` with `iOpen(_Symbol, _Period, index)`
- [ ] Replace `High[index]` with `iHigh(_Symbol, _Period, index)`
- [ ] Replace `Low[index]` with `iLow(_Symbol, _Period, index)`
- [ ] Replace `Close[index]` with `iClose(_Symbol, _Period, index)`
- [ ] Replace `Volume[index]` with `iVolume(_Symbol, _Period, index)`

### Bar Count

- [ ] Replace `Bars` with `Bars(_Symbol, _Period)`
- [ ] Replace `iBars()` with `Bars(_Symbol, timeframe)`

## Indicators

### Handle-Based Approach

For each indicator used:

- [ ] Create handle in `OnInit()`:
  ```mql5
  int indicator_handle = iIndicatorName(...);
  if(indicator_handle == INVALID_HANDLE) return(INIT_FAILED);
  ```

- [ ] Declare buffer array
- [ ] Set buffer as series: `ArraySetAsSeries(buffer, true);`
- [ ] Copy indicator data: `CopyBuffer(handle, buffer_num, start, count, buffer);`
- [ ] Release handle in `OnDeinit()`: `IndicatorRelease(indicator_handle);`

### Common Indicator Conversions

- [ ] iMA: Create handle, use CopyBuffer
- [ ] iRSI: Create handle, use CopyBuffer
- [ ] iMACD: Create handle, use CopyBuffer (main=0, signal=1)
- [ ] iStochastic: Create handle, use CopyBuffer (main=0, signal=1)
- [ ] iBands: Create handle, use CopyBuffer (upper=1, middle=0, lower=2)

## Custom Indicators (For Indicator Migration)

- [ ] Update `OnCalculate()` signature:
  ```mql5
  int OnCalculate(const int rates_total,
                  const int prev_calculated,
                  const datetime &time[],
                  const double &open[],
                  const double &high[],
                  const double &low[],
                  const double &close[],
                  const long &tick_volume[],
                  const long &volume[],
                  const int &spread[])
  ```

- [ ] Replace buffer declarations with `#property indicator_buffers` and `SetIndexBuffer()`
- [ ] Set all input arrays as series at the start of `OnCalculate()`
- [ ] Return `rates_total` instead of `0`

## Error Handling

- [ ] Replace `GetLastError()` with `GetLastError()` (same in MQL5 but check new error codes)
- [ ] Update error code checks to MQL5 equivalents
- [ ] Add proper error handling for all trade operations:
  ```mql5
  if(!trade.Buy(...))
  {
     Print("Error: ", trade.ResultRetcodeDescription());
  }
  ```

## Input Parameters

- [ ] Review all `input` parameters
- [ ] Use `sinput` for parameters that shouldn't change during optimization
- [ ] Add input groups with `input group "Group Name"`
- [ ] Update enum types if needed (some enums have changed)

## Objects & Graphics

- [ ] Update `ObjectCreate()` calls (signature changed slightly)
- [ ] Update `ObjectSet*()` functions to `ObjectSetInteger()`, `ObjectSetDouble()`, `ObjectSetString()`
- [ ] Update `ObjectGet()` functions to `ObjectGetInteger()`, `ObjectGetDouble()`, `ObjectGetString()`
- [ ] Chart ID parameter: Most functions now require chart ID (use `0` for current chart)

## Testing & Validation

### Compilation

- [ ] Compile code (F7 in MetaEditor)
- [ ] Fix all compiler errors and warnings
- [ ] Ensure no deprecated function warnings

### Strategy Tester

- [ ] Run in Strategy Tester with historical data
- [ ] Compare results with MQL4 version (they should be similar)
- [ ] Verify all trades are executed correctly
- [ ] Check SL/TP placement
- [ ] Validate magic number filtering

### Visual Testing

- [ ] Test on demo account
- [ ] Verify chart objects display correctly
- [ ] Check indicator plotting (for indicators)
- [ ] Test all alerts and notifications

### Edge Cases

- [ ] Test with different lot sizes
- [ ] Test with different symbols
- [ ] Test with different timeframes
- [ ] Test position modification
- [ ] Test during high volatility/spread

## Optimization & Cleanup

- [ ] Remove any MQL4-specific workarounds
- [ ] Use MQL5 OOP features where appropriate
- [ ] Add proper comments and documentation
- [ ] Format code consistently
- [ ] Remove unused variables and functions
- [ ] Consider performance optimizations

## Final Steps

- [ ] Update version number
- [ ] Update copyright and description
- [ ] Create README with usage instructions
- [ ] Document any behavior changes from MQL4 version
- [ ] Create backups of both versions
- [ ] Share or deploy migrated code

## Notes

- **Don't Rush:** Take your time with each step
- **Test Frequently:** Compile and test after each major change
- **Keep MQL4 Version:** Don't delete your working MQL4 code until MQL5 version is fully tested
- **Use Debugger:** MQL5 has better debugging tools - use them!
- **Read Docs:** When stuck, refer to official MQL5 documentation

---

**Remember:** Migration is not just about making code compile - it's about understanding the new architecture and writing better, more maintainable code.
