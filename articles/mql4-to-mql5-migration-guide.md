# MQL4 to MQL5 Migration: A Practical Guide from the Trenches

*By Jaume Sancho | 2026*

---

## Introduction

If you're reading this, you probably have a working MQL4 EA or indicator that you need to port to MQL5. Maybe your broker is phasing out MT4, maybe you want access to MQL5's better backtesting, or maybe a client is paying you to convert their legacy code.

Whatever your reason, I've been there. I've migrated dozens of EAs and indicators, and I can tell you: **it's not a simple find-and-replace job**. But it's also not as scary as it looks.

This guide gives you the practical knowledge I wish I had when I started.

---

## The Big Picture: What Actually Changed?

Before diving into code, understand the architectural shift:

### MQL4: Simple and Direct
```mql4
// Want the RSI? Just call it.
double rsi = iRSI(NULL, 0, 14, PRICE_CLOSE, 0);

// Want to open a trade? One function.
int ticket = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 3, 0, 0);
```

### MQL5: Handle-Based and Object-Oriented
```mql5
// RSI requires a handle (create once, use many times)
int rsi_handle = iRSI(_Symbol, _Period, 14, PRICE_CLOSE);
double rsi_buffer[];
ArraySetAsSeries(rsi_buffer, true);
CopyBuffer(rsi_handle, 0, 0, 1, rsi_buffer);
double rsi = rsi_buffer[0];

// Trading uses the CTrade class
#include <Trade\Trade.mqh>
CTrade trade;
trade.Buy(0.1, _Symbol);
```

**Why the change?** Performance. MQL5's handle system lets the terminal cache indicator calculations. In MQL4, `iRSI()` recalculates every time you call it. In MQL5, you calculate once and read from memory.

---

## Step 1: The Entry Points

This is the easy part. Find and replace:

| MQL4 | MQL5 | Notes |
|------|------|-------|
| `init()` | `OnInit()` | Must return `INIT_SUCCEEDED` or `INIT_FAILED` |
| `deinit()` | `OnDeinit(const int reason)` | Now receives a reason code |
| `start()` | `OnTick()` | For EAs |
| `start()` | `OnCalculate(...)` | For indicators (different signature!) |

**Common mistake:** Forgetting that `OnInit()` must return an int. Your MQL4 `init()` that returned 0 needs to return `INIT_SUCCEEDED`.

```mql5
int OnInit()
{
   // Setup code...
   
   if(something_failed)
      return(INIT_FAILED);
      
   return(INIT_SUCCEEDED);
}
```

---

## Step 2: Add the Trade Libraries

At the top of your file, add:

```mql5
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
```

Then declare global instances:

```mql5
CTrade trade;
CPositionInfo position;
CSymbolInfo symbol_info;
```

In `OnInit()`:

```mql5
trade.SetExpertMagicNumber(MagicNumber);
trade.SetDeviationInPoints(10);
symbol_info.Name(_Symbol);
```

---

## Step 3: Converting Order Functions

This is where most people struggle. MQL5 separates **orders** (pending) from **positions** (open trades).

### Opening Trades

**MQL4:**
```mql4
int ticket = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 3, sl, tp, "Comment", Magic);
if(ticket < 0) Print("Error: ", GetLastError());
```

**MQL5:**
```mql5
if(!trade.Buy(0.1, _Symbol, 0, sl, tp, "Comment"))
{
   Print("Error: ", trade.ResultRetcodeDescription());
}
```

Note: In MQL5, passing 0 as price means "use current market price" — the class handles Ask/Bid automatically.

### Closing Trades

**MQL4:**
```mql4
OrderClose(ticket, OrderLots(), Bid, 3);
```

**MQL5:**
```mql5
trade.PositionClose(ticket);
```

### Checking Open Positions

**MQL4:**
```mql4
for(int i = OrdersTotal() - 1; i >= 0; i--)
{
   if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
   {
      if(OrderSymbol() == Symbol() && OrderMagicNumber() == Magic)
      {
         // Found our position
      }
   }
}
```

**MQL5:**
```mql5
for(int i = PositionsTotal() - 1; i >= 0; i--)
{
   if(position.SelectByIndex(i))
   {
      if(position.Symbol() == _Symbol && position.Magic() == Magic)
      {
         // Found our position
      }
   }
}
```

---

## Step 4: Converting Indicators

This is the biggest mental shift. **Create handles once, read values many times.**

### Example: Moving Average

**MQL4:**
```mql4
double ma = iMA(NULL, 0, 20, 0, MODE_SMA, PRICE_CLOSE, 0);
double ma_prev = iMA(NULL, 0, 20, 0, MODE_SMA, PRICE_CLOSE, 1);
```

**MQL5:**
```mql5
// Declare at global level
int ma_handle;
double ma_buffer[];

// In OnInit()
ma_handle = iMA(_Symbol, _Period, 20, 0, MODE_SMA, PRICE_CLOSE);
if(ma_handle == INVALID_HANDLE)
{
   Print("Error creating MA handle");
   return(INIT_FAILED);
}
ArraySetAsSeries(ma_buffer, true);

// In OnTick()
if(CopyBuffer(ma_handle, 0, 0, 2, ma_buffer) < 2)
   return; // Not enough data
   
double ma = ma_buffer[0];
double ma_prev = ma_buffer[1];

// In OnDeinit() - IMPORTANT!
IndicatorRelease(ma_handle);
```

