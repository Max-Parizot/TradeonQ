import numpy as np
import functions as Q
from scipy.signal import convolve
from scipy.linalg import expm

def getstates(Data, n, N):
    # Extracting data from the input structure
    # Imbalance vector
    # Price vector

    # Hyperparameters
    dI = N  # Window size for smoothing imbalance
    dS = N  # Window size for calculating price changes
    n  # Number of bins for discretization

    # Smoothed imbalance bins
    sI =  Q.time_weighted_smooth(Data['I'], dI)
    binEdges = np.linspace(-1., 1., num=int(n+1))
    rho = np.digitize(sI, binEdges, right=False)   # Discretize smoothed imbalance ratio into bins
    rho = rho[dS:]  #rho[1:-dS+1]
    # Price changes
    DS=np.zeros_like(rho)
    for i in range(dS,len(DS)):
        DS[i] = np.sign(Data['S'][i] - Data['S'][i - dS])
    return rho, DS