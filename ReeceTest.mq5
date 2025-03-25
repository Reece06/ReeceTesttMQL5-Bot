//+------------------------------------------------------------------+
//|                                                    ReeceTest.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Trade\PositionInfo.mqh>

CTrade trade;
CPositionInfo positionInfo;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   if(HasOpenPosition()){
      /*static datetime lastUpdate;
      if(TimeCurrent() - lastUpdate >= 30){
         SmartTrailingStop();
         lastUpdate = TimeCurrent();
      }*/
      return;
   }
   //Define input parameters
   double supportLevel = FindNearestSupport(); // do calculate
   double resistanceLevel = FindNearestResistance(); //do calculate
   
   
   
   double riskPercent = 1.0; // 1% can be dependent on user input
   
   double pipValue = 10; // for EU, 1 pip= 10$ per standard lot
   double stopLossPips = 10 * pipValue; //can also be dependent 
   double takeProfitPips = 25 * pipValue; //can also be depenednent
   double lotSize = CalculateLotSize(riskPercent,stopLossPips);
   
   //Get current Price and RSI Value
   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double rsiValue = iRSI(NULL, PERIOD_M5, 14, PRICE_CLOSE);
    
   
   //check for short trade condition
   if(currentBid >= resistanceLevel - 15 * _Point){
      if(IsBearishEngulfing()  && rsiValue > 65){
         PlaceOrder(ORDER_TYPE_SELL, lotSize,stopLossPips, takeProfitPips);
      }
   }
   
   
   //check for long trade conditions
   if(currentBid <= supportLevel + 15 * _Point){
      if(IsBullishEngulfing() && rsiValue < 35 ){
         PlaceOrder(ORDER_TYPE_BUY, lotSize, stopLossPips, takeProfitPips);
      }
   }
  }
  
//+------------------------------------------------------------------+
//Calculate lot size based on risk percentage                        |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskPercentage, double stopLossPips){
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (riskPercentage/100);
   double lotSize = riskAmount/(stopLossPips);
   
   
   //get normalization process
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;
   
   lotSize = round(lotSize/lotStep) * lotStep;
   
   return lotSize;
}


//+------------------------------------------------------------------+
//Check for bearish engulfing candle                                 |
//+------------------------------------------------------------------+
bool IsBearishEngulfing(){
   //implement logic to check for bearish engulfing pattern
   if(Bars(_Symbol, _Period) < 2) return false;
   
   //get candle data
   double prevOpen = iOpen(_Symbol,_Period,1);
   double prevClose = iClose(_Symbol, _Period, 1);
   double currOpen = iOpen(_Symbol,_Period, 0);
   double currClose = iClose(_Symbol, _Period, 0);
   
   //check conditions for bearish engulfing
   bool isPrevBullish = (prevClose > prevOpen);
   bool isCurrBearish = (currClose < currOpen);
   bool isEngulfing = (currOpen > prevClose) && (currClose < prevOpen);
   
   return (isPrevBullish && isCurrBearish && isEngulfing);
}

bool IsStrongBearishEngulfing(){
   if(!IsBearishEngulfing()) return false;
   
   //Wait for confirmation
   if(iVolume(_Symbol,_Period,0) < iVolume(_Symbol,_Period,1)) return false;
   
   return true;
}

//+------------------------------------------------------------------+
//Check for bullish engulfing candle                                 |
//+------------------------------------------------------------------+
bool IsBullishEngulfing(){
   //implement logic to check for bullish engulfing pattern
   //implement logic to check for bearish engulfing pattern
   if(Bars(_Symbol, _Period) < 2) return false;
   
   //get candle data
   double prevOpen = iOpen(_Symbol,_Period,1);
   double prevClose = iClose(_Symbol, _Period, 1);
   double currOpen = iOpen(_Symbol,_Period, 0);
   double currClose = iClose(_Symbol, _Period, 0);
   
   //check conditions for bearish engulfing
   bool isPrevBearish = (prevClose < prevOpen);
   bool isCurrBullish = (currClose > currOpen);
   bool isEngulfing = (currOpen < prevClose) && (currClose > prevOpen);
   
   return (isPrevBearish && isCurrBullish && isEngulfing);
   
}

