//+------------------------------------------------------------------+
//|                                            RSI_Multi_Scanner.mq5 |
//|                                    Copyright 2026, Jaume Sancho  |
//|                    https://github.com/jimmer89/mql5-portfolio    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Jaume Sancho"
#property link      "https://www.mql5.com/en/users/whitechocolate"
#property version   "1.00"
#property description "Scans multiple symbols for RSI overbought/oversold conditions"
#property description "Displays a dashboard with real-time RSI values and alerts"
#property description "Perfect for finding trading opportunities across multiple pairs"
#property indicator_chart_window
#property indicator_plots 0

//--- Input parameters
input group "=== Symbols to Scan ==="
input string   InpSymbols     = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,EURJPY"; // Symbols (comma separated)

input group "=== RSI Settings ==="
input int      InpRSIPeriod   = 14;          // RSI Period
input ENUM_APPLIED_PRICE InpPrice = PRICE_CLOSE; // Applied Price
input int      InpOverbought  = 70;          // Overbought Level
input int      InpOversold    = 30;          // Oversold Level

input group "=== Display Settings ==="
input int      InpXOffset     = 20;          // Panel X Position
input int      InpYOffset     = 30;          // Panel Y Position
input int      InpFontSize    = 10;          // Font Size
input color    InpColorBull   = clrLime;     // Oversold Color (Buy Signal)
input color    InpColorBear   = clrRed;      // Overbought Color (Sell Signal)
input color    InpColorNeutral= clrWhite;    // Neutral Color
input color    InpColorBG     = clrBlack;    // Background Color

input group "=== Alerts ==="
input bool     InpAlertPopup  = true;        // Popup Alert
input bool     InpAlertSound  = true;        // Sound Alert
input bool     InpAlertPush   = false;       // Push Notification

