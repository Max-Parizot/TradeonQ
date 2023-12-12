function cash = tradeOnQ(Data, Q, n, N)
% This function performs trading based on a given Q matrix and input Data.
% It uses the Q matrix to make predictions and execute buy or sell actions accordingly.

% Extract relevant data from the input structure 'Data'
t = Data.t;       % Time vector
MOBid = Data.MOBid; % Market order bid prices
MOAsk = Data.MOAsk; % Market order ask prices

% Obtain states and corresponding indices using the getStates function
[rho, DS] = getStates(Data, n, N);

% Initialize trading variables
cash = 0;     % Total cash
assets = 0;   % Number of assets (stocks) held

% Active trading loop
T = length(t); % Total number of time points

% Loop through each time point for active trading
for tt = 2:T-N

    % Get row and column indices for the current state in the Q matrix
    row = rho(tt-1) + n * (DS(tt-1) + 1);
    downColumn = rho(tt);
    upColumn = rho(tt) + 2 * n;

    % If predicting a downward price move
    if Q(row, downColumn) > 0.5
        cash = cash + MOBid(tt); % Sell
        assets = assets - 1;

    % If predicting an upward price move
    elseif Q(row, upColumn) > 0.5
        cash = cash - MOAsk(tt); % Buy
        assets = assets + 1;
    end
end

% End of trading: liquidate position
if assets > 0
    cash = cash + assets * MOBid(T); % Sell off remaining assets
elseif assets < 0
    cash = cash + assets * MOAsk(T); % Buy back remaining short positions
end
end
