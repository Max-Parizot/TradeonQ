function [rho, DS] = getStates(Data, n, N)
%page 24 in the report
% [rho, DS] = getStates(Data, n, N) calculates states based on input data.
% This function takes time series data, performs smoothing on imbalance, 
% and computes price changes to derive states.

% Extracting data from the input structure
t = Data.t; % Time vector
I = Data.I; % Imbalance vector
S = Data.S; % Price vector

% Hyperparameters
dI = N; % Window size for smoothing imbalance
dS = N; % Window size for calculating price changes
numBins = n; % Number of bins for discretization

% Smoothed imbalance bins
sI = smoothed_time_weighted_average(I, dI); % Smoothing imbalance using moving average Needs to be the time weighed moving average
binEdges = linspace(-1, 1, numBins + 1); % Bin edges for discretization
rho = discretize(sI, binEdges); % Discretize smoothed imbalance into bins

% Price changes
DS = NaN(size(S)); % Initialize array for price changes
DS(1:end - dS) = sign( S(dS + 1:end) - S(1:end - dS)); % Compute price changes To make rolling need to adjust to page 24
end
