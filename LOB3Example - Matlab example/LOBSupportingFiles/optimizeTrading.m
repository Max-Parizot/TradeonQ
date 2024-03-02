function results = optimizeTrading(TData,VData)

% Optimization variables
n = optimizableVariable('numBins',[3 13],'Type','integer');
N = optimizableVariable('numTicks',[10 60],'Type','integer');
% Objective function handle
f = @(x)negativeCash(x,TData,VData);
% Optimize
results = bayesopt(f,[n,N],...
                   'IsObjectiveDeterministic',true,...
                   'AcquisitionFunctionName','expected-improvement-plus',...
                   'MaxObjectiveEvaluations',100,...
                   'ExplorationRatio',2,...
                   'Verbose',0, ...
                   'UseParallel',true);
end % optimizeTrading

% Objective (local)
function loss = negativeCash(x,TData,VData)
%grab values from numBins and numTicks
n = x.numBins;
N = x.numTicks;

% Make trading matrix Q
Q = makeQ(TData,n,N);

% Trade on Q
cash = trade_on_Q_with_cash_limit(VData,Q,n,N,309900 * 100,0);
% Objective value
loss = -cash;

end % negativeCash