bool IsStrongBullishEngulfing(){
   if(!IsBullishEngulfing()) return false;
   
   //Wait for confirmation
   if(iVolume(_Symbol,_Period,0) < iVolume(_Symbol,_Period,1)) return false;
   return true;
}

//+------------------------------------------------------------------+
//Calculate  buy/sell order                                          |
//+------------------------------------------------------------------+
void PlaceOrder(int orderType, double lotSize, double stopLossPIps, double takeProfitPips){
   double currentPrice = iClose(_Symbol,_Period,0);
   double stopLossPrice;
   double takeProfitPrice;
   
   
   
   
   if(orderType == ORDER_TYPE_BUY){
      stopLossPrice =  currentPrice - stopLossPIps * Point();
      takeProfitPrice = currentPrice + takeProfitPips * Point();
      
      SafeTradeOrder(orderType, currentPrice, stopLossPrice,takeProfitPrice, lotSize);
      
   }
   if(orderType == ORDER_TYPE_SELL){
      stopLossPrice =  currentPrice + stopLossPIps * Point();
      takeProfitPrice = currentPrice - takeProfitPips * Point();
      
      SafeTradeOrder(orderType, currentPrice, stopLossPrice,takeProfitPrice, lotSize);
   }
}

//+------------------------------------------------------------------+
//Place  buy/sell order                                              |
//+------------------------------------------------------------------+
bool SafeTradeOrder(int type,double entry, double sl, double tp, double lots){
   //normalize prices
   entry = NormalizePrice(entry);
   sl = NormalizePrice(sl);
   tp = NormalizePrice(tp);
   
   //Get broker requirement
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double minDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
   double freezeDist = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * point;
   
   //calculate distances
   
   if(type == ORDER_TYPE_BUY){
      if((entry - sl) < minDist) sl = entry - minDist;
      if((tp - entry) < minDist) tp = entry + minDist;
   }
   else{
      if((sl - entry) < minDist) sl = entry + minDist;
      if((entry - tp) < minDist) tp = entry - minDist;
   }
   
   //check freeze level
   if(MathAbs(entry - SymbolInfoDouble(_Symbol, type == ORDER_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK)) <= freezeDist){
      Print("Cannot Trade - price too close to freeze level");
      return false;
   }
   
   //Execute trade
   if(type == ORDER_TYPE_BUY){
      Print("entry : " + entry);
      Print("sl : " + sl);
      Print("tp : " + tp);
      return trade.Buy(lots, _Symbol, entry, sl, tp);
   }
   else{
   Print("entry : " + entry);
      Print("sl : " + sl);
      Print("tp : " + tp);
      return trade.Sell(lots, _Symbol, entry, sl, tp);
   }
}

double NormalizePrice(double price){
   return NormalizeDouble(price, _Digits);
}

bool HasOpenPosition(){
   return positionInfo.Select(_Symbol);
}


