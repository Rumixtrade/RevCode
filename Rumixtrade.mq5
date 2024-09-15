//+------------------------------------------------------------------+
//|                                                   Rumixtrade.mq5 |
//|                                    Copyright 2024, Ahmed Ibrahim |
//|                                            https://t.me/AIM_algo |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Ahmed Ibrahim"
#property link      "https://t.me/AIM_algo"
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade trade;

//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
input string Developer_Contacts = "https://t.me/AIM_algo <><> gouda9050@gmail.com";//Contact Developer
//>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>//
input int         Magic                = 1001;
input string      EA_Comment           = "DAR EA"; //EA Comment
input double      Lot                  = 0.01;     //Lot
input bool        AutoLot              = true;     //Auto Lot
input double      per                  = 3;        //Lot %
input bool        TS                   = true;     //Enable Trailing Stop
input int         TrailingStart        = 50;       //Trailing Start
input int         TrailingStep         = 10;       //Trailing Step
input int         Stoploss             = -1;       //Stoploss (0 = Auto / -1 = No SL / 0+ = Manual SL)

input double      step                 = 0.02;
input double      maximum              = 0.2;
input int         Rsi_period           = 14;        //RSI period
input int         FI_period            = 13;       //Force Index period
double Ask,Bid;
int psarHandle,foHandle,rsihandle,macdHandle;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(Magic);
   
//   if(TimeCurrent()>D'2024.09.15') {
//    Alert("Expert is Expired, Please contact developer Ahmed Ibrahim");
//    return(INIT_FAILED);
//   } 
   
   psarHandle = iSAR(Symbol(),PERIOD_CURRENT,step,maximum);
   rsihandle      = iRSI(NULL,PERIOD_CURRENT,Rsi_period,PRICE_CLOSE);
   foHandle    = iCustom(Symbol(),PERIOD_CURRENT,"Examples//Force_Index",FI_period);
   macdHandle  = iMACD(Symbol(),PERIOD_CURRENT,12,26,9,PRICE_CLOSE);
   
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

   Ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   Bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double lot =Lot;
   if(AutoLot){
      lot= NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*0.00001*per,2);
   
      if(lot<=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN))
         lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
         
      if(lot>=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX))
         lot=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
         
   }
   else lot =Lot;
   
   if(TS){
      if(Stoploss>=0 || buycount()==1)
         TrailingStopBuy();
      if(Stoploss>=0 || sellcount()==1)
         TrailingStopSell();
         }

   if(IsNewBar()){
   
      if(buyProfitCnt()>0 && buycount()>1)
         closebuypositions();
      if(sellProfitCnt()>0 && sellcount()>1)
         closesellpositions();
   
  //    if(iClose(Symbol(),PERIOD_CURRENT,1)>iOpen(Symbol(),PERIOD_CURRENT,1) && iClose(Symbol(),PERIOD_CURRENT,2)<iOpen(Symbol(),PERIOD_CURRENT,2) && 
  //      MathAbs(iClose(Symbol(),PERIOD_CURRENT,1)-iOpen(Symbol(),PERIOD_CURRENT,1))>MathAbs(iClose(Symbol(),PERIOD_CURRENT,2)-iOpen(Symbol(),PERIOD_CURRENT,2)))
   if(mcd(1)>0 && rsi(1)>50 && fi(1)>0 &&  sar(1) < iLow(Symbol(),PERIOD_CURRENT,1) && (mcd(2)<0 || rsi(2)<50 || fi(2)<0 || sar(2) > iHigh(Symbol(),PERIOD_CURRENT,1)))
      {
         double BuySL = 0;
         double bd = (iClose(Symbol(),PERIOD_CURRENT,1)-iLow(Symbol(),PERIOD_CURRENT,1))/Point();
         double BuyTP = iClose(Symbol(),PERIOD_CURRENT,1) + (bd*2*Point());
         
         if(Stoploss<0)
                {BuySL = 0;BuyTP=0;}
         if(Stoploss==0)
                BuySL = iLow(Symbol(),PERIOD_CURRENT,1);
         if(Stoploss>0)
                BuySL = Ask+(Stoploss*Point());

            trade.Buy(lot,Symbol(),Ask,BuySL,BuyTP,"");
      }
    //  if(iClose(Symbol(),PERIOD_CURRENT,1)<iOpen(Symbol(),PERIOD_CURRENT,1) && iClose(Symbol(),PERIOD_CURRENT,2)>iOpen(Symbol(),PERIOD_CURRENT,2) &&
    //    MathAbs(iClose(Symbol(),PERIOD_CURRENT,1)-iOpen(Symbol(),PERIOD_CURRENT,1))>MathAbs(iClose(Symbol(),PERIOD_CURRENT,2)-iOpen(Symbol(),PERIOD_CURRENT,2)))
   if(mcd(1)<0 && rsi(1)<50 && fi(1)<0 &&  sar(1) > iHigh(Symbol(),PERIOD_CURRENT,1) && (mcd(2)>0 || rsi(2)>50 || fi(2)>0 || sar(2) < iLow(Symbol(),PERIOD_CURRENT,1)))
      {
         double SellSL = 0;
         double sd = (iHigh(Symbol(),PERIOD_CURRENT,1)-iClose(Symbol(),PERIOD_CURRENT,1))/Point();
         double SellTP = iClose(Symbol(),PERIOD_CURRENT,1) - (sd*2*Point());
         
         if(Stoploss<0)
                {SellSL = 0;SellTP=0;}
         if(Stoploss==0)
                SellSL = iHigh(Symbol(),PERIOD_CURRENT,1);
         if(Stoploss>0)
                SellSL = Bid-(Stoploss*Point());

            trade.Sell(lot,Symbol(),Bid,SellSL,SellTP,"");
      }
   }
   
  }
