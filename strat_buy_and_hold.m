function  [x_optimal cash_optimal weight_optimal value] = strat_buy_and_hold(x_init, cash_init, mu, Q, cur_prices,period)

   x_optimal = x_init;
   cash_optimal = cash_init;
   weight_optimal = [];
 value = cur_prices * x_init +cash_optimal;
end