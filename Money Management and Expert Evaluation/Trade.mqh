﻿//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                                            Copyright 2018, NOVTS |
//|                                                 http://novts.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, NOVTS"
#property link      "http://novts.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Trade
  {
private:
double StopLoss;
double Profit;
double   Lot;
double TrailingStop;
double priceBuy;
double priceSell;
double slBuy;
double slSell;

CPositionInfo  m_position;                   
CTrade         m_trade;   


public:
                     Trade(double stopLoss, double profit, double lot, double trailingStop);
                    ~Trade();
void                 Order(bool Buy, bool StopBuy, bool Sell, bool StopSell);  
void                 Trailing();             
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade::Trade(double stopLoss, double profit, double lot, double trailingStop)
  {
  StopLoss=stopLoss;
  Profit=profit;
  Lot=lot;
  TrailingStop=trailingStop;
  priceBuy=0.0;
  priceSell=0.0;
  slBuy=0.0;
  slSell=0.0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Trade::~Trade()
  {
  }
//+------------------------------------------------------------------+
void Trade::Trailing(){
   bool BuyOpened=false;  
   bool SellOpened=false; 

   if(PositionSelect(_Symbol)==true) 
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         BuyOpened=true;  
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         SellOpened=true; 
        }
     }
 //-----------------------------------------------------------------------------
MqlTradeRequest mrequest;
MqlTradeCheckResult check_result;
MqlTradeResult mresult;

MqlTick latest_price;
if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest quotes - :", GetLastError(),"!!");
      return;
     }
if(BuyOpened==true) {   
double  TBS=0;
    if(TrailingStop<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)*_Point){
    TBS=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)*_Point;
    }else{
    TBS=TrailingStop;
    }
if(
latest_price.bid-priceBuy>=TBS
){ 
         mrequest.action = TRADE_ACTION_SLTP; 
         mrequest.price = NormalizeDouble(latest_price.ask,_Digits);      
         mrequest.sl = NormalizeDouble(priceBuy,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(latest_price.ask + Profit,_Digits);
         mrequest.symbol = _Symbol;                                            
         mrequest.volume = Lot;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;
         mrequest.type = ORDER_TYPE_BUY;                                       
         
         if(!OrderCheck(mrequest,check_result))
     {
      return;
     }else{
         if(OrderSend(mrequest,mresult)){}
   }      
        
         if(mresult.retcode==10009 || mresult.retcode==10008) 
           {           
          slBuy= mrequest.sl;   
          priceBuy=slBuy+TrailingStop;  
           }
         else
           {         
            return;
           }  
           }
        }  
        
if(SellOpened==true) {   
double  TSS=0;
    if(TrailingStop<SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)*_Point){
    TSS=SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL)*_Point;
    }else{
    TSS=TrailingStop;
    }
if(
priceSell-latest_price.ask>=TSS
){ 
         mrequest.action = TRADE_ACTION_SLTP; 
         mrequest.price = NormalizeDouble(latest_price.bid,_Digits);      
         mrequest.sl = NormalizeDouble(priceSell,_Digits); // Stop Loss
         mrequest.tp = NormalizeDouble(latest_price.bid - Profit,_Digits);
         mrequest.symbol = _Symbol;                                            
         mrequest.volume = Lot;                                                
         mrequest.type_filling = ORDER_FILLING_FOK;
         mrequest.type = ORDER_TYPE_SELL;                                       
        
        if(!OrderCheck(mrequest,check_result))
     {
      return;
     }else{
         if(OrderSend(mrequest,mresult)){}
     }    
         
         if(mresult.retcode==10009 || mresult.retcode==10008) 
           {           
          slSell= mrequest.sl;   
          priceSell=slSell-TrailingStop;  
           }
         else
           {         
            return;
           }  
           }
        }       
     
}  
//+------------------------------------------------------------------+
void Trade::Order(bool Buy, bool BuyStop, bool Sell, bool SellStop){

   bool BuyOpened=false;  
   bool SellOpened=false; 

   if(PositionSelect(_Symbol)==true) 
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
        {
         BuyOpened=true;  
        }
      else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         SellOpened=true; 
        }
     }
     //-----------------------------------------------------------------------------
MqlTradeRequest mrequest;
MqlTradeCheckResult check_result;
MqlTradeResult mresult;

MqlTick latest_price;
if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest quotes - :", GetLastError(),"!!");
      return;
     }
