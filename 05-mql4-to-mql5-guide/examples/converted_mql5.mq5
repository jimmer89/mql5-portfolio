//+------------------------------------------------------------------+
//|                                              Simple_MA_EA.mq5 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.00"
#property description "Simple MA crossover EA - MQL5 version"

//--- Include standard trade library
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Input parameters
input int      MA_Period = 20;           // MA Period
input double   LotSize = 0.1;            // Lot Size
input int      StopLoss = 50;            // Stop Loss (pips)
input int      TakeProfit = 100;         // Take Profit (pips)
input int      MagicNumber = 12345;      // Magic Number

//--- Global variables
int ma_handle;
double ma_buffer[];

//--- Trade objects
CTrade trade;
CPositionInfo position;
CSymbolInfo symbol_info;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Create MA indicator handle
   ma_handle = iMA(_Symbol, _Period, MA_Period, 0, MODE_SMA, PRICE_CLOSE);
   
   if(ma_handle == INVALID_HANDLE)
   {
      Print("Error creating MA indicator handle");
      return(INIT_FAILED);
   }
   
   //--- Set array as series
   ArraySetAsSeries(ma_buffer, true);
   
   //--- Initialize symbol info
   if(!symbol_info.Name(_Symbol))
   {
      Print("Error initializing symbol info");
      return(INIT_FAILED);
   }
   
   //--- Set trade parameters
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   
   Print("Simple MA EA initialized (MQL5)");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handle
   if(ma_handle != INVALID_HANDLE)
      IndicatorRelease(ma_handle);
   
   Print("Simple MA EA deinitialized (MQL5). Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Copy MA values (get last 2 values)
   if(CopyBuffer(ma_handle, 0, 0, 2, ma_buffer) < 2)
   {
      Print("Error copying MA buffer");
      return;
   }
   
   double ma_current = ma_buffer[0];
   double ma_previous = ma_buffer[1];
   
   //--- Get current and previous close prices
   double currentPrice = iClose(_Symbol, _Period, 0);
   double previousPrice = iClose(_Symbol, _Period, 1);
   
   //--- Check for open position
   bool hasPosition = false;
   ENUM_POSITION_TYPE posType;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == MagicNumber)
         {
            hasPosition = true;
            posType = position.PositionType();
            break;
         }
      }
   }
   
   //--- Buy signal: Price crosses above MA
   if(previousPrice <= ma_previous && currentPrice > ma_current)
   {
      //--- Close sell position if exists
      if(hasPosition && posType == POSITION_TYPE_SELL)
      {
         if(!trade.PositionClose(position.Ticket()))
         {
            Print("Error closing sell position: ", trade.ResultRetcodeDescription());
         }
         hasPosition = false;
      }
      
      //--- Open buy position if we don't have one
      if(!hasPosition)
      {
         double sl = 0;
         double tp = 0;
         double price = symbol_info.Ask();
         
         if(StopLoss > 0)
            sl = price - StopLoss * symbol_info.Point() * 10;
         
         if(TakeProfit > 0)
            tp = price + TakeProfit * symbol_info.Point() * 10;
         
         //--- Normalize prices
         sl = NormalizeDouble(sl, symbol_info.Digits());
         tp = NormalizeDouble(tp, symbol_info.Digits());
         
         if(trade.Buy(LotSize, _Symbol, price, sl, tp, "MA Buy"))
         {
            Print("Buy order opened at ", price);
         }
         else
         {
            Print("Error opening buy order: ", trade.ResultRetcodeDescription());
         }
      }
   }
   //--- Sell signal: Price crosses below MA
   else if(previousPrice >= ma_previous && currentPrice < ma_current)
   {
      //--- Close buy position if exists
      if(hasPosition && posType == POSITION_TYPE_BUY)
      {
         if(!trade.PositionClose(position.Ticket()))
         {
            Print("Error closing buy position: ", trade.ResultRetcodeDescription());
         }
         hasPosition = false;
      }
      
      //--- Open sell position if we don't have one
      if(!hasPosition)
      {
         double sl = 0;
         double tp = 0;
         double price = symbol_info.Bid();
         
         if(StopLoss > 0)
            sl = price + StopLoss * symbol_info.Point() * 10;
         
         if(TakeProfit > 0)
            tp = price - TakeProfit * symbol_info.Point() * 10;
         
         //--- Normalize prices
         sl = NormalizeDouble(sl, symbol_info.Digits());
         tp = NormalizeDouble(tp, symbol_info.Digits());
         
         if(trade.Sell(LotSize, _Symbol, price, sl, tp, "MA Sell"))
         {
            Print("Sell order opened at ", price);
         }
         else
         {
            Print("Error opening sell order: ", trade.ResultRetcodeDescription());
         }
      }
   }
}
//+------------------------------------------------------------------+
