function results = optimizeTrading(TData,VData)

% Optimization variables

n = optimizableVariable('numBins',[1 10],'Type','integer');
N = optimizableVariable('numTicks',[1 50],'Type','integer');

% Objective function handle

f = @(x)negativeCash(x,TData,VData);

% Optimize

results = bayesopt(f,[n,N],...
                   'IsObjectiveDeterministic',true,...
                   'AcquisitionFunctionName','expected-improvement-plus',...
                   'MaxObjectiveEvaluations',25,...
                   'ExplorationRatio',2,...
                   'Verbose',0);

end % optimizeTrading

% Objective (local)
function loss = negativeCash(x,TData,VData)

n = x.numBins;
N = x.numTicks;

% Make trading matrix Q

Q = makeQ(TData,n,N);

% Trade on Q

cash = tradeOnQ(VData,Q,n,N);

% Objective value

loss = -cash;

end % negativeCash