if(Buy==true&&BuyOpened==false){ 
//--------------------------------------------------------------------------------------------------------------------   
if(((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE))==SYMBOL_TRADE_EXECUTION_INSTANT){
ZeroMemory(mrequest);
mrequest.action = TRADE_ACTION_DEAL;                              
mrequest.symbol = _Symbol;
mrequest.volume = Lot;
mrequest.price = NormalizeDouble(latest_price.ask,_Digits);
mrequest.sl = NormalizeDouble(latest_price.bid - StopLoss,_Digits); 
mrequest.tp = NormalizeDouble(latest_price.ask + Profit,_Digits);
mrequest.deviation=10;  
mrequest.type = ORDER_TYPE_BUY;                
mrequest.type_filling = ORDER_FILLING_FOK;

ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {
     if(check_result.retcode==10014)Alert("Invalid volume in request");
     if(check_result.retcode==10015)Alert("Incorrect price in request");
     if(check_result.retcode==10016)Alert("Wrong stops in request");
     if(check_result.retcode==10019)Alert("There are no sufficient funds to execute the request");
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           {  
           priceBuy=mresult.price;  
           slBuy= mrequest.sl;                                 
           }
         else
           {
if(mresult.retcode==10004) 
{
Print("Requote bid ",mresult.bid);
Print("Requote ask ",mresult.ask);
}else{
Print("Retcode ",mresult.retcode);
}         
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
}
//-------------------------------------------------------------------------------------------------------------
if(((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE))==SYMBOL_TRADE_EXECUTION_EXCHANGE){
ZeroMemory(mrequest);
mrequest.action = TRADE_ACTION_DEAL;                              
mrequest.symbol = _Symbol;
mrequest.volume = Lot;
mrequest.type = ORDER_TYPE_BUY;                
mrequest.type_filling = ORDER_FILLING_FOK;
ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {
     if(check_result.retcode==10014)Alert("Invalid volume in request");
     if(check_result.retcode==10019)Alert("There are no sufficient funds to execute the request");
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           { 
           priceBuy=mresult.price;  
            
//-----------------------           
ZeroMemory(mrequest);           
mrequest.action = TRADE_ACTION_SLTP; 
mrequest.symbol = _Symbol;    
mrequest.sl = NormalizeDouble(mresult.price - StopLoss,_Digits); 
mrequest.tp = NormalizeDouble(mresult.price + Profit,_Digits);
ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {     
     if(check_result.retcode==10015)Alert("Incorrect price in request");
     if(check_result.retcode==10016)Alert("Wrong stops in request");     
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           {           
 slBuy= mrequest.sl;                      
           }
         else
           {
Print("Retcode ",mresult.retcode);        
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
//------------------------------------------                                   
           }
         else
           {
Print("Retcode ",mresult.retcode);    
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
}
//-------------------------------------------------------------------------------------------------------------
} 
//--------------------------------------------------------------------------------------------------------------
if(SellStop==true&&SellOpened==true){ 
//--------------------------------------------------------------------------------------------------------------------   
for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties  
      {       
           ENUM_POSITION_TYPE type = m_position.PositionType();
           if(type==POSITION_TYPE_SELL)  
           m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol  
      }
//-------------------------------------------------------------------------------------------------------------
}     
//--------------------------------------------------------------------------------------------------------------     
if(Sell==true&&SellOpened==false){
//------------------------------------------------------------------------------------------------------------------
if(((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE))==SYMBOL_TRADE_EXECUTION_INSTANT){
ZeroMemory(mrequest);
mrequest.action = TRADE_ACTION_DEAL;                              
mrequest.symbol = _Symbol;
mrequest.volume = Lot;
mrequest.price = NormalizeDouble(latest_price.bid,_Digits);
mrequest.sl = NormalizeDouble(latest_price.ask + StopLoss,_Digits); 
mrequest.tp = NormalizeDouble(latest_price.bid - Profit,_Digits);
mrequest.deviation=10;  
mrequest.type = ORDER_TYPE_SELL;                
mrequest.type_filling = ORDER_FILLING_FOK;

ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {
     if(check_result.retcode==10014)Alert("Invalid volume in request");
     if(check_result.retcode==10015)Alert("Incorrect price in request");
     if(check_result.retcode==10016)Alert("Wrong stops in request");
     if(check_result.retcode==10019)Alert("There are no sufficient funds to execute the request");
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           {           
 priceSell=mresult.price;
 slSell= mrequest.sl;                     
           }
         else
           {
if(mresult.retcode==10004) 
{
Print("Requote bid ",mresult.bid);
Print("Requote ask ",mresult.ask);
}else{
Print("Retcode ",mresult.retcode);
}         
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
} 
//-------------------------------------------------------------------------------------------------------------
if(((ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE))==SYMBOL_TRADE_EXECUTION_EXCHANGE){
ZeroMemory(mrequest);
mrequest.action = TRADE_ACTION_DEAL;                              
mrequest.symbol = _Symbol;
mrequest.volume = Lot;
mrequest.type = ORDER_TYPE_SELL;                
mrequest.type_filling = ORDER_FILLING_FOK;

ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {
     if(check_result.retcode==10014)Alert("Invalid volume in request");
     if(check_result.retcode==10019)Alert("There are no sufficient funds to execute the request");
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           { 
 priceSell=mresult.price;
       
//-----------------------           
ZeroMemory(mrequest);           
mrequest.action = TRADE_ACTION_SLTP; 
mrequest.symbol = _Symbol;    
mrequest.tp = NormalizeDouble(mresult.price - Profit,_Digits); 
mrequest.sl = NormalizeDouble(mresult.price + StopLoss,_Digits);
ZeroMemory(check_result);
ZeroMemory(mresult);
if(!OrderCheck(mrequest,check_result))
     {     
     if(check_result.retcode==10015)Alert("Incorrect price in request");
     if(check_result.retcode==10016)Alert("Wrong stops in request");     
      return;
     }else{ 
 if(OrderSend(mrequest,mresult)){
 if(mresult.retcode==10009 || mresult.retcode==10008) 
           {           
slSell= mrequest.sl;                      
           }
         else
           {
Print("Retcode ",mresult.retcode);        
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
//------------------------------------------                                   
           }
         else
           {
Print("Retcode ",mresult.retcode);    
           }  
}else{
Print("Retcode ",mresult.retcode);
}
} 
}
//-------------------------------------------------------------------------------------------------------------
    
}     
//-------------------------------------------------------------------------------
if(BuyStop==true&&BuyOpened==true){
//------------------------------------------------------------------------------------------------------------------
for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties  
      {       
           ENUM_POSITION_TYPE type = m_position.PositionType();
           if(type==POSITION_TYPE_BUY)            
           m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol  
            
       }
//-------------------------------------------------------------------------------------------------------------
    
}     
//----------------------------------------------------------------------------  
}    
