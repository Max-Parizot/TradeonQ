function Q = makeQ(Data,n,N)
% This function generates a transition matrix Q based on input data.
%this is done by backtesting data to generate Q. Once Q is made it can be
%used for future returns.
%makes Q using training data
% Extract relevant parameters from the input structure 'Data'
numBins = n;      % Number of bins for discretization
numStates = 3 * n; % Total number of states
dI = N;           % Imbalance smoothing window size
dS = N;           % Price change window size

% Markov states
[rho, DS] = getStates(Data,n, N); 

% Map states to a composite state space 'phi'
phi = NaN(size(rho));
for i = 1:length(rho)
    switch DS(i)
        case -1
            phi(i) = rho(i);
        case 0
            phi(i) = rho(i) + numBins;
        case 1
            phi(i) = rho(i) + 2 * numBins;
    end
end

% Transition counts
C = zeros(numStates);
for i = 1:length(phi) - dS - 1
    C(phi(i), phi(i + 1)) = C(phi(i), phi(i + 1)) + 1;
end

% Holding times, generator matrix
H = diag(C);
G = C ./ H;
v = sum(G, 2);
G = G + diag(-v);

% Transition matrix
P = expm(G * dI);

% Bayes condition
PCond = zeros(size(P));
phiNums = 1:numStates;
modNums = mod(phiNums, numBins);
for i = phiNums
    for j = phiNums
        idx = (modNums == modNums(j));
        PCond(i, j) = sum(P(i, idx));
    end
end

% Trading matrix
Q = P ./ PCond;
end
