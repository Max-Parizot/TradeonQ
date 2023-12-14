import requests
import numpy as np
from scipy.linalg import expm
from skopt import BayesSearchCV
from skopt.space import Integer

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

    else:
        print(f"Error: {resp.status_code}")

    return ask_prices, ask_volumes, ask_timestamps, bid_prices, bid_volumes, bid_timestamps

def imbalance_ratio(Vbid_volume,Vask_volume):
    # Imbalance is a ratio of limit order volumes between the bid and ask side
    # This function assumes 1 timestep
    
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
    
    S = (MOBid - MOAsk) / 2 + MOAsk
    
    return S

def smoothed_time_weighted_average(data, window):
    # This function assumes that the data is evenly distributed with time.
    # The user will specify a certain amount of ticks for the function.
    
    # Define exponential weights
    x = np.arange(1, window + 1)
    weights = np.exp(-0.5 * x)
    
    # Initialize smoothed_data variable
    smoothed_data = np.full_like(data, np.nan)
    smoothed_data[:window] = data[:window]

    # Iterate over each time point
    for i in range(window, len(data)):
        # Calculate the dot product of weights with a subset of data
        smoothed_data[i] = np.dot(weights, data[i - window + 1:i + 1]) / np.sum(weights)

    # Output the smoothed time-weighted average
    twa = smoothed_data
    
    return twa

def get_states(Data, n, N):
    # Extracting data from the input structure
    t = Data['t']  # Time vector
    I = Data['I']  # Imbalance vector
    S = Data['S']  # Price vector

    # Hyperparameters
    dI = N  # Window size for smoothing imbalance
    dS = N  # Window size for calculating price changes
    numBins = n  # Number of bins for discretization

    # Smoothed imbalance bins
    sI = smoothed_time_weighted_average(I, dI)
    binEdges = np.linspace(-1., 1., numBins + 1.)
    rho = np.digitize(sI, binEdges) - 1  # Discretize smoothed imbalance into bins. -1 to start index at 0

    # Price changes
    DS = np.full_like(S, np.nan)
    DS[:-dS] = np.sign(S[dS:] - S[:-dS])  # Compute price changes

    return rho, DS

def make_Q(Data, n, N):
    # Extract relevant parameters from the input structure 'Data'
    numBins = n  # Number of bins for discretization
    numStates = 3 * n  # Total number of states
    dI = N  # Imbalance smoothing window size
    dS = N  # Price change window size

    # Markov states
    rho, DS = get_states(Data, n, N)

    # Map states to a composite state space 'phi'
    phi = np.zeros_like(rho)
    for i in range(len(rho)):
        if DS[i] == -1:
            phi[i] = rho[i]
        elif DS[i] == 0:
            phi[i] = rho[i] + numBins
        elif DS[i] == 1:
            phi[i] = rho[i] + 2 * numBins

    # Transition counts
    C = np.zeros((numStates, numStates))
    for i in range(len(phi) - dS - 1):
        C[phi[i], phi[i + 1]] += 1

    # Holding times, generator matrix
    H = np.diag(C)
    G = C / H[:, None]
    v = np.sum(G, axis=1)
    G = G + np.diag(-v)

    # Transition matrix
    P = expm(G * dI)

    # Bayes condition
    PCond = np.zeros_like(P)
    phiNums = np.arange(1, numStates + 1)
    modNums = phiNums % numBins
    for i in phiNums - 1:
        for j in phiNums - 1:
            idx = (modNums == modNums[j])
            PCond[i, j] = np.sum(P[i, idx])

    # Trading matrix
    Q = P / PCond

    return Q

def trade_on_Q(Data, Q, n, N):
    # Extract relevant data from the input structure 'Data'
    t = Data['t']  # Time vector
    MOBid = Data['MOBid']  # Market order bid prices
    MOAsk = Data['MOAsk']  # Market order ask prices

    # Obtain states and corresponding indices using the get_states function
    rho, DS = get_states(Data, n, N)

    # Initialize trading variables
    cash = 0  # Total cash
    assets = 0  # Number of assets (stocks) held

    # Active trading loop
    T = len(t)  # Total number of time points

    # Loop through each time point for active trading
    for tt in range(1, T - N):

        # Get row and column indices for the current state in the Q matrix
        row = rho[tt - 1] + n * (DS[tt - 1] + 1)
        down_column = rho[tt]
        up_column = rho[tt] + 2 * n

        # If predicting a downward price move
        if Q[row, down_column] > 0.5:
            cash += MOBid[tt]  # Sell
            assets -= 1

        # If predicting an upward price move
        elif Q[row, up_column] > 0.5:
            cash -= MOAsk[tt]  # Buy
            assets += 1

def optimize_trading(TData, VData):
    # Optimization variables
    space = {'numBins': Integer(3, 13), 'numTicks': Integer(10, 60)}

    # Objective function handle
    def objective_function(x):
        return negative_cash(x, TData, VData)

    # Optimize
    results = BayesSearchCV(objective_function, space, n_iter=75, n_jobs=-1, random_state=42, verbose=0)

    return results

# Objective (local)
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

if __name__ == "__main__":
    resp = requests.get('https://api.kraken.com/0/public/Depth?pair=XBTUSD')

    ask_prices, ask_volumes, ask_timestamps, bid_prices, bid_volumes, bid_timestamps = get_LOB(resp)

    print(ask_prices)
    