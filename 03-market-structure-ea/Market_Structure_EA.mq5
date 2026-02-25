//+------------------------------------------------------------------+
//|                                       Market_Structure_EA.mq5    |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "2.10"
#property description "Market Structure - Swing Points, HH/HL/LH/LL, BOS, CHoCH"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Input Parameters
input int     Swing_Lookback = 5;           // Swing Lookback (bars each side)
input int     Max_History = 500;            // Max bars to analyze
input bool    Show_HH_HL = true;            // Show HH / HL
input bool    Show_LH_LL = true;            // Show LH / LL
input bool    Show_BOS = true;              // Show Break of Structure
input bool    Show_CHoCH = true;            // Show Change of Character
input bool    Draw_Lines = true;            // Draw structure lines
input color   HH_Color = clrLime;           // HH Color
input color   HL_Color = clrDodgerBlue;     // HL Color
input color   LH_Color = clrOrange;         // LH Color
input color   LL_Color = clrRed;            // LL Color
input color   BOS_Color = clrDeepSkyBlue;   // BOS Color
input color   CHoCH_Color = clrMagenta;     // CHoCH Color
input int     Line_Width = 1;               // Line Width
input int     Font_Size = 9;                // Label Font Size
input bool    Enable_Alerts = false;        // Enable Alerts

//--- Swing data stored in parallel arrays (no struct with strings)
datetime g_time[];
double   g_price[];
bool     g_is_high[];
int      g_label[];    // 0=unclassified, 1=HH, 2=HL, 3=LH, 4=LL
int      g_count = 0;

datetime g_last_bar_time = 0;
string   g_prefix = "MS_";

#define LBL_NONE  0
#define LBL_HH    1
#define LBL_HL    2
#define LBL_LH    3
#define LBL_LL    4