//+------------------------------------------------------------------+
bool IsNewBar()

  {
   static datetime RegBarTime=0;
   datetime ThisBarTime = iTime(NULL,PERIOD_CURRENT,0);
   if(ThisBarTime == RegBarTime)
     {
      return(false);
     }
   else
     {
      RegBarTime = ThisBarTime;
      return(true);
     }
  }

double sar(int index)
  {
   double value[];
   CopyBuffer(psarHandle,0,index,1,value);
   return value[0];
  }

double rsi(int index)
  {
   double value[];
   CopyBuffer(rsihandle,0,index,1,value);
   return value[0];
  }
  
double fi(int index)
  {
   double value[];
   CopyBuffer(foHandle,0,index,1,value);
   return value[0];
  }
double mcd(int index)
  {
   double value[];
   CopyBuffer(macdHandle,0,index,1,value);
   return value[0];
  }

   double buycount()
   {
      int openOrders = PositionsTotal();
      int  count =0;
      for(int i = 0; i < openOrders; i++)
      {
         PositionGetTicket(i);

         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetInteger(POSITION_MAGIC)==Magic)
         {
           count++;
         }
      }
      return count;
   }
   
   double sellcount()
   {
      int openOrders = PositionsTotal();
      int  count =0;
    
      for (int i = 0; i < openOrders; i++)
          {
            PositionGetTicket(i);
              
              if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetInteger(POSITION_MAGIC)==Magic)
              {
                 count++;
              }
          }    
     return count;    
   }     
   
    void TrailingStopBuy(){
    
    for(int i = PositionsTotal()-1; i >= 0; i--){ 
    
      PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic){
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
         
         double oprice = PositionGetDouble(POSITION_PRICE_OPEN);
         double Tsl    = NormalizeDouble((TrailingStart*_Point),_Digits);
         double Tssl   = NormalizeDouble((TrailingStep*_Point),_Digits);
         double currSL = PositionGetDouble(POSITION_SL);
         double currTP = PositionGetDouble(POSITION_TP);
           long Ticket = PositionGetInteger(POSITION_TICKET);
          
            if( Bid - oprice  > Tsl ){
               if(currSL < Bid - Tssl || currSL==0){
                 trade.PositionModify(Ticket,Bid-Tssl,currTP);
                }
      }
      }
      }
    }
    }  
    
    void TrailingStopSell(){
    
    for(int i = PositionsTotal()-1; i >= 0; i--){ 
    
      PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==Magic){
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
         
         double oprice = PositionGetDouble(POSITION_PRICE_OPEN);
         double  Tsl   = NormalizeDouble((TrailingStart*_Point),_Digits);
         double Tssl   = NormalizeDouble((TrailingStep*_Point),_Digits);
         double currSL = PositionGetDouble(POSITION_SL);
         double currTP = PositionGetDouble(POSITION_TP);
           long Ticket = PositionGetInteger(POSITION_TICKET);
          
            if( oprice - Ask  > Tsl ){
               if(currSL > Ask + Tssl || currSL==0){
                 trade.PositionModify(Ticket,Ask+Tssl,currTP);
              }
      }
      }
      }
    }
    }    
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closebuypositions()
  {
   long ticket=0;
   for(int i = PositionsTotal()-1; i>=0 ;  i--)
     {
      PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)==Symbol())
        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY  && PositionGetInteger(POSITION_MAGIC)==Magic)
           {
            ticket = PositionGetInteger(POSITION_TICKET);
            trade.PositionClose(ticket);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closesellpositions()
  {
   long ticket=0;
   for(int i = PositionsTotal()-1; i>=0 ;  i--)
     {
      PositionGetTicket(i);
      if(PositionGetString(POSITION_SYMBOL)==Symbol())
        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL  && PositionGetInteger(POSITION_MAGIC)==Magic)
           {
            ticket = PositionGetInteger(POSITION_TICKET);
            trade.PositionClose(ticket);
           }
        }
     }
  }

   double buyProfitCnt()
  {
  double resu=0;
    
      for(int i =0; i< PositionsTotal();  i++)
       {
         PositionGetTicket(i);
              
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         resu = resu + PositionGetDouble(POSITION_PROFIT);
        }
     }
   return resu;
  }     
  
   double sellProfitCnt()
  {
  double resu=0;
    
      for(int i =0; i< PositionsTotal();  i++)
       {
         PositionGetTicket(i);
              
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         resu = resu + PositionGetDouble(POSITION_PROFIT);
        }
     }
   return resu;
  }     
  