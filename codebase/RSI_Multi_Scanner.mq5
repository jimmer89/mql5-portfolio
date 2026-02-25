//+------------------------------------------------------------------+
//|                                            RSI_Multi_Scanner.mq5 |
//|                                    Copyright 2026, Jaume Sancho  |
//|                    https://www.mql5.com/en/users/whitechocolate  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Jaume Sancho"
#property link      "https://www.mql5.com/en/users/whitechocolate"
#property version   "1.10"
#property description "Scans multiple symbols for RSI overbought/oversold conditions"
#property description "Displays a dashboard with real-time RSI values and alerts"
#property description "Perfect for finding trading opportunities across multiple pairs"
#property indicator_chart_window
#property indicator_plots 0

//+------------------------------------------------------------------+
//| Input parameters                                                  |
//+------------------------------------------------------------------+
input group "=== Symbols to Scan ==="
input string   InpSymbols     = "EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,EURJPY"; // Symbols (comma separated)

input group "=== RSI Settings ==="
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_CURRENT; // Timeframe
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
input color    InpColorBG     = C'20,20,20'; // Background Color

input group "=== Alerts ==="
input bool     InpAlertPopup  = true;        // Popup Alert
input bool     InpAlertSound  = true;        // Sound Alert
input bool     InpAlertPush   = false;       // Push Notification

//+------------------------------------------------------------------+
//| Global variables                                                  |
//+------------------------------------------------------------------+
string   g_symbols[];
int      g_handles[];
int      g_symbolCount = 0;
datetime g_lastAlert[];
string   g_prefix = "RSIScanner_";
ENUM_TIMEFRAMES g_timeframe;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- set timeframe
   g_timeframe = (InpTimeframe == PERIOD_CURRENT) ? Period() : InpTimeframe;

//--- parse symbols from input string
   ParseSymbols(InpSymbols);

   if(g_symbolCount == 0)
     {
      Print("Error: No valid symbols found");
      return(INIT_FAILED);
     }

//--- create RSI handles for each symbol
   ArrayResize(g_handles, g_symbolCount);
   ArrayResize(g_lastAlert, g_symbolCount);

   for(int i = 0; i < g_symbolCount; i++)
     {
      g_handles[i] = iRSI(g_symbols[i], g_timeframe, InpRSIPeriod, InpPrice);
      if(g_handles[i] == INVALID_HANDLE)
        {
         PrintFormat("Warning: Cannot create RSI handle for %s", g_symbols[i]);
        }
      g_lastAlert[i] = 0;
     }

//--- create panel background and labels
   CreatePanel();

   Print("RSI Multi-Scanner initialized with ", g_symbolCount, " symbols on ", TimeframeToString(g_timeframe));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- release indicator handles
   for(int i = 0; i < g_symbolCount; i++)
     {
      if(g_handles[i] != INVALID_HANDLE)
         IndicatorRelease(g_handles[i]);
     }

//--- delete all graphical objects
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
//--- update dashboard on every tick
   UpdateDashboard();
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Convert timeframe enum to readable string                         |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN";
      default:         return "M" + IntegerToString(tf);
     }
  }

//+------------------------------------------------------------------+
//| Parse comma-separated symbols string                              |
//+------------------------------------------------------------------+
void ParseSymbols(string symbolList)
  {
   string temp[];
   int count = StringSplit(symbolList, ',', temp);

   g_symbolCount = 0;
   ArrayResize(g_symbols, count);

//--- validate each symbol
   for(int i = 0; i < count; i++)
     {
      string sym = temp[i];
      StringTrimRight(sym);
      StringTrimLeft(sym);

      //--- check if symbol exists in Market Watch
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
//| Create panel background and labels                                |
//+------------------------------------------------------------------+
void CreatePanel()
  {
   int panelHeight = 30 + (g_symbolCount * 22) + 10;
   int panelWidth = 250;

//--- create background rectangle
   string bgName = g_prefix + "BG";
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, InpXOffset);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, InpYOffset);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, panelWidth);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, panelHeight);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, InpColorBG);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);

//--- create title label with timeframe info
   string titleName = g_prefix + "Title";
   string titleText = "RSI Scanner (" + IntegerToString(InpRSIPeriod) + ") - " + TimeframeToString(g_timeframe);
   ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, InpXOffset + 10);
   ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, InpYOffset + 7);
   ObjectSetString(0, titleName, OBJPROP_TEXT, titleText);
   ObjectSetString(0, titleName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, InpFontSize + 1);
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);