//+------------------------------------------------------------------+
//Smart trailing stops                                               |
//+------------------------------------------------------------------+
void SmartTrailingStop(){
   for(int i = PositionsTotal()-1; i >=0;i--){
      if(positionInfo.SelectByIndex(i)){
         
         double bid = NormalizeDouble( SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
         double ask = NormalizeDouble( SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         
         //calculate dynamic stop distance
         
         double volatilityPips = GetRecentVolatility(14);
         double stopDistance = volatilityPips * point * 1.5;
         
         //calculate new SL
         double newSL = 0;
         bool shouldModify = false;
         
         if(positionInfo.PositionType()== POSITION_TYPE_BUY){
            double highestSinceOpen = GetHighestSinceOpen(positionInfo.Ticket());
            newSL = NormalizeDouble(highestSinceOpen- stopDistance, _Digits);
            
            shouldModify = (newSL > positionInfo.PriceOpen()) &&
                           (newSL > positionInfo.StopLoss() || positionInfo.StopLoss() == 0);
         }
         else{
            double lowestSinceOpen = GetLowestSinceOpen(positionInfo.Ticket());
            newSL = NormalizeDouble(lowestSinceOpen + stopDistance, _Digits);
            
            shouldModify = (newSL < positionInfo.PriceOpen()) && 
                           (newSL < positionInfo.StopLoss() || positionInfo.StopLoss() == 0);
         }
         
         if(shouldModify){
            if(!trade.PositionModify(positionInfo.Ticket(), newSL, positionInfo.TakeProfit())){
               Print("Failed to Modify SL! ERROR : ",GetLastError());
            }
         }
      }
   }
}

double GetRecentVolatility(int lookbackBars){
   double sumRanges = 0;
   for(int i= 0; i< lookbackBars; i++){
      sumRanges += (iHigh(_Symbol,PERIOD_CURRENT,i) - iLow(_Symbol,PERIOD_CURRENT,i))/ _Point;
   }
   
   return sumRanges / lookbackBars;
}

double GetHighestSinceOpen(ulong ticket){
   if(!positionInfo.SelectByTicket(ticket)) return 0;
   
   datetime openTime = (datetime)positionInfo.Time();
   double highest = positionInfo.PriceOpen();
   int i = 0;
   
   while(iTime(_Symbol,PERIOD_CURRENT,i) > openTime && i < 1000){
      highest = MathMax(highest, iHigh(_Symbol,PERIOD_CURRENT,i));
      i++;
   }
   
   return highest;
}

double GetLowestSinceOpen(ulong ticket){
   if(!positionInfo.SelectByTicket(ticket)) return 0;
   
   datetime openTime = (datetime)positionInfo.Time();
   double lowest = positionInfo.PriceOpen();
   int i = 0;
   
   while(iTime(_Symbol,PERIOD_CURRENT,i) > openTime && i < 1000){
      lowest = MathMin(lowest, iLow(_Symbol,PERIOD_CURRENT,i));
      i++;
   }
   
   return lowest;
}


//+------------------------------------------------------------------+
//SUPPORT AND RESISTANCE CODE                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//Find Nearest Support Level                                         |
//+------------------------------------------------------------------+
double FindNearestSupport(){
 
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double nearestSupport = 0;
   double smallestGap = EMPTY_VALUE;
   
   for(int i = 3; i < 100 ; i++){
      if(IsSwingLow(i)){
         double suppLevel = iLow(_Symbol, PERIOD_M15, i);
         double gap = currentPrice - suppLevel;
         
         if(gap > 0 && gap < smallestGap){
            smallestGap = gap;
            nearestSupport = suppLevel;
         }
      }
   }
   
   return(nearestSupport);
}


//+------------------------------------------------------------------+
//Swing Low Detection code                                           |
//+------------------------------------------------------------------+
bool IsSwingLow(int index){
   return(iLow(_Symbol, PERIOD_M15, index) < iLow(_Symbol, PERIOD_M15, index + 1) &&
         iLow(_Symbol, PERIOD_M15, index) < iLow(_Symbol, PERIOD_M15, index - 1 )
         );
}



//+------------------------------------------------------------------+
//Find Nearest Resistance Level                                         |
//+------------------------------------------------------------------+
double FindNearestResistance(){
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double nearestResistance = 0;
   double smallestGap = EMPTY_VALUE;
   
   for(int i = 3; i < 100 ; i++){
      if(IsSwingHigh(i)){
         double resLevel = iHigh(_Symbol, PERIOD_M15, i);
         double gap = resLevel - currentPrice ;
         
         if(gap > 0 && gap < smallestGap){
            smallestGap = gap;
            nearestResistance = resLevel;
         }
      }
   }
   
   return(nearestResistance);
}


//+------------------------------------------------------------------+
//Swing Low Detection code                                           |
//+------------------------------------------------------------------+
bool IsSwingHigh(int index){
   return(iHigh(_Symbol, PERIOD_M15, index) > iHigh(_Symbol, PERIOD_M15, index + 1) &&
         iHigh(_Symbol, PERIOD_M15, index) > iHigh(_Symbol, PERIOD_M15, index - 1 )
         );
}