//+------------------------------------------------------------------+
//|                                              Simple_MA_EA.mq4 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.00"
#property strict

//--- Input parameters
input int      MA_Period = 20;           // MA Period
input double   LotSize = 0.1;            // Lot Size
input int      StopLoss = 50;            // Stop Loss (pips)
input int      TakeProfit = 100;         // Take Profit (pips)
input int      MagicNumber = 12345;      // Magic Number

//--- Global variables
double ma_current, ma_previous;
int ticket = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   Print("Simple MA EA initialized");
   return(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   Print("Simple MA EA deinitialized");
   return(0);
}

//+------------------------------------------------------------------+
//| Expert start function                                            |
//+------------------------------------------------------------------+
int start()
{
   //--- Get MA values
   ma_current = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMA, PRICE_CLOSE, 0);
   ma_previous = iMA(Symbol(), Period(), MA_Period, 0, MODE_SMA, PRICE_CLOSE, 1);
   
   //--- Check for open position
   bool hasPosition = false;
   int posType = -1;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            hasPosition = true;
            posType = OrderType();
            ticket = OrderTicket();
            break;
         }
      }
   }
   
   //--- Trading logic: Buy when price crosses above MA, sell when crosses below
   double currentPrice = Close[0];
   double previousPrice = Close[1];
   
   //--- Buy signal
   if(previousPrice <= ma_previous && currentPrice > ma_current)
   {
      //--- Close sell position if exists
      if(hasPosition && posType == OP_SELL)
      {
         if(!OrderClose(ticket, OrderLots(), Bid, 3, clrRed))
         {
            Print("Error closing sell order: ", GetLastError());
         }
         hasPosition = false;
      }
      
      //--- Open buy position if we don't have one
      if(!hasPosition)
      {
         double sl = 0;
         double tp = 0;
         
         if(StopLoss > 0)
            sl = Bid - StopLoss * Point * 10;
         
         if(TakeProfit > 0)
            tp = Bid + TakeProfit * Point * 10;
         
         ticket = OrderSend(Symbol(), OP_BUY, LotSize, Ask, 3, sl, tp, "MA Buy", MagicNumber, 0, clrGreen);
         
         if(ticket < 0)
         {
            Print("Error opening buy order: ", GetLastError());
         }
         else
         {
            Print("Buy order opened at ", Ask);
         }
      }
   }
   //--- Sell signal
   else if(previousPrice >= ma_previous && currentPrice < ma_current)
   {
      //--- Close buy position if exists
      if(hasPosition && posType == OP_BUY)
      {
         if(!OrderClose(ticket, OrderLots(), Ask, 3, clrBlue))
         {
            Print("Error closing buy order: ", GetLastError());
         }
         hasPosition = false;
      }
      
      //--- Open sell position if we don't have one
      if(!hasPosition)
      {
         double sl = 0;
         double tp = 0;
         
         if(StopLoss > 0)
            sl = Ask + StopLoss * Point * 10;
         
         if(TakeProfit > 0)
            tp = Ask - TakeProfit * Point * 10;
         
         ticket = OrderSend(Symbol(), OP_SELL, LotSize, Bid, 3, sl, tp, "MA Sell", MagicNumber, 0, clrRed);
         
         if(ticket < 0)
         {
            Print("Error opening sell order: ", GetLastError());
         }
         else
         {
            Print("Sell order opened at ", Bid);
         }
      }
   }
   
   return(0);
}
//+------------------------------------------------------------------+