//--- create labels for each symbol
   for(int i = 0; i < g_symbolCount; i++)
     {
      int yPos = InpYOffset + 30 + (i * 22);

      //--- symbol name label
      string symName = g_prefix + "Sym_" + IntegerToString(i);
      ObjectCreate(0, symName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, symName, OBJPROP_XDISTANCE, InpXOffset + 10);
      ObjectSetInteger(0, symName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, symName, OBJPROP_TEXT, g_symbols[i]);
      ObjectSetString(0, symName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, symName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, symName, OBJPROP_COLOR, InpColorNeutral);
      ObjectSetInteger(0, symName, OBJPROP_CORNER, CORNER_LEFT_UPPER);

      //--- RSI value label
      string valName = g_prefix + "Val_" + IntegerToString(i);
      ObjectCreate(0, valName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, valName, OBJPROP_XDISTANCE, InpXOffset + 100);
      ObjectSetInteger(0, valName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, valName, OBJPROP_TEXT, "---");
      ObjectSetString(0, valName, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, valName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, valName, OBJPROP_COLOR, InpColorNeutral);
      ObjectSetInteger(0, valName, OBJPROP_CORNER, CORNER_LEFT_UPPER);

      //--- signal label (BUY/SELL)
      string sigName = g_prefix + "Sig_" + IntegerToString(i);
      ObjectCreate(0, sigName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, sigName, OBJPROP_XDISTANCE, InpXOffset + 160);
      ObjectSetInteger(0, sigName, OBJPROP_YDISTANCE, yPos);
      ObjectSetString(0, sigName, OBJPROP_TEXT, "");
      ObjectSetString(0, sigName, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, sigName, OBJPROP_FONTSIZE, InpFontSize);
      ObjectSetInteger(0, sigName, OBJPROP_COLOR, InpColorNeutral);
      ObjectSetInteger(0, sigName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
     }
  }

//+------------------------------------------------------------------+
//| Update dashboard with current RSI values                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   double rsiBuffer[1];

   for(int i = 0; i < g_symbolCount; i++)
     {
      if(g_handles[i] == INVALID_HANDLE)
         continue;

      //--- get current RSI value
      if(CopyBuffer(g_handles[i], 0, 0, 1, rsiBuffer) <= 0)
         continue;

      double rsi = rsiBuffer[0];
      string valName = g_prefix + "Val_" + IntegerToString(i);
      string sigName = g_prefix + "Sig_" + IntegerToString(i);

      //--- update RSI value display
      ObjectSetString(0, valName, OBJPROP_TEXT, DoubleToString(rsi, 1));

      //--- determine signal and color based on RSI level
      color textColor = InpColorNeutral;
      string signal = "";

      if(rsi >= InpOverbought)
        {
         textColor = InpColorBear;
         signal = "● SELL";
         CheckAlert(i, g_symbols[i], "OVERBOUGHT", rsi);
        }
      else if(rsi <= InpOversold)
        {
         textColor = InpColorBull;
         signal = "● BUY";
         CheckAlert(i, g_symbols[i], "OVERSOLD", rsi);
        }

      ObjectSetInteger(0, valName, OBJPROP_COLOR, textColor);
      ObjectSetString(0, sigName, OBJPROP_TEXT, signal);
      ObjectSetInteger(0, sigName, OBJPROP_COLOR, textColor);
     }

//--- refresh chart
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Check and send alerts (prevents spam)                             |
//+------------------------------------------------------------------+
void CheckAlert(int index, string symbol, string condition, double rsi)
  {
//--- prevent alert spam (one alert per symbol per bar)
   datetime currentBar = iTime(symbol, g_timeframe, 0);
   if(g_lastAlert[index] == currentBar)
      return;

   g_lastAlert[index] = currentBar;

//--- build alert message
   string message = StringFormat("RSI Scanner [%s]: %s is %s (RSI=%.1f)",
                                 TimeframeToString(g_timeframe), symbol, condition, rsi);

//--- send alerts based on user preferences
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
//--- handle chart resize events
   if(id == CHARTEVENT_CHART_CHANGE)
     {
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
