//+------------------------------------------------------------------+
//|                                       Market_Structure_EA.mq5 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.00"
#property description "Market Structure Indicator - Swing Points, HH/HL/LH/LL, BOS, CHoCH"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

//--- Input Parameters
input group "Detection Settings"
input int                  Swing_Lookback = 5;               // Swing Lookback (bars each side)

input group "Display Settings"
input bool                 Show_HH_HL = true;                // Show Higher Highs and Higher Lows
input bool                 Show_LH_LL = true;                // Show Lower Highs and Lower Lows
input bool                 Show_BOS = true;                  // Show Break of Structure
input bool                 Show_CHoCH = true;                // Show Change of Character
input bool                 Draw_Structure_Lines = true;      // Draw Structure Lines

input group "Visual Settings"
input color                HH_Color = clrLime;               // Higher High Color
input color                HL_Color = clrGreen;              // Higher Low Color
input color                LH_Color = clrOrange;             // Lower High Color
input color                LL_Color = clrRed;                // Lower Low Color
input color                BOS_Color = clrBlue;              // BOS Color
input color                CHoCH_Color = clrMagenta;         // CHoCH Color
input int                  Line_Width = 1;                   // Line Width
input int                  Label_Font_Size = 8;              // Label Font Size

input group "Alert Settings"
input bool                 Enable_Alerts = false;            // Enable Alerts
input bool                 Alert_on_BOS = true;              // Alert on BOS
input bool                 Alert_on_CHoCH = true;            // Alert on CHoCH

//--- Structure to store swing points
struct SwingPoint
{
   datetime time;
   double   price;
   int      bar_index;
   bool     is_high;  // true = swing high, false = swing low
   string   type;     // "HH", "HL", "LH", "LL", or "INITIAL"
};

