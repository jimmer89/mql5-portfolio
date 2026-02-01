//+------------------------------------------------------------------+
//|                                                 RSI_Alert_EA.mq5 |
//|                                                     Jaume Sancho |
//|                                      https://github.com/jimmer89 |
//+------------------------------------------------------------------+
#property copyright "Jaume Sancho"
#property link      "https://github.com/jimmer89"
#property version   "1.00"
#property description "RSI Alert System with multi-channel notifications and visual feedback"

//--- Input Parameters
input group "RSI Settings"
input int                  RSI_Period = 14;                    // RSI Period
input double               Overbought_Level = 70.0;            // Overbought Level
input double               Oversold_Level = 30.0;              // Oversold Level
input ENUM_TIMEFRAMES      Alert_Timeframe = PERIOD_CURRENT;   // Alert Timeframe
input ENUM_APPLIED_PRICE   Applied_Price = PRICE_CLOSE;        // Applied Price

input group "Alert Settings"
input bool                 Enable_Push_Notifications = true;   // Enable Push Notifications
input bool                 Enable_Email_Alerts = false;        // Enable Email Alerts
input bool                 Enable_Sound_Alerts = true;         // Enable Sound Alerts
input bool                 Enable_Popup_Alerts = true;         // Enable Popup Alerts
input string               Sound_File = "alert.wav";           // Sound File

input group "Visual Settings"
input bool                 Show_Info_Panel = true;             // Show Info Panel
input ENUM_BASE_CORNER     Panel_Corner = CORNER_LEFT_UPPER;   // Panel Corner
input color                Overbought_Arrow_Color = clrRed;    // Overbought Arrow Color
input color                Oversold_Arrow_Color = clrBlue;     // Oversold Arrow Color

//--- Global Variables
int rsi_handle;
double rsi_buffer[];
datetime last_alert_time = 0;
string last_alert_type = "";

//--- Object names for info panel
#define PANEL_BASE "RSI_Panel_"
#define PANEL_BG PANEL_BASE + "BG"
#define PANEL_TITLE PANEL_BASE + "Title"
#define PANEL_RSI PANEL_BASE + "RSI"
#define PANEL_STATE PANEL_BASE + "State"
#define PANEL_LAST PANEL_BASE + "Last"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Validate inputs
   if(RSI_Period < 1)
   {
      Print("Error: RSI Period must be greater than 0");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   if(Overbought_Level <= Oversold_Level)
   {
      Print("Error: Overbought level must be greater than Oversold level");
      return(INIT_PARAMETERS_INCORRECT);
   }
   
   //--- Create RSI indicator handle
   rsi_handle = iRSI(_Symbol, Alert_Timeframe, RSI_Period, Applied_Price);
   
   if(rsi_handle == INVALID_HANDLE)
   {
      Print("Error creating RSI indicator handle");
      return(INIT_FAILED);
   }
   
   //--- Set array as series
   ArraySetAsSeries(rsi_buffer, true);
   
   //--- Create info panel if enabled
   if(Show_Info_Panel)
      CreateInfoPanel();
   
   Print("RSI Alert EA initialized successfully on ", _Symbol, " ", EnumToString(Alert_Timeframe));
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Release indicator handle
   if(rsi_handle != INVALID_HANDLE)
      IndicatorRelease(rsi_handle);
   
   //--- Delete info panel objects
   DeleteInfoPanel();
   
   Print("RSI Alert EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Copy RSI values
   if(CopyBuffer(rsi_handle, 0, 0, 3, rsi_buffer) < 3)
   {
      Print("Error copying RSI buffer data");
      return;
   }
   
   //--- Get current and previous RSI values
   double rsi_current = rsi_buffer[0];
   double rsi_previous = rsi_buffer[1];
   
   //--- Update info panel
   if(Show_Info_Panel)
      UpdateInfoPanel(rsi_current);
   
   //--- Check for overbought condition
   if(rsi_previous < Overbought_Level && rsi_current >= Overbought_Level)
   {
      if(IsNewAlert("OVERBOUGHT"))
      {
         SendAlert("OVERBOUGHT", rsi_current);
         DrawArrow("OVERBOUGHT");
         last_alert_type = "OVERBOUGHT";
         last_alert_time = TimeCurrent();
      }
   }
   
   //--- Check for oversold condition
   if(rsi_previous > Oversold_Level && rsi_current <= Oversold_Level)
   {
      if(IsNewAlert("OVERSOLD"))
      {
         SendAlert("OVERSOLD", rsi_current);
         DrawArrow("OVERSOLD");
         last_alert_type = "OVERSOLD";
         last_alert_time = TimeCurrent();
      }
   }
}

//+------------------------------------------------------------------+
//| Check if this is a new alert to avoid spam                      |
//+------------------------------------------------------------------+
bool IsNewAlert(string alert_type)
{
   //--- Allow alert if it's the first one
   if(last_alert_time == 0)
      return true;
   
   //--- Allow alert if type changed
   if(last_alert_type != alert_type)
      return true;
   
   //--- Allow alert if enough time has passed (at least 1 bar)
   datetime current_bar_time = iTime(_Symbol, Alert_Timeframe, 0);
   if(current_bar_time > last_alert_time)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Send alerts through enabled channels                            |
//+------------------------------------------------------------------+
void SendAlert(string alert_type, double rsi_value)
{
   string message = StringFormat("RSI Alert on %s %s: %s (RSI: %.2f)", 
                                 _Symbol, 
                                 EnumToString(Alert_Timeframe),
                                 alert_type,
                                 rsi_value);
   
   //--- Sound alert
   if(Enable_Sound_Alerts)
      PlaySound(Sound_File);
   
   //--- Popup alert
   if(Enable_Popup_Alerts)
      Alert(message);
   
   //--- Push notification
   if(Enable_Push_Notifications)
      SendNotification(message);
   
   //--- Email alert
   if(Enable_Email_Alerts)
   {
      string subject = StringFormat("RSI %s Alert - %s", alert_type, _Symbol);
      SendMail(subject, message);
   }
   
   Print(message);
}

//+------------------------------------------------------------------+
//| Draw arrow on chart                                             |
//+------------------------------------------------------------------+
void DrawArrow(string alert_type)
{
   string arrow_name = StringFormat("RSI_Arrow_%s_%d", alert_type, TimeCurrent());
   datetime arrow_time = iTime(_Symbol, Alert_Timeframe, 0);
   double arrow_price;
   int arrow_code;
   color arrow_color;
   
   if(alert_type == "OVERBOUGHT")
   {
      arrow_price = iHigh(_Symbol, Alert_Timeframe, 0);
      arrow_code = 234; // Down arrow
      arrow_color = Overbought_Arrow_Color;
   }
   else // OVERSOLD
   {
      arrow_price = iLow(_Symbol, Alert_Timeframe, 0);
      arrow_code = 233; // Up arrow
      arrow_color = Oversold_Arrow_Color;
   }
   
   //--- Create arrow object
   if(ObjectCreate(0, arrow_name, OBJ_ARROW, 0, arrow_time, arrow_price))
   {
      ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE, arrow_code);
      ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, arrow_color);
      ObjectSetInteger(0, arrow_name, OBJPROP_WIDTH, 2);
      ObjectSetString(0, arrow_name, OBJPROP_TOOLTIP, StringFormat("RSI %s: %.2f", alert_type, rsi_buffer[0]));
   }
}

