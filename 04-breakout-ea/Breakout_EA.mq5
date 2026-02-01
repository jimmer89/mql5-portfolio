//+------------------------------------------------------------------+
//|                                                Breakout_EA.mq5 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.10"
#property description "Range Breakout EA with session filtering and false breakout prevention"

//--- Include standard libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "Range Settings"
input int                  Range_Lookback_Bars = 20;         // Range Lookback (bars)
input int                  Min_Breakout_Distance_Pips = 10;  // Min Breakout Distance (pips)

input group "Trade Settings"
input double               Lot_Size = 0.1;                   // Lot Size
input int                  Stop_Loss_Pips = 50;              // Stop Loss (pips)
input int                  Take_Profit_Pips = 100;           // Take Profit (pips)
input bool                 Use_Trailing_Stop = true;         // Use Trailing Stop
input int                  Trailing_Stop_Pips = 30;          // Trailing Stop (pips)
input int                  Trailing_Step_Pips = 10;          // Trailing Step (pips)

input group "Filters"
input double               Max_Spread_Pips = 3.0;            // Max Spread (pips)
input bool                 Use_Session_Filter = true;        // Use Session Filter
input int                  Session_Start_Hour = 8;           // Session Start Hour
input int                  Session_End_Hour = 18;            // Session End Hour

input group "Visual Settings"
input bool                 Show_Range_Lines = true;          // Show Range Lines
input color                Range_Line_Color = clrYellow;     // Range Line Color

input group "EA Settings"
input int                  Magic_Number = 789012;            // Magic Number
input string               Trade_Comment = "Breakout";       // Trade Comment

//--- Global Variables
double range_high = 0;
double range_low = 0;
datetime last_range_calc_time = 0;

CTrade trade;
CPositionInfo position;
CSymbolInfo symbol_info;