**Why `ArraySetAsSeries()`?** MQL5 arrays index from oldest to newest by default. Setting as series flips it so index 0 is the current bar (like MQL4).

---

## Step 5: Price Data

**MQL4:**
```mql4
double close = Close[0];
double high = High[1];
datetime time = Time[0];
```

**MQL5:**
```mql5
double close = iClose(_Symbol, _Period, 0);
double high = iHigh(_Symbol, _Period, 1);
datetime time = iTime(_Symbol, _Period, 0);
```

Or using arrays:
```mql5
double close[], high[];
ArraySetAsSeries(close, true);
ArraySetAsSeries(high, true);
CopyClose(_Symbol, _Period, 0, 10, close);
CopyHigh(_Symbol, _Period, 0, 10, high);
// Now close[0] is current bar, close[1] is previous, etc.
```

---

## Step 6: Account and Symbol Info

**MQL4:**
```mql4
double balance = AccountBalance();
double equity = AccountEquity();
double point = Point;
int digits = Digits;
double bid = Bid;
double ask = Ask;
```

**MQL5:**
```mql5
double balance = AccountInfoDouble(ACCOUNT_BALANCE);
double equity = AccountInfoDouble(ACCOUNT_EQUITY);
double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

// Or using CSymbolInfo class:
symbol_info.RefreshRates();
double bid = symbol_info.Bid();
double ask = symbol_info.Ask();
```

---

## Common Pitfalls (Learn from My Mistakes)

### 1. Forgetting to Release Handles
Memory leak alert! Always release indicator handles in `OnDeinit()`:
```mql5
void OnDeinit(const int reason)
{
   IndicatorRelease(ma_handle);
   IndicatorRelease(rsi_handle);
   // etc.
}
```

### 2. Arrays Not Set as Series
Your code looks right but gives wrong values? Check `ArraySetAsSeries()`. MQL5 arrays are "as series" = false by default.

### 3. Bid/Ask Not Updating
`symbol_info.Bid()` returns cached values. Call `symbol_info.RefreshRates()` first, or use `SymbolInfoDouble()` directly.

### 4. Position vs Order Confusion
- `OrdersTotal()` = pending orders only
- `PositionsTotal()` = open positions only

In MQL4, `OrdersTotal()` included both. In MQL5, they're separate.

### 5. ENUM Changes
Some enums changed names:
- `OP_BUY` → `ORDER_TYPE_BUY` (but `trade.Buy()` handles this)
- `MODE_SMA` → Same name, but check the value matches
- `PRICE_CLOSE` → Same name

---

## Quick Reference Card

| Task | MQL4 | MQL5 |
|------|------|------|
| Current bid | `Bid` | `SymbolInfoDouble(_Symbol, SYMBOL_BID)` |
| Current ask | `Ask` | `SymbolInfoDouble(_Symbol, SYMBOL_ASK)` |
| Point size | `Point` | `SymbolInfoDouble(_Symbol, SYMBOL_POINT)` |
| Digits | `Digits` | `SymbolInfoInteger(_Symbol, SYMBOL_DIGITS)` |
| Current close | `Close[0]` | `iClose(_Symbol, _Period, 0)` |
| Bar count | `Bars` | `Bars(_Symbol, _Period)` |
| Open buy | `OrderSend(..., OP_BUY, ...)` | `trade.Buy(...)` |
| Close position | `OrderClose(ticket, ...)` | `trade.PositionClose(ticket)` |
| Count positions | `OrdersTotal()` | `PositionsTotal()` |
| Get MA value | `iMA(..., shift)` | `CopyBuffer(ma_handle, ...)` |

---

## Migration Checklist

- [ ] Rename `init()` → `OnInit()` (return `INIT_SUCCEEDED`)
- [ ] Rename `deinit()` → `OnDeinit(const int reason)`
- [ ] Rename `start()` → `OnTick()` (EA) or `OnCalculate()` (indicator)
- [ ] Add `#include <Trade\Trade.mqh>` and friends
- [ ] Create `CTrade trade;` global variable
- [ ] Set magic number in `OnInit()`: `trade.SetExpertMagicNumber(Magic)`
- [ ] Convert all `OrderSend()` → `trade.Buy()/Sell()`
- [ ] Convert all `OrderClose()` → `trade.PositionClose()`
- [ ] Convert order loops to position loops
- [ ] Convert indicators to handle-based system
- [ ] Add `IndicatorRelease()` calls in `OnDeinit()`
- [ ] Replace `Bid/Ask` with `SymbolInfoDouble()`
- [ ] Replace `Close[]/High[]/etc.` with `iClose()/iHigh()/etc.`
- [ ] Test thoroughly in Strategy Tester

---

## Final Thoughts

MQL5 migration isn't just about making code compile — it's about understanding the new architecture. Once you internalize the handle-based indicator system and the position-based order management, everything clicks.

The payoff is worth it: faster backtesting, cleaner code, better debugging tools, and access to the growing MQL5 marketplace.

Need help migrating your EA? Check my [GitHub portfolio](https://github.com/jimmer89/mql5-portfolio) for examples, or reach out on [MQL5.com](https://www.mql5.com/en/users/whitechocolate).

---

*© 2026 Jaume Sancho. Free to use and share with attribution.*
