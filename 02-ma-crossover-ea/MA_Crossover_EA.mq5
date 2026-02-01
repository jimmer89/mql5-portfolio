//+------------------------------------------------------------------+
//|                                            MA_Crossover_EA.mq5 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.00"
#property description "Moving Average Crossover EA with comprehensive risk management"

//--- Include standard libraries
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input Parameters
input group "MA Settings"
input int                  Fast_MA_Period = 10;              // Fast MA Period
input int                  Slow_MA_Period = 30;              // Slow MA Period
input ENUM_MA_METHOD       MA_Method = MODE_EMA;             // MA Method
input ENUM_APPLIED_PRICE   Applied_Price = PRICE_CLOSE;      // Applied Price

input group "Trade Settings"
input double               Lot_Size = 0.1;                   // Lot Size
input int                  Stop_Loss_Pips = 50;              // Stop Loss (pips)
input int                  Take_Profit_Pips = 100;           // Take Profit (pips)
input bool                 Use_Trailing_Stop = true;         // Use Trailing Stop
input int                  Trailing_Stop_Pips = 30;          // Trailing Stop (pips)
input int                  Trailing_Step_Pips = 10;          // Trailing Step (pips)

input group "Risk Management"
input double               Max_Spread_Pips = 3.0;            // Max Spread (pips)

input group "EA Settings"
input int                  Magic_Number = 123456;            // Magic Number
input string               Trade_Comment = "MA Cross";       // Trade Comment

//--- Global Variables
int fast_ma_handle;
int slow_ma_handle;
double fast_ma_buffer[];
double slow_ma_buffer[];

CTrade trade;
CPositionInfo position;
CSymbolInfo symbol_info;

//--- Last crossover tracking
int last_signal = 0; // 1 = bullish, -1 = bearish, 0 = none

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate inputs
   if(Fast_MA_Period <= 0 || Slow_MA_Period <= 0)
   {
      Print("Error: MA periods must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Fast_MA_Period >= Slow_MA_Period)
   {
      Print("Error: Fast MA period must be less than Slow MA period");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Lot_Size <= 0)
   {
      Print("Error: Lot size must be greater than 0");
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
   
   //--- Create MA indicator handles
   fast_ma_handle = iMA(_Symbol, PERIOD_CURRENT, Fast_MA_Period, 0, MA_Method, Applied_Price);
   slow_ma_handle = iMA(_Symbol, PERIOD_CURRENT, Slow_MA_Period, 0, MA_Method, Applied_Price);
   
   if(fast_ma_handle == INVALID_HANDLE || slow_ma_handle == INVALID_HANDLE)
   {
      Print("Error creating MA indicator handles");
      return(INIT_FAILED);
   }
   
   //--- Set arrays as series
   ArraySetAsSeries(fast_ma_buffer, true);
   ArraySetAsSeries(slow_ma_buffer, true);
   
   Print("MA Crossover EA initialized successfully");
   Print("Fast MA: ", Fast_MA_Period, " | Slow MA: ", Slow_MA_Period, " | Method: ", EnumToString(MA_Method));
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handles
   if(fast_ma_handle != INVALID_HANDLE)
      IndicatorRelease(fast_ma_handle);
   if(slow_ma_handle != INVALID_HANDLE)
      IndicatorRelease(slow_ma_handle);
   
   Print("MA Crossover EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Copy MA values
   if(CopyBuffer(fast_ma_handle, 0, 0, 3, fast_ma_buffer) < 3 ||
      CopyBuffer(slow_ma_handle, 0, 0, 3, slow_ma_buffer) < 3)
   {
      Print("Error copying MA buffer data");
      return;
   }
   
   //--- Check spread
   if(!CheckSpread())
      return;
   
   //--- Manage trailing stop for existing positions
   if(Use_Trailing_Stop)
      ManageTrailingStop();
   
   //--- Check for crossover signals
   CheckCrossoverSignals();
}

//+------------------------------------------------------------------+
//| Check for MA crossover signals                                  |
//+------------------------------------------------------------------+
void CheckCrossoverSignals()
{
   //--- Get current and previous MA values
   double fast_current = fast_ma_buffer[0];
   double fast_previous = fast_ma_buffer[1];
   double slow_current = slow_ma_buffer[0];
   double slow_previous = slow_ma_buffer[1];
   
   //--- Detect bullish crossover (fast crosses above slow)
   if(fast_previous <= slow_previous && fast_current > slow_current)
   {
      if(last_signal != 1) // New signal
      {
         Print("Bullish crossover detected");
         
         //--- Close any existing sell positions
         ClosePositionsByType(POSITION_TYPE_SELL);
         
         //--- Open buy position if we don't have one
         if(!HasPosition(POSITION_TYPE_BUY))
         {
            OpenBuyPosition();
            last_signal = 1;
         }
      }
   }
   //--- Detect bearish crossover (fast crosses below slow)
   else if(fast_previous >= slow_previous && fast_current < slow_current)
   {
      if(last_signal != -1) // New signal
      {
         Print("Bearish crossover detected");
         
         //--- Close any existing buy positions
         ClosePositionsByType(POSITION_TYPE_BUY);
         
         //--- Open sell position if we don't have one
         if(!HasPosition(POSITION_TYPE_SELL))
         {
            OpenSellPosition();
            last_signal = -1;
         }
      }
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
   
   //--- Calculate stop loss
   if(Stop_Loss_Pips > 0)
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
      Print("Buy order opened successfully at ", price);
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
   
   //--- Calculate stop loss
   if(Stop_Loss_Pips > 0)
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
      Print("Sell order opened successfully at ", price);
   }
   else
   {
      Print("Error opening sell order: ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Check if there's a position of specified type                   |
//+------------------------------------------------------------------+
bool HasPosition(ENUM_POSITION_TYPE pos_type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && 
            position.Magic() == Magic_Number &&
            position.PositionType() == pos_type)
         {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Close positions of specified type                               |
//+------------------------------------------------------------------+
void ClosePositionsByType(ENUM_POSITION_TYPE pos_type)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && 
            position.Magic() == Magic_Number &&
            position.PositionType() == pos_type)
         {
            trade.PositionClose(position.Ticket());
            Print("Closed ", EnumToString(pos_type), " position #", position.Ticket());
         }
      }
   }
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
               //--- Calculate new stop loss for buy position
               new_sl = symbol_info.Bid() - trailing_stop;
               new_sl = NormalizeDouble(new_sl, symbol_info.Digits());
               
               //--- Update if new SL is better and moved enough
               if(new_sl > current_sl && (current_sl == 0 || new_sl - current_sl >= trailing_step))
               {
                  trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                  Print("Trailing stop updated for buy position #", position.Ticket(), " to ", new_sl);
               }
            }
            else if(position.PositionType() == POSITION_TYPE_SELL)
            {
               //--- Calculate new stop loss for sell position
               new_sl = symbol_info.Ask() + trailing_stop;
               new_sl = NormalizeDouble(new_sl, symbol_info.Digits());
               
               //--- Update if new SL is better and moved enough
               if(new_sl < current_sl || current_sl == 0)
               {
                  if(current_sl == 0 || current_sl - new_sl >= trailing_step)
                  {
                     trade.PositionModify(position.Ticket(), new_sl, position.TakeProfit());
                     Print("Trailing stop updated for sell position #", position.Ticket(), " to ", new_sl);
                  }
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+
