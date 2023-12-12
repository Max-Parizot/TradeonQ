function results = optimizeTrading2(TData,VData)

% Optimization variables

lb = [1, 1];
ub = [10, 50];
intcon  = [1,2];

% Objective funtion handle

f = @(x)negativeCash(x,TData,VData);

% Optimize

opts = optimoptions(@surrogateopt,...
                    'Display','off', ...
                    'PlotFcn',@surrogateoptplot,...                    
                    'MinSurrogatePoints',5,...
                    'MaxFunctionEvaluation',25);
                
results = surrogateopt(f,lb,ub,intcon,opts);

end % optimizeTrading2

% Objective (local)
function loss = negativeCash(x,TData,VData)

n = x(1);
N = x(2);

% Make trading matrix Q

Q = makeQ(TData,n,N);

% Trade on Q

cash = tradeOnQ(VData,Q,n,N);

% Objective value

loss = -cash;

end % negativeCash