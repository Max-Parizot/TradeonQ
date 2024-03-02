import numpy as np
from scipy.signal import convolve
from scipy.linalg import expm

def time_weighted_smooth(data, window):
    #calculates the time weighted average of the data
    x = np.arange(1, window + 1)
    weights = np.exp(-0.5 * x)
    weights /= weights.sum()  # Normalize weights to sum to 1
    smoothed_data = convolve(data, np.flip(weights), mode='same', method='auto')
    return smoothed_data

def imbalance_ratio(Vbid_volume,Vask_volume):
    # Imbalance is a ratio of limit order volumes between the bid and ask side
    # This function assumes 1 timestep
    #for speed consider bringing the weights out of the function
    x = np.arange(1, len(Vbid_volume) + 1)
    weight = np.exp(-0.5 * x) #calculates the exponential decay factor for each element
    Vbid = sum(weight * Vbid_volume)
    
    if len(Vbid_volume) != len(Vask_volume):
        x = np.arange(1, len(Vask_volume) + 1)
        weight = np.exp(-0.5 * x)
    
    Vask = sum(weight * Vask_volume)
    
    I = (Vbid - Vask) / (Vbid + Vask)
    return  I

def midprice(MOBid, MOAsk):
    # Returns midprice for given bid and ask price
    # This function can handle vectors
    
    S = (MOBid + MOAsk) / 2
    
    return S

def get_states(Data, n, N):
    # Extracting data from the input structure
    # Imbalance vector
    # Price vector

    # Hyperparameters
    dI = N  # Window size for smoothing imbalance
    dS = N  # Window size for calculating price changes
    n  # Number of bins for discretization

    # Smoothed imbalance bins
    sI =  time_weighted_smooth(Data['I'], dI)
    binEdges = np.linspace(-1., 1., num=int(n+1))
    rho = np.digitize(sI, binEdges, right=False)   # Discretize smoothed imbalance ratio into bins
    rho = rho[1:-dS+1]
    # Price changes
    DS=np.zeros_like(rho)
    for i in range(len(DS)):
        DS[i] = np.sign(Data['S'][i + dS] - Data['S'][i])
    return rho, DS

def make_Q(Data, n, N):
    # Extract relevant parameters from the input structure 'Data'
    numBins = n  # Number of bins for discretization
    numStates = 3 * n  # Total number of states
    dI = N  # Imbalance smoothing window size
    dS = N  # Price change window size
    #markov states
    [rho, DS] = get_states(Data, numBins, dI)
    # Map states to a composite state space 'phi'
    phi = np.full_like(rho, np.nan)
    for i in range(len(rho)):
        if DS[i] == -1:
            phi[i] = rho[i]-1  #adjusting for python indexing
        elif DS[i] == 0:
            phi[i] = rho[i] + numBins-1 #adjusting for python indexing
        elif DS[i] == 1:
            phi[i] = rho[i] + 2*numBins -1 #adjusting for python indexing

    C = np.zeros((numStates, numStates))
    for i in range(len(phi) - 1):
        C[phi[i], phi[i+1]] += 1
    # Holding times, generator matrix
    H = np.diag(C)
    H = H.reshape(-1, 1) # Reshape H into a column vector
    G = C / H
    v = np.sum(G, axis=1)
    G = G + np.diag(-v)

    # Transition matrix
    P = expm(G * dI)

    # Bayes condition
    PCond = np.zeros_like(P)
    phiNums = np.arange(1, numStates+1)
    modNums = phiNums % numBins
    for i in phiNums:
        for j in phiNums:
            idx = (modNums == modNums[j-1])
            PCond[i-1, j-1] = np.sum(P[i-1, idx])

    # Trading matrix
    Q = P / PCond

    return Q

def trade_on_Q(Data,Q,n,N):
    # Extract relevant data from the input structure 'Data'
    t = Data['t']       # Time vector
    MOBid = Data['MOBid'] # Market order bid prices
    MOAsk = Data['MOAsk'] # Market order ask prices

    # Obtain states and corresponding indices using the getStates function
    rho, DS = get_states(Data, n, N)

    # Initialize trading variables
    cash = 0     # Total cash
    assets = 0   # Number of assets (stocks) held

    # Active trading loop
    T = len(t) # Total number of time points

    # Loop through each time point for active trading
    for tt in range(1, T-N): # added the additional -1

        # Get row and column indices for the current state in the Q matrix
        row = rho[tt-1] + n * (DS[tt-1] + 1) -1
        downColumn = rho[tt] -1
        upColumn = rho[tt] + 2 * n  -1

        # If predicting a downward price move
        if Q[row, downColumn] > 0.5:
            cash = cash + MOBid[tt] # Sell
            assets = assets - 1

        # If predicting an upward price move
        elif Q[row, upColumn] > 0.5:
            cash = cash - MOAsk[tt] # Buy
            assets = assets + 1

    # End of trading: liquidate position
    if assets > 0:
        cash = cash + assets * MOBid[T-1] # Sell off remaining assets
    elif assets < 0:
        cash = cash + assets * MOAsk[T-1] # Buy back remaining short positions

    return cash
    
def negative_cash(x, TData, VData):
    # grab values from numBins and numTicks
    n = x['numBins']
    N = x['numTicks']
    
    # Make trading matrix Q
    Q = make_Q(TData, n, N)
    
    # Trade on Q
    cash = trade_on_Q(VData, Q, n, N)
    
    # Objective value
    loss = -cash
    
    return loss

def get_LOB(resp):
    # Check if the request was successful (status code 200)
    if resp.status_code == 200:
        # Parse the JSON response
        data = resp.json()

        # Access the asks and bids arrays
        asks = data['result']['XXBTZUSD']['asks']
        ask_prices, ask_volumes, ask_timestamps = zip(*[(float(entry[0]), float(entry[1]), entry[2]) for entry in asks])

        bids = data['result']['XXBTZUSD']['bids']
        bid_prices, bid_volumes, bid_timestamps = zip(*[(float(entry[0]), float(entry[1]), entry[2]) for entry in bids])

        mid_price=(ask_prices[0]+bid_prices[0])/2 #midprice is the average of the best bid and ask

        ImbalanceRatio=imbalance_ratio(bid_volumes,ask_volumes)
    else:
        print(f"Error: {resp.status_code}")

    return ask_prices, ask_volumes, ask_timestamps, bid_prices, bid_volumes, bid_timestamps, mid_price,ImbalanceRatio

from skopt import BayesSearchCV
def optimize_trading(TData, VData):
    # Optimization variables
    dimensions = {'numBins': (3, 13, 'integer'), 'numTicks': (10, 60, 'integer')}
    
    # Objective function handle
    def f(x):
        return negative_cash(x, TData, VData)
    
    # Optimize
    results = BayesSearchCV(f, dimensions,
                            n_iter=75,
                            random_state=42,
                            n_jobs=-1,
                            cv=0,
                            verbose=0)
    
    results.fit(np.empty((0, len(dimensions))))
    
    return results
