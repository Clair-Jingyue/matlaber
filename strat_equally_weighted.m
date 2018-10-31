function  [x_optimal cash_optimal weight_optimal value] = strat_equally_weighted (init_positions, init_cash, mu, Q, cur_prices,period)
 n=20;
 w_equal=(1/n)*ones(20,1);
 optimal_position = init_positions;
 init_value =  1.000002119999000e+06;
 port_value = cur_prices * init_positions +init_cash;

   init_positions = floor(port_value.*w_equal./(cur_prices)');
   x_change = init_positions - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;%transaction cost
   new_port = cur_prices * init_positions;%portfolio value without cash
   cash_new =port_value - new_port-spend;%remaining cash
if (cash_new < 0)   %adjust the avaialbe fund used to buy stocks, deduct the lacking part
    %from the avaible fund,recalculate the positions
    init_positions=floor((port_value-abs(cash_new)).*w_equal./(cur_prices)');
    x_change = init_positions - optimal_position;
   spend = (cur_prices*abs(x_change))*0.005;
   new_port = cur_prices * init_positions;
    cash_new =port_value - new_port-spend;
end
if (cash_new < 0)
   % error('cash account must be positive') %if the first adjustment is not enough, then give a higher adjustment,
    %deduct the estimated transaction cost from avaliable fund.
    init_positions=floor((port_value-abs(spend)).*w_equal./(cur_prices)');
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
    value = cur_prices * x_optimal +cash_optimal;
    weight_optimal = w_equal;

