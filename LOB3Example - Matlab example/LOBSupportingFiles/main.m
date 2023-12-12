%main
%Hyper parameters 
%lambda= 1; % lambda — The weighting parameter used to compute the imbalance index I
n= 3; %The number of bins used to partition smoothed I for discretization
N=20; %window length
dI=dS; dS=N; 
    %dI — The number of backward ticks used to average I during smoothing -m
    %dS — The number of forward ticks used to convert the prices S to discrete DS