//+------------------------------------------------------------------+
//| Create info panel on chart                                      |
//+------------------------------------------------------------------+
void CreateInfoPanel()
{
   int x_offset = 10;
   int y_offset = 20;
   int line_height = 18;
   
   //--- Background
   ObjectCreate(0, PANEL_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_CORNER, Panel_Corner);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XDISTANCE, x_offset);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YDISTANCE, y_offset);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XSIZE, 200);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, 90);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BGCOLOR, clrBlack);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);
   
   //--- Title
   CreateLabel(PANEL_TITLE, "RSI Alert Dashboard", x_offset + 10, y_offset + 5, clrWhite, 9, "Arial Bold");
   
   //--- RSI Value
   CreateLabel(PANEL_RSI, "RSI: --", x_offset + 10, y_offset + 25, clrYellow, 8, "Arial");
   
   //--- State
   CreateLabel(PANEL_STATE, "State: Neutral", x_offset + 10, y_offset + 45, clrGray, 8, "Arial");
   
   //--- Last Alert
   CreateLabel(PANEL_LAST, "Last: None", x_offset + 10, y_offset + 65, clrGray, 8, "Arial");
}

//+------------------------------------------------------------------+
//| Create label helper function                                    |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int font_size, string font)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetString(0, name, OBJPROP_FONT, font);
}

//+------------------------------------------------------------------+
//| Update info panel with current data                             |
//+------------------------------------------------------------------+
void UpdateInfoPanel(double rsi_value)
{
   //--- Update RSI value
   ObjectSetString(0, PANEL_RSI, OBJPROP_TEXT, StringFormat("RSI: %.2f", rsi_value));
   
   //--- Update state
   string state_text;
   color state_color;
   
   if(rsi_value >= Overbought_Level)
   {
      state_text = "State: OVERBOUGHT";
      state_color = clrRed;
   }
   else if(rsi_value <= Oversold_Level)
   {
      state_text = "State: OVERSOLD";
      state_color = clrBlue;
   }
   else
   {
      state_text = "State: Neutral";
      state_color = clrGray;
   }
   
   ObjectSetString(0, PANEL_STATE, OBJPROP_TEXT, state_text);
   ObjectSetInteger(0, PANEL_STATE, OBJPROP_COLOR, state_color);
   
   //--- Update last alert
   if(last_alert_time > 0)
   {
      string last_text = StringFormat("Last: %s", last_alert_type);
      ObjectSetString(0, PANEL_LAST, OBJPROP_TEXT, last_text);
      ObjectSetInteger(0, PANEL_LAST, OBJPROP_COLOR, 
                       last_alert_type == "OVERBOUGHT" ? Overbought_Arrow_Color : Oversold_Arrow_Color);
   }
}

//+------------------------------------------------------------------+
//| Delete info panel objects                                       |
//+------------------------------------------------------------------+
void DeleteInfoPanel()
{
   ObjectDelete(0, PANEL_BG);
   ObjectDelete(0, PANEL_TITLE);
   ObjectDelete(0, PANEL_RSI);
   ObjectDelete(0, PANEL_STATE);
   ObjectDelete(0, PANEL_LAST);
}
//+------------------------------------------------------------------+