//--- Global variables
string   g_symbols[];
int      g_handles[];
int      g_symbolCount = 0;
datetime g_lastAlert[];
string   g_prefix = "RSIScanner_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Parse symbols
   ParseSymbols(InpSymbols);
   
   if(g_symbolCount == 0)
   {
      Print("Error: No valid symbols found");
      return(INIT_FAILED);
   }
   
   //--- Create RSI handles for each symbol
   ArrayResize(g_handles, g_symbolCount);
   ArrayResize(g_lastAlert, g_symbolCount);
   
   for(int i = 0; i < g_symbolCount; i++)
   {
      g_handles[i] = iRSI(g_symbols[i], PERIOD_CURRENT, InpRSIPeriod, InpPrice);
      if(g_handles[i] == INVALID_HANDLE)
      {
         PrintFormat("Warning: Cannot create RSI handle for %s", g_symbols[i]);
      }
      g_lastAlert[i] = 0;
   }
   
   //--- Create panel background
   CreatePanel();
   
   Print("RSI Multi-Scanner initialized with ", g_symbolCount, " symbols");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release handles
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(g_handles[i] != INVALID_HANDLE)
         IndicatorRelease(g_handles[i]);
   }
   
   //--- Delete objects
   ObjectsDeleteAll(0, g_prefix);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
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
{
   UpdateDashboard();
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Parse comma-separated symbols                                     |
//+------------------------------------------------------------------+
void ParseSymbols(string symbolList)
{
   string temp[];
   int count = StringSplit(symbolList, ',', temp);
   
   g_symbolCount = 0;
   ArrayResize(g_symbols, count);
   
   for(int i = 0; i < count; i++)
   {
      string sym = StringTrimRight(StringTrimLeft(temp[i]));
      
      //--- Check if symbol exists
      if(SymbolSelect(sym, true))
      {
         g_symbols[g_symbolCount] = sym;
         g_symbolCount++;
      }
      else
      {
         PrintFormat("Symbol %s not found, skipping", sym);
      }
   }
   
   ArrayResize(g_symbols, g_symbolCount);
}

//+------------------------------------------------------------------+
//| Create panel background                                           |
//+------------------------------------------------------------------+
void CreatePanel()
{
   int panelHeight = 25 + (g_symbolCount * 20) + 10;
   int panelWidth = 200;
   
   //--- Background
   string bgName = g_prefix + "BG";
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, InpXOffset);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, InpYOffset);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, InpColorBG);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);
   
   //--- Title
   string titleName = g_prefix + "Title";
   ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, InpXOffset + 10);
   ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, InpYOffset + 5);
   ObjectSetString(0, titleName, OBJPROP_TEXT, "RSI Scanner (" + IntegerToString(InpRSIPeriod) + ")");
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, InpFontSize + 1);
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   
   //--- Symbol labels
   for(int i = 0; i < g_symbolCount; i++)
   {
      int yPos = InpYOffset + 25 + (i * 20);
      
      //--- Symbol name
      string symName = g_prefix + "Sym_" + IntegerToString(i);
      ObjectCreate(0, symName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, symName, OBJPROP_XDISTANCE, InpXOffset + 10);
      ObjectSetInteger(0, symName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, symName, OBJPROP_TEXT, g_symbols[i]);
      ObjectSetInteger(0, symName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, symName, OBJPROP_COLOR, InpColorNeutral);
      ObjectSetInteger(0, symName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      
      //--- RSI value
      string valName = g_prefix + "Val_" + IntegerToString(i);
      ObjectCreate(0, valName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, valName, OBJPROP_XDISTANCE, InpXOffset + 120);
      ObjectSetInteger(0, valName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, valName, OBJPROP_TEXT, "---");
      ObjectSetInteger(0, valName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, valName, OBJPROP_COLOR, InpColorNeutral);
      ObjectSetInteger(0, valName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      
      //--- Signal
      string sigName = g_prefix + "Sig_" + IntegerToString(i);
      ObjectCreate(0, sigName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sigName, OBJPROP_XDISTANCE, InpXOffset + 165);
      ObjectSetInteger(0, sigName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, sigName, OBJPROP_TEXT, "");
      ObjectSetInteger(0, sigName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, sigName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   }
}

//+------------------------------------------------------------------+
//| Update dashboard values                                           |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   double rsiBuffer[1];
   
   for(int i = 0; i < g_symbolCount; i++)
   {
      if(g_handles[i] == INVALID_HANDLE)
         continue;
      
      //--- Get RSI value
      if(CopyBuffer(g_handles[i], 0, 0, 1, rsiBuffer) <= 0)
         continue;
      
      double rsi = rsiBuffer[0];
      string valName = g_prefix + "Val_" + IntegerToString(i);
      string sigName = g_prefix + "Sig_" + IntegerToString(i);
      
      //--- Update value
      ObjectSetString(0, valName, OBJPROP_TEXT, DoubleToString(rsi, 1));
      
      //--- Determine signal and color
      color textColor = InpColorNeutral;
      string signal = "";
      
      if(rsi >= InpOverbought)
      {
         textColor = InpColorBear;
         signal = "SELL";
         CheckAlert(i, g_symbols[i], "OVERBOUGHT", rsi);
      }
      else if(rsi <= InpOversold)
      {
         textColor = InpColorBull;
         signal = "BUY";
         CheckAlert(i, g_symbols[i], "OVERSOLD", rsi);
      }
      
      ObjectSetInteger(0, valName, OBJPROP_COLOR, textColor);
      ObjectSetString(0, sigName, OBJPROP_TEXT, signal);
      ObjectSetInteger(0, sigName, OBJPROP_COLOR, textColor);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Check and send alerts                                             |
//+------------------------------------------------------------------+
void CheckAlert(int index, string symbol, string condition, double rsi)
{
   //--- Prevent alert spam (1 alert per symbol per bar)
   datetime currentBar = iTime(symbol, PERIOD_CURRENT, 0);
   if(g_lastAlert[index] == currentBar)
      return;
   
   g_lastAlert[index] = currentBar;
   
   string message = StringFormat("RSI Scanner: %s is %s (RSI=%.1f)", symbol, condition, rsi);
   
   if(InpAlertPopup)
      Alert(message);
   
   if(InpAlertSound)
      PlaySound("alert.wav");
   
   if(InpAlertPush)
      SendNotification(message);
}

//+------------------------------------------------------------------+
//| ChartEvent function                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- Handle chart resize
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      ChartRedraw();
   }
}
//+------------------------------------------------------------------+
