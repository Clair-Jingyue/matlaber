function  [x_optimal cash_optimal weight_optimal value] = strat_min_variance (x_init, cash_init, mu, Q, cur_prices,period)
addpath('E:\Program Files\CPLEX\cplex\matlab\x64_win64')
n=20;
optimal_position = x_init;
port_value = cur_prices * x_init +cash_init;

lb = zeros(n,1);
ub = inf*ones(n,1);
A = ones(1,n);
b = 1;

cplex1= Cplex('min_Variance');
cplex1.addCols(zeros(n,1), [],lb, ub);
cplex1.addRows(b, A, b);
cplex1.Model.Q = 2*Q;
cplex1.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex1.Param.barrier.crossover.Cur = 1; % enable crossover
cplex1.DisplayFunc = []; % disable output to screen
cplex1.solve();
   
w_minVar = cplex1.Solution.x;
var_minVar = w_minVar' * Q * w_minVar;
ret_minVar = mu' * w_minVar;
x_init = floor(port_value.*w_minVar./(cur_prices)');
x_change = x_init - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005; %transaction cost
   new_port = cur_prices * x_init; %portfolio value without cash
   cash_new =port_value - new_port-spend; %remaining cash
if (cash_new < 0)
    %adjust the avaialbe fund used to buy stocks, deduct the lacking part
    %from the avaible fund,recalculate the positions
    x_init=floor((port_value-abs(cash_new)).*w_minVar./(cur_prices)');
    x_change = x_init - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;
   new_port = cur_prices * x_init;
    cash_new =port_value - new_port-spend;
end
if (cash_new < 0)
    %if the first adjustment is not enough, then give a higher adjustment,
    %deduct the estimated transaction cost from avaliable fund.
   limited_money = port_value-abs(spend);
    x_init=floor((limited_money).*w_minVar./(cur_prices)');
    x_change = x_init - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;
   new_port = cur_prices * x_init;
    cash_new =port_value - new_port-spend;
end
if (cash_new < 0)
    error('cash account must be positive')
end

 x_optimal = x_init;
 cash_optimal = port_value - new_port-spend;
 weight_optimal=w_minVar;
  value = cur_prices * x_optimal +cash_optimal;