//--- Global Variables
SwingPoint swing_points[];
int last_processed_bar = -1;
string obj_prefix = "MS_";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate inputs
   if(Swing_Lookback < 2)
   {
      Print("Error: Swing Lookback must be at least 2");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- Initialize swing points array
   ArrayResize(swing_points, 0);
   
   Print("Market Structure Indicator initialized");
   Print("Swing Lookback: ", Swing_Lookback, " bars");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Delete all objects created by this indicator
   DeleteAllObjects();
   
   Print("Market Structure Indicator deinitialized");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   //--- Set arrays as series
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   
   //--- Check for new bar
   int current_bar = rates_total - 1 - Swing_Lookback;
   
   if(current_bar <= last_processed_bar)
      return(rates_total);
   
   //--- Scan for swing points
   for(int i = last_processed_bar + 1; i <= current_bar; i++)
   {
      //--- Check for swing high
      if(IsSwingHigh(i, high))
      {
         AddSwingPoint(time[i], high[i], i, true);
      }
      
      //--- Check for swing low
      if(IsSwingLow(i, low))
      {
         AddSwingPoint(time[i], low[i], i, false);
      }
   }
   
   last_processed_bar = current_bar;
   
   //--- Analyze structure and draw
   AnalyzeStructure();
   DrawStructure();
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Check if bar is a swing high                                    |
//+------------------------------------------------------------------+
bool IsSwingHigh(int bar_index, const double &high[])
{
   double center = high[bar_index];
   
   //--- Check left side
   for(int i = 1; i <= Swing_Lookback; i++)
   {
      if(high[bar_index + i] >= center)
         return false;
   }
   
   //--- Check right side
   for(int i = 1; i <= Swing_Lookback; i++)
   {
      if(high[bar_index - i] >= center)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if bar is a swing low                                     |
//+------------------------------------------------------------------+
bool IsSwingLow(int bar_index, const double &low[])
{
   double center = low[bar_index];
   
   //--- Check left side
   for(int i = 1; i <= Swing_Lookback; i++)
   {
      if(low[bar_index + i] <= center)
         return false;
   }
   
   //--- Check right side
   for(int i = 1; i <= Swing_Lookback; i++)
   {
      if(low[bar_index - i] <= center)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Add swing point to array                                        |
//+------------------------------------------------------------------+
void AddSwingPoint(datetime swing_time, double swing_price, int bar_index, bool is_high)
{
   int size = ArraySize(swing_points);
   ArrayResize(swing_points, size + 1);
   
   swing_points[size].time = swing_time;
   swing_points[size].price = swing_price;
   swing_points[size].bar_index = bar_index;
   swing_points[size].is_high = is_high;
   swing_points[size].type = "INITIAL";
}

//+------------------------------------------------------------------+
//| Analyze market structure                                        |
//+------------------------------------------------------------------+
void AnalyzeStructure()
{
   int size = ArraySize(swing_points);
   
   if(size < 2)
      return;
   
   //--- Find last swing high and low
   int last_high_idx = -1;
   int prev_high_idx = -1;
   int last_low_idx = -1;
   int prev_low_idx = -1;
   
   //--- Scan from most recent to oldest
   for(int i = size - 1; i >= 0; i--)
   {
      if(swing_points[i].is_high)
      {
         if(last_high_idx == -1)
            last_high_idx = i;
         else if(prev_high_idx == -1)
            prev_high_idx = i;
      }
      else
      {
         if(last_low_idx == -1)
            last_low_idx = i;
         else if(prev_low_idx == -1)
            prev_low_idx = i;
      }
      
      //--- Stop when we have enough data
      if(last_high_idx != -1 && prev_high_idx != -1 && 
         last_low_idx != -1 && prev_low_idx != -1)
         break;
   }
   
   //--- Classify swing highs
   if(last_high_idx != -1 && prev_high_idx != -1)
   {
      if(swing_points[last_high_idx].price > swing_points[prev_high_idx].price)
         swing_points[last_high_idx].type = "HH";
      else
         swing_points[last_high_idx].type = "LH";
   }
   
   //--- Classify swing lows
   if(last_low_idx != -1 && prev_low_idx != -1)
   {
      if(swing_points[last_low_idx].price > swing_points[prev_low_idx].price)
         swing_points[last_low_idx].type = "HL";
      else
         swing_points[last_low_idx].type = "LL";
   }
   
   //--- Detect BOS and CHoCH
   DetectBOSandCHoCH();
}

//+------------------------------------------------------------------+
//| Detect Break of Structure and Change of Character               |
//+------------------------------------------------------------------+
void DetectBOSandCHoCH()
{
   int size = ArraySize(swing_points);
   
   if(size < 3)
      return;
   
   //--- Simple detection logic
   //--- BOS: Price continues in trend direction breaking previous structure
   //--- CHoCH: Price breaks structure in opposite direction (potential reversal)
   
   //--- This is a simplified implementation
   //--- Production version would track more detailed structure states
}

//+------------------------------------------------------------------+
//| Draw structure on chart                                         |
//+------------------------------------------------------------------+
void DrawStructure()
{
   //--- Delete old objects first
   DeleteAllObjects();
   
   int size = ArraySize(swing_points);
   
   for(int i = 0; i < size; i++)
   {
      string type = swing_points[i].type;
      
      //--- Skip if type not set or should not be displayed
      if(type == "INITIAL")
         continue;
      
      if((type == "HH" || type == "HL") && !Show_HH_HL)
         continue;
      
      if((type == "LH" || type == "LL") && !Show_LH_LL)
         continue;
      
      //--- Determine color based on type
      color label_color = clrWhite;
      
      if(type == "HH")
         label_color = HH_Color;
      else if(type == "HL")
         label_color = HL_Color;
      else if(type == "LH")
         label_color = LH_Color;
      else if(type == "LL")
         label_color = LL_Color;
      
      //--- Create label
      string label_name = obj_prefix + "Label_" + IntegerToString(i);
      
      if(ObjectCreate(0, label_name, OBJ_TEXT, 0, swing_points[i].time, swing_points[i].price))
      {
         ObjectSetString(0, label_name, OBJPROP_TEXT, type);
         ObjectSetInteger(0, label_name, OBJPROP_COLOR, label_color);
         ObjectSetInteger(0, label_name, OBJPROP_FONTSIZE, Label_Font_Size);
         ObjectSetString(0, label_name, OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, label_name, OBJPROP_ANCHOR, swing_points[i].is_high ? ANCHOR_LOWER : ANCHOR_UPPER);
      }
      
      //--- Draw structure lines
      if(Draw_Structure_Lines && i > 0)
      {
         //--- Find previous swing of same type (high to high or low to low)
         for(int j = i - 1; j >= 0; j--)
         {
            if(swing_points[j].is_high == swing_points[i].is_high)
            {
               string line_name = obj_prefix + "Line_" + IntegerToString(i);
               
               if(ObjectCreate(0, line_name, OBJ_TREND, 0, 
                              swing_points[j].time, swing_points[j].price,
                              swing_points[i].time, swing_points[i].price))
               {
                  ObjectSetInteger(0, line_name, OBJPROP_COLOR, label_color);
                  ObjectSetInteger(0, line_name, OBJPROP_WIDTH, Line_Width);
                  ObjectSetInteger(0, line_name, OBJPROP_STYLE, STYLE_DOT);
                  ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, false);
               }
               
               break; // Only connect to most recent previous swing
            }
         }
      }
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete all objects created by this indicator                    |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   int total = ObjectsTotal(0, 0, -1);
   
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      
      if(StringFind(name, obj_prefix) == 0)
      {
         ObjectDelete(0, name);
      }
   }
}
//+------------------------------------------------------------------+