//+------------------------------------------------------------------+
int OnInit()
{
   if(Swing_Lookback < 2)
   {
      Print("Error: Swing Lookback must be >= 2");
      return(INIT_PARAMETERS_INCORRECT);
   }

   g_count = 0;
   g_last_bar_time = 0;

   Print("[MS] Market Structure v2.10 initialized | Lookback=", Swing_Lookback);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteAllObjects();
   Print("[MS] Deinitialized");
}

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
   //--- Index 0 = oldest, rates_total-1 = current
   ArraySetAsSeries(high, false);
   ArraySetAsSeries(low, false);
   ArraySetAsSeries(time, false);

   int min_bars = Swing_Lookback * 2 + 1;
   if(rates_total < min_bars)
      return(0);

   //--- Only recalculate on new bar
   if(time[rates_total - 1] == g_last_bar_time && prev_calculated > 0)
      return(rates_total);
   g_last_bar_time = time[rates_total - 1];

   //--- Full recalculation
   if(prev_calculated == 0)
   {
      DeleteAllObjects();
      g_count = 0;

      int start_bar = Swing_Lookback;
      if(rates_total - Max_History > start_bar)
         start_bar = rates_total - Max_History;

      int end_bar = rates_total - 1 - Swing_Lookback;

      Print("[MS] Recalc: bars=", rates_total, " scan ", start_bar, " to ", end_bar);

      //--- Find swing points
      for(int i = start_bar; i <= end_bar; i++)
      {
         bool is_sh = true;
         bool is_sl = true;
         double h_center = high[i];
         double l_center = low[i];

         for(int j = 1; j <= Swing_Lookback; j++)
         {
            if(high[i - j] >= h_center || high[i + j] >= h_center)
               is_sh = false;
            if(low[i - j] <= l_center || low[i + j] <= l_center)
               is_sl = false;
         }

         if(is_sh)
            AddSwing(time[i], high[i], true);
         if(is_sl)
            AddSwing(time[i], low[i], false);
      }

      Print("[MS] Found ", g_count, " swing points");

      //--- Classify
      ClassifySwings();

      //--- Draw
      DrawAll();

      Print("[MS] Done. Objects: ", ObjectsTotal(0, 0, -1));
   }
   else
   {
      //--- Incremental: check newly confirmed bar
      int check = rates_total - 1 - Swing_Lookback;
      if(check < Swing_Lookback) return(rates_total);

      bool new_swing = false;
      double h_center = high[check];
      double l_center = low[check];
      bool is_sh = true;
      bool is_sl = true;

      for(int j = 1; j <= Swing_Lookback; j++)
      {
         if(high[check - j] >= h_center || high[check + j] >= h_center)
            is_sh = false;
         if(low[check - j] <= l_center || low[check + j] <= l_center)
            is_sl = false;
      }

      if(is_sh) { AddSwing(time[check], high[check], true); new_swing = true; }
      if(is_sl) { AddSwing(time[check], low[check], false); new_swing = true; }

      if(new_swing)
      {
         ClassifySwings();
         DrawAll();
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
void AddSwing(datetime t, double price, bool is_high)
{
   g_count++;
   ArrayResize(g_time, g_count);
   ArrayResize(g_price, g_count);
   ArrayResize(g_is_high, g_count);
   ArrayResize(g_label, g_count);

   g_time[g_count - 1] = t;
   g_price[g_count - 1] = price;
   g_is_high[g_count - 1] = is_high;
   g_label[g_count - 1] = LBL_NONE;
}

//+------------------------------------------------------------------+
void ClassifySwings()
{
   if(g_count < 2) return;

   double prev_high = 0;
   double prev_low = 0;
   bool has_prev_high = false;
   bool has_prev_low = false;

   for(int i = 0; i < g_count; i++)
   {
      if(g_is_high[i])
      {
         if(!has_prev_high)
         {
            g_label[i] = LBL_NONE;  // first, no comparison
            has_prev_high = true;
         }
         else
         {
            g_label[i] = (g_price[i] > prev_high) ? LBL_HH : LBL_LH;
         }
         prev_high = g_price[i];
      }
      else
      {
         if(!has_prev_low)
         {
            g_label[i] = LBL_NONE;
            has_prev_low = true;
         }
         else
         {
            g_label[i] = (g_price[i] > prev_low) ? LBL_HL : LBL_LL;
         }
         prev_low = g_price[i];
      }
   }
}

//+------------------------------------------------------------------+
void DrawAll()
{
   DeleteAllObjects();

   string trend = "NONE";

   for(int i = 0; i < g_count; i++)
   {
      int lbl = g_label[i];
      if(lbl == LBL_NONE) continue;

      //--- Filter
      if((lbl == LBL_HH || lbl == LBL_HL) && !Show_HH_HL) continue;
      if((lbl == LBL_LH || lbl == LBL_LL) && !Show_LH_LL) continue;

      //--- Label text and color
      string txt = "";
      color clr = clrWhite;

      switch(lbl)
      {
         case LBL_HH: txt = "HH"; clr = HH_Color; break;
         case LBL_HL: txt = "HL"; clr = HL_Color; break;
         case LBL_LH: txt = "LH"; clr = LH_Color; break;
         case LBL_LL: txt = "LL"; clr = LL_Color; break;
      }

      //--- Draw text on chart
      string obj_name = g_prefix + "L" + IntegerToString(i);
      if(ObjectCreate(0, obj_name, OBJ_TEXT, 0, g_time[i], g_price[i]))
      {
         ObjectSetString(0, obj_name, OBJPROP_TEXT, txt);
         ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, Font_Size);
         ObjectSetString(0, obj_name, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR,
                          g_is_high[i] ? ANCHOR_LOWER : ANCHOR_UPPER);
      }

      //--- Structure line to previous same-type swing
      if(Draw_Lines)
      {
         for(int j = i - 1; j >= 0; j--)
         {
            if(g_is_high[j] == g_is_high[i] && g_label[j] != LBL_NONE)
            {
               string ln = g_prefix + "SL" + IntegerToString(i);
               if(ObjectCreate(0, ln, OBJ_TREND, 0,
                              g_time[j], g_price[j],
                              g_time[i], g_price[i]))
               {
                  ObjectSetInteger(0, ln, OBJPROP_COLOR, clr);
                  ObjectSetInteger(0, ln, OBJPROP_WIDTH, Line_Width);
                  ObjectSetInteger(0, ln, OBJPROP_STYLE, STYLE_DOT);
                  ObjectSetInteger(0, ln, OBJPROP_RAY_RIGHT, false);
                  ObjectSetInteger(0, ln, OBJPROP_BACK, true);
               }
               break;
            }
         }
      }

      //--- BOS / CHoCH detection
      if(lbl == LBL_HH || lbl == LBL_HL)
      {
         if(trend == "BEAR" && Show_CHoCH)
            DrawBOSLine(i, "CHoCH", CHoCH_Color);
         else if(trend == "BULL" && lbl == LBL_HH && Show_BOS)
            DrawBOSLine(i, "BOS", BOS_Color);
         trend = "BULL";
      }
      else if(lbl == LBL_LH || lbl == LBL_LL)
      {
         if(trend == "BULL" && Show_CHoCH)
            DrawBOSLine(i, "CHoCH", CHoCH_Color);
         else if(trend == "BEAR" && lbl == LBL_LL && Show_BOS)
            DrawBOSLine(i, "BOS", BOS_Color);
         trend = "BEAR";
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
void DrawBOSLine(int idx, string bos_txt, color clr)
{
   //--- Find previous same-type swing
   int prev = -1;
   for(int j = idx - 1; j >= 0; j--)
   {
      if(g_is_high[j] == g_is_high[idx])
      {
         prev = j;
         break;
      }
   }
   if(prev < 0) return;

   double level = g_price[prev];

   string name = g_prefix + "B" + IntegerToString(idx);
   if(ObjectCreate(0, name, OBJ_TREND, 0,
                   g_time[prev], level,
                   g_time[idx], level))
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, Line_Width);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASH);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
   }

   //--- Label at midpoint
   string tname = g_prefix + "BT" + IntegerToString(idx);
   datetime mid = (datetime)(((long)g_time[prev] + (long)g_time[idx]) / 2);
   if(ObjectCreate(0, tname, OBJ_TEXT, 0, mid, level))
   {
      ObjectSetString(0, tname, OBJPROP_TEXT, " " + bos_txt);
      ObjectSetInteger(0, tname, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, tname, OBJPROP_FONTSIZE, Font_Size - 1);
      ObjectSetString(0, tname, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, tname, OBJPROP_ANCHOR, ANCHOR_LOWER);
   }
}

//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, g_prefix) == 0)
         ObjectDelete(0, name);
   }
}
//+------------------------------------------------------------------+