//--- Object names
#define OBJ_RANGE_HIGH "Breakout_Range_High"
#define OBJ_RANGE_LOW "Breakout_Range_Low"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate inputs
   if(Range_Lookback_Bars < 2)
   {
      Print("Error: Range lookback must be at least 2 bars");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Lot_Size <= 0)
   {
      Print("Error: Lot size must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Use_Session_Filter && Session_Start_Hour >= Session_End_Hour)
   {
      Print("Error: Session start hour must be before end hour");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- Initialize symbol info
   if(!symbol_info.Name(_Symbol))
   {
      Print("Error initializing symbol info");
      return(INIT_FAILED);
   }
   
   //--- Set trade parameters
   trade.SetExpertMagicNumber(Magic_Number);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);
   
   //--- Calculate initial range
   CalculateRange();
   
   //--- Draw range lines immediately
   if(Show_Range_Lines)
      DrawRangeLines();
   
   //--- Update info comment
   UpdateInfoComment();
   
   Print("Breakout EA initialized successfully");
   Print("Range Lookback: ", Range_Lookback_Bars, " bars");
   Print("Session Filter: ", Use_Session_Filter ? "Enabled" : "Disabled");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Delete range lines
   ObjectDelete(0, OBJ_RANGE_HIGH);
   ObjectDelete(0, OBJ_RANGE_LOW);
   
   //--- Clear comment
   Comment("");
   
   Print("Breakout EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Update range on new bar
   UpdateRange();
   
   //--- Update range lines
   if(Show_Range_Lines)
      DrawRangeLines();
   
   //--- Update info comment
   UpdateInfoComment();
   
   //--- Check if we should trade (session filter)
   if(!IsWithinTradingSession())
      return;
   
   //--- Check spread
   if(!CheckSpread())
      return;
   
   //--- Manage trailing stop for existing positions
   if(Use_Trailing_Stop)
      ManageTrailingStop();
   
   //--- Check for breakout if we don't have a position
   if(!HasPosition())
      CheckBreakout();
}

//+------------------------------------------------------------------+
//| Update information comment on chart                              |
//+------------------------------------------------------------------+
void UpdateInfoComment()
{
   string session_time = "";
   if(Use_Session_Filter)
   {
      string start_str = (Session_Start_Hour < 10 ? "0" : "") + IntegerToString(Session_Start_Hour) + ":00";
      string end_str = (Session_End_Hour < 10 ? "0" : "") + IntegerToString(Session_End_Hour) + ":00";
      session_time = start_str + " - " + end_str;
   }
   else
   {
      session_time = "24/7";
   }
   
   string range_str = "";
   if(range_high > 0 && range_low > 0)
   {
      range_str = DoubleToString(range_high, _Digits) + " - " + DoubleToString(range_low, _Digits);
   }
   else
   {
      range_str = "Calculating...";
   }
   
   string comment_text = "═══════════════════════════════════════\n";
   comment_text += "        BREAKOUT EA\n";
   comment_text += "═══════════════════════════════════════\n";
   comment_text += "Symbol: " + _Symbol + "\n";
   comment_text += "Range: " + range_str + "\n";
   comment_text += "Lookback: " + IntegerToString(Range_Lookback_Bars) + " bars\n";
   comment_text += "───────────────────────────────────────\n";
   comment_text += "Session: " + session_time + "\n";
   comment_text += "═══════════════════════════════════════\n";
   
   Comment(comment_text);
}

//+------------------------------------------------------------------+
//| Calculate range high and low                                    |
//+------------------------------------------------------------------+
void CalculateRange()
{
   if(Range_Lookback_Bars <= 0)
      return;
   
   range_high = 0;
   range_low = DBL_MAX;
   
   for(int i = 1; i <= Range_Lookback_Bars; i++)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      
      if(high > range_high)
         range_high = high;
      
      if(low < range_low)
         range_low = low;
   }
   
   last_range_calc_time = iTime(_Symbol, PERIOD_CURRENT, 0);
}

//+------------------------------------------------------------------+
//| Update range on new bar                                         |
//+------------------------------------------------------------------+
void UpdateRange()
{
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   
   if(current_bar_time != last_range_calc_time)
   {
      CalculateRange();
   }
}

//+------------------------------------------------------------------+
//| Check for breakout conditions                                   |
//+------------------------------------------------------------------+
void CheckBreakout()
{
   if(range_high == 0 || range_low == 0)
      return;
   
   //--- Get current close price
   double close = iClose(_Symbol, PERIOD_CURRENT, 1); // Previous closed bar
   double current_close = iClose(_Symbol, PERIOD_CURRENT, 0); // Current bar
   
   //--- Calculate minimum breakout distance
   double min_distance = Min_Breakout_Distance_Pips * symbol_info.Point() * 10;
   
   //--- Check for bullish breakout (close above range high)
   if(close > range_high + min_distance)
   {
      Print("Bullish breakout detected! Close: ", close, " Range High: ", range_high);
      OpenBuyPosition();
   }
   //--- Check for bearish breakout (close below range low)
   else if(close < range_low - min_distance)
   {
      Print("Bearish breakout detected! Close: ", close, " Range Low: ", range_low);
      OpenSellPosition();
   }
}

//+------------------------------------------------------------------+
//| Open buy position                                                |
//+------------------------------------------------------------------+
void OpenBuyPosition()
{
   double price = symbol_info.Ask();
   double sl = 0;
   double tp = 0;
   
   //--- Calculate stop loss (place below range low)
   if(Stop_Loss_Pips > 0)
      sl = range_low - (10 * symbol_info.Point());
   else
      sl = price - Stop_Loss_Pips * symbol_info.Point() * 10;
   
   //--- Calculate take profit
   if(Take_Profit_Pips > 0)
      tp = price + Take_Profit_Pips * symbol_info.Point() * 10;
   
   //--- Normalize prices
   sl = NormalizeDouble(sl, symbol_info.Digits());
   tp = NormalizeDouble(tp, symbol_info.Digits());
   
   //--- Execute buy order
   if(trade.Buy(Lot_Size, _Symbol, price, sl, tp, Trade_Comment))
   {
      Print("Buy order opened at ", price, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Error opening buy order: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Open sell position                                               |
//+------------------------------------------------------------------+
void OpenSellPosition()
{
   double price = symbol_info.Bid();
   double sl = 0;
   double tp = 0;
   
   //--- Calculate stop loss (place above range high)
   if(Stop_Loss_Pips > 0)
      sl = range_high + (10 * symbol_info.Point());
   else
      sl = price + Stop_Loss_Pips * symbol_info.Point() * 10;
   
   //--- Calculate take profit
   if(Take_Profit_Pips > 0)
      tp = price - Take_Profit_Pips * symbol_info.Point() * 10;
   
   //--- Normalize prices
   sl = NormalizeDouble(sl, symbol_info.Digits());
   tp = NormalizeDouble(tp, symbol_info.Digits());
   
   //--- Execute sell order
   if(trade.Sell(Lot_Size, _Symbol, price, sl, tp, Trade_Comment))
   {
      Print("Sell order opened at ", price, " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Error opening sell order: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Check if there's an open position                               |
//+------------------------------------------------------------------+
bool HasPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == Magic_Number)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable                                   |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double spread = (symbol_info.Ask() - symbol_info.Bid()) / symbol_info.Point();
   
   if(spread > Max_Spread_Pips * 10)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if current time is within trading session                 |
//+------------------------------------------------------------------+
bool IsWithinTradingSession()
{
   if(!Use_Session_Filter)
      return true;
   
   MqlDateTime time_struct;
   TimeCurrent(time_struct);
   
   int current_hour = time_struct.hour;
   
   //--- Simple session check
   if(current_hour >= Session_Start_Hour && current_hour < Session_End_Hour)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Manage trailing stop for open positions                         |
//+------------------------------------------------------------------+
void ManageTrailingStop()
{
   if(Trailing_Stop_Pips <= 0)
      return;
   
   double trailing_stop = Trailing_Stop_Pips * symbol_info.Point() * 10;
   double trailing_step = Trailing_Step_Pips * symbol_info.Point() * 10;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == Magic_Number)
         {
            double current_sl = position.StopLoss();
            double new_sl = 0;
            
            if(position.PositionType() == POSITION_TYPE_BUY)
            {
               new_sl = symbol_info.Bid() - trailing_stop;
               new_sl = NormalizeDouble(new_sl, symbol_info.Digits());
               
               if(new_sl > current_sl && (current_sl == 0 || new_sl - current_sl >= trailing_step))
               {
                  trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                  Print("Trailing stop updated for buy position to ", new_sl);
               }
            }
            else if(position.PositionType() == POSITION_TYPE_SELL)
            {
               new_sl = symbol_info.Ask() + trailing_stop;
               new_sl = NormalizeDouble(new_sl, symbol_info.Digits());
               
               if(new_sl < current_sl || current_sl == 0)
               {
                  if(current_sl == 0 || current_sl - new_sl >= trailing_step)
                  {
                     trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                     Print("Trailing stop updated for sell position to ", new_sl);
                  }
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw range lines on chart                                       |
//+------------------------------------------------------------------+
void DrawRangeLines()
{
   if(range_high == 0 || range_low == 0)
      return;
   
   //--- Draw range high line
   if(ObjectFind(0, OBJ_RANGE_HIGH) < 0)
   {
      ObjectCreate(0, OBJ_RANGE_HIGH, OBJ_HLINE, 0, 0, range_high);
      ObjectSetInteger(0, OBJ_RANGE_HIGH, OBJPROP_COLOR, Range_Line_Color);
      ObjectSetInteger(0, OBJ_RANGE_HIGH, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, OBJ_RANGE_HIGH, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetString(0, OBJ_RANGE_HIGH, OBJPROP_TEXT, "Range High");
   }
   else
   {
      ObjectSetDouble(0, OBJ_RANGE_HIGH, OBJPROP_PRICE, range_high);
   }
   
   //--- Draw range low line
   if(ObjectFind(0, OBJ_RANGE_LOW) < 0)
   {
      ObjectCreate(0, OBJ_RANGE_LOW, OBJ_HLINE, 0, 0, range_low);
      ObjectSetInteger(0, OBJ_RANGE_LOW, OBJPROP_COLOR, Range_Line_Color);
      ObjectSetInteger(0, OBJ_RANGE_LOW, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, OBJ_RANGE_LOW, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetString(0, OBJ_RANGE_LOW, OBJPROP_TEXT, "Range Low");
   }
   else
   {
      ObjectSetDouble(0, OBJ_RANGE_LOW, OBJPROP_PRICE, range_low);
   }
}
//+------------------------------------------------------------------+
