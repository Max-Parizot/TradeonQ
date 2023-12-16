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
results = optimizeTrading(TData,VData);
[BEST,negcash]= bestPoint(results);
n=BEST.numBins;
N=BEST.numTicks;
dollars= -negcash / 100;
% Compare Qs
n=5
N=20
QT = makeQ(TData,n,N);    
QV = makeQ(VData,n,N);
QTVDiff = QT - QV
Inhomogeneity = (QT > 0.5 & QV < 0.5 ) | (QT < 0.5 & QV > 0.5 ) %identify trading inefficiencies in the Algorithm. 