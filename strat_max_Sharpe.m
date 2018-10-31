function  [x_optimal cash_optimal weight_optimal value] = strat_max_Sharpe (init_positions, init_cash, mu, Q, cur_prices,period)
addpath('E:\Program Files\CPLEX\cplex\matlab\x64_win64')
n=20;
r_rf = 0.025/252;

optimal_position = init_positions;
 init_value =  1.000002119999000e+06;
port_value = cur_prices * init_positions +init_cash;

Q=[Q;zeros(1,n)];
Q=[Q zeros(n+1,1)];
cplex2 = Cplex('max_Sharpe');
cplex2.Model.sense = 'minimize';
lhs = [ 1 ; 0; -inf*ones(n,1)];%zeros(20,1)]
rhs=[ 1 ; 0; zeros(n,1)];
A =[mu'-r_rf, 0; ones(1,20),-1; eye(n,n) -1*ones(n,1)];%zeros(20,19),-ones(20,1)]
c = zeros(n+1,1);
lb=zeros(n+1,1);
ub = inf*ones(n+1,1);


cplex2.addCols(c, [], lb, ub);
cplex2.addRows(lhs, A, rhs);

cplex2.Model.Q = 2*Q;
cplex2.Param.qpmethod.Cur = 6; % concurrent algorithm
cplex2.Param.barrier.crossover.Cur = 1; % enable crossover
cplex2.DisplayFunc = [];
cplex2.solve(); %CPLEX states that the solution is infeasible!!


y = cplex2.Solution.x(1:n);
k = cplex2.Solution.x(n+1);
w_MaxSharpe = y/k;%optimal weight

init_positions = floor(port_value.*w_MaxSharpe./(cur_prices)');
x_change = init_positions - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;%transaction cost
   new_port = cur_prices * init_positions;%portfolio value without cash

   cash_new =port_value - new_port-spend;%remaining cash
if (cash_new < 0)
    %error('cash account must be positive') %adjust the avaialbe fund used to buy stocks, deduct the lacking part
    %from the avaible fund, recalculate the positions
    init_positions=floor((port_value-abs(cash_new)).*w_MaxSharpe./(cur_prices)');
    x_change = init_positions - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;
   new_port = cur_prices * init_positions;
    cash_new =port_value - new_port-spend;
end
if (cash_new < 0)
   % error('cash account must be positive') %if the first adjustment is not enough, then give a higher adjustment,
    %deduct the estimated transaction cost from avaliable fund.
    init_positions=floor((port_value-abs(spend)).*w_MaxSharpe./(cur_prices)');
    x_change = init_positions - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;
   new_port = cur_prices * init_positions;
    cash_new =port_value - new_port-spend;
end
if (cash_new < 0)
    error('cash account must be positive')
end

 x_optimal = init_positions;
 cash_optimal = cash_new;
 weight_optimal = w_MaxSharpe;
 value = cur_prices * x_optimal +cash_optimal;




