function S = midprice(MOBid,MOAsk)
%returns midprice for given bid and ask price
S=(MOBid-MOAsk)./2 + MOAsk;
end