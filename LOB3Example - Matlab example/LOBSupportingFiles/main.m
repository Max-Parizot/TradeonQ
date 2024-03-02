%main
close all; clear all
%Hyper parameters 
    %lambda= 1; % lambda — The weighting parameter used to compute the imbalance index I
    % nThe initial number of bins used to partition smoothed I for discretization
    % N window length
    %dI — The number of backward ticks used to average I during smoothing -m
    %dS — The number of forward ticks used to convert the prices S to discrete DS

%import data
data1=table2array(readtable('MSFT_2012-06-21_34200000_57600000_message_10.csv'));
data2=table2array(readtable('MSFT_2012-06-21_34200000_57600000_orderbook_10.csv'));
[MoBid, bid_volume, MoAsk, ask_volume,Time] = lobster_data(data1, data2);

%build data object for backtesting
% Convert duration to datetime (assuming a reference time, e.g., midnight)
durationTime=seconds(Time);    %t - arrival time from midnight in ticks (seconds)
referenceTime = datetime('00:00:00', 'Format', 'HH:mm:ss'); % Set your reference time
t = referenceTime + durationTime;

S=NaN(length(MoBid),1); %initialize variable

for price = 1:length(MoBid)
    S(price,1) = midprice(MoBid(price,1),MoAsk(price,1));   %S - midprice
end

I=NaN(size(bid_volume,1),1); %initialize variable
for time = 1:size(bid_volume,1)
    I(time,1) = imbalance_ratio(bid_volume(time,:),ask_volume(time,:));    %I - imbalance index
end

MOBid=MoBid(:,1);
MOAsk=MoAsk(:,1);
Data = timetable(t,S,I,MOBid,MOAsk); 
    %MOBid - level 1 bidding price
    %MOAsk - level 1 ask price
%Separate data for testing and validation
bp = round((0.80)*length(t)); % Use 80% of data for training
TData = Data(1:bp,:);       % Training data
VData = Data(bp+1:end,:);   % Validation data


%Machine learning portion
n=5;
N=20;
Q=makeQ(TData,n,N);
Cash=309900 * 20;
prob_limit=.0;
[cash2, CASH, ASSETS,POSITIONS]=trade_on_Q_with_cash_limit (Data,Q,n,N,Cash,prob_limit);
percent_increase = (cash2-Cash)/Cash*100
increase = (cash2-Cash)/100

% Your existing plotting code for CASH and ASSETS
figure(1)
subplot(4,1,1)
plot(Data.t, CASH)
xlabel('Time')
ylabel('Cash')
title('Cash over time')
% Add an orange dotted line for the last cash data point
hold on;
lastCashPoint = ones(1,length(CASH)) *cash2;
plot(Data.t, lastCashPoint, 'r--', 'LineWidth', .2);
hold off;

subplot(4,1,2)
plot(Data.t, ASSETS)
xlabel('Time')
ylabel('Assets')
title('Assets over time')

% Third subplot: Difference in cash price over time
subplot(4,1,3)
positions_difference=POSITIONS-Cash;
zero=zeros(1,length(POSITIONS));
plot(Data.t, positions_difference,Data.t,zero,'r--','LineWidth',.2)
xlabel('Time')
ylabel('Cash Difference')
title('Positions')
ylim([-550000, 60000])

subplot(4,1,4)
plot(Data.t,Data.S)
xlabel('Time')
ylabel('Stock Price in cents')


[cash, CASH, ASSETS,POSITIONS] = tradeOnQ(Data, Q, n, N);
figure(2)
% Your existing plotting code for CASH and ASSETS
subplot(4,1,1)
plot(Data.t, CASH)
xlabel('Time')
ylabel('Cash')
title('Cash over time')

% Add an orange dotted line for the last cash data point
hold on;
lastCashPoint = ones(1,length(CASH)) *cash2;
plot(Data.t, lastCashPoint, 'r--', 'LineWidth', .2);
hold off;

subplot(4,1,2)
plot(Data.t, ASSETS)
xlabel('Time')
ylabel('Assets')
title('Assets over time')

% Third subplot: Difference in cash price over time
subplot(4,1,3)

plot(Data.t, Data.I ,Data.t,zero,'r--','LineWidth',.2)
xlabel('Time')
ylabel('Imbalance ratio')
title('Imbalance ratio')

subplot(4,1,4)
plot(Data.t,Data.S)
xlabel('Time')
ylabel('Stock Price in cents')


%cash=tradeOnQ(VData, Q, n, N)
% 
% results = optimizeTrading(TData,VData);
% [BEST,negcash]= bestPoint(results);
% n=BEST.numBins;
% N=BEST.numTicks;
% dollars= -negcash / 100;
% cash= 309900 * 100;
% percent_increase = (-negcash-cash)/cash * 100
% increase_in_dollars = (-negcash-cash) / 100
% [QT,P, Pcond, G, v, H, C,phi] = makeQ(TData,n,N); 
% [rho, DS] = getStates(TData, n, N);
% [QV,PQV, PcondQV, GQV, vQV, HQV, CQV,phiQV] = makeQ(VData,n,N);
% QTVDiff = QT - QV;
% Inhomogeneity = (QT > 0.5 & QV < 0.5 ) | (QT < 0.5 & QV > 0.5 ); %identify trading inefficiencies in the Algorithm. 