clc;
clear all;
format long

% Input files
input_file_prices  = 'Daily_closing_prices.csv';

% Read daily prices
if(exist(input_file_prices,'file')) %\n inserts a newline character.
  fprintf('\nReading daily prices datafile - %s\n', input_file_prices)
  fid = fopen(input_file_prices);
     % Read instrument tickers
     hheader  = textscan(fid, '%s', 1, 'delimiter', '\n');
     headers = textscan(char(hheader{:}), '%q', 'delimiter', ',');
     tickers = headers{1}(2:end);
     % Read time periods
     vheader = textscan(fid, '%[^,]%*[^\n]');
     dates = vheader{1}(1:end);
  fclose(fid);
  data_prices = dlmread(input_file_prices, ',', 1, 1);
else
  error('Daily prices datafile does not exist')
end

% Convert dates into array [year month day]
format_date = 'mm/dd/yyyy';
dates_array = datevec(dates, format_date);
dates_array = dates_array(:,1:3);

% Find the number of trading days in Nov-Dec 2014 and
% compute expected return and covariance matrix for period 1
day_ind_start0 = 1;
day_ind_end0 = length(find(dates_array(:,1)==2014));
cur_returns0 = data_prices(day_ind_start0+1:day_ind_end0,:) ./ data_prices(day_ind_start0:day_ind_end0-1,:) - 1;
mu = mean(cur_returns0)';
Q = cov(cur_returns0);

% Remove datapoints for year 2014
data_prices = data_prices(day_ind_end0+1:end,:);
dates_array = dates_array(day_ind_end0+1:end,:);
dates = dates(day_ind_end0+1:end,:);

% Initial positions in the portfolio
init_positions = [5000 950 2000 0 0 0 0 2000 3000 1500 0 0 0 0 0 0 1001 0 0 0]';

% Initial value of the portfolio
init_value = data_prices(1,:) * init_positions;
fprintf('\nInitial portfolio value = $ %10.2f\n\n', init_value);
% %10 for the number of spaces
%.2f Number of digits to the right of the decimal point

% Initial portfolio weights
w_init = (data_prices(1,:) .* init_positions')' / init_value;

% Number of periods, assets, trading days
N_periods = 6*length(unique(dates_array(:,1))); % 6 periods per year,2 month per periods
N = length(tickers);
N_days = length(dates);

% Annual risk-free rate for years 2015-2016 is 2.5%
r_rf = 0.025;

% Number of strategies
strategy_functions = {'strat_buy_and_hold' 'strat_equally_weighted' 'strat_min_variance' 'strat_max_Sharpe'};
strategy_names     = {'Buy and Hold' 'Equally Weighted Portfolio' 'Mininum Variance Portfolio' 'Maximum Sharpe Ratio Portfolio'};
N_strat = 4; % comment this in your code
%N_strat = length(strategy_functions); % uncomment this in your code
fh_array = cellfun(@str2func, strategy_functions, 'UniformOutput', false);

for (period = 1:N_periods)
   % Compute current year and month, first and last day of the period
   if(dates_array(1,1)==15)
       cur_year  = 15 + floor(period/7); % divide by 7 because each year has 6 periods, just for increase the year.
   else
       cur_year  = 2015 + floor(period/7);
   end
   cur_month = 2*rem(period-1,6) + 1;
   day_ind_start = find(dates_array(:,1)==cur_year & dates_array(:,2)==cur_month, 1, 'first');
   day_ind_end = find(dates_array(:,1)==cur_year & dates_array(:,2)==(cur_month+1), 1, 'last');
   fprintf('\nPeriod %d: start date %s, end date %s\n', period, char(dates(day_ind_start)), char(dates(day_ind_end)));

   % Prices for the current day
   cur_prices = data_prices(day_ind_start,:);

   % Execute portfolio selection strategies
   for(strategy =1:N_strat)

      % Get current portfolio positions
      if(period==1)
         curr_positions = init_positions;
         curr_cash = 0;
         portf_value{strategy} = zeros(N_days,1);
      else
         curr_positions = x{strategy,period-1};
         curr_cash = cash{strategy,period-1};
      end

      % Compute strategy
      [x{strategy,period} cash{strategy,period} weight{strategy,period} value{strategy,period}] = fh_array{strategy}(curr_positions, curr_cash, mu, Q, cur_prices,period);

     %cash adjustment is in each strategy function
     
     %code for Question 3, a new strategy.
[dynamic_x(:,period) dynamic_cash(period) dynamic_weight(:,period) dynamic_value(period)] = dynamic_strategy(curr_positions, curr_cash, mu, Q, cur_prices,period);
portf_value{5}(day_ind_start:day_ind_end)= data_prices(day_ind_start:day_ind_end,:) * dynamic_x(:,period) + dynamic_cash(period);

      % Compute portfolio value
      portf_value{strategy}(day_ind_start:day_ind_end) = data_prices(day_ind_start:day_ind_end,:) * x{strategy,period} + cash{strategy,period};

      fprintf('   Strategy "%s", value begin = $ %10.2f, value end = $ %10.2f\n', char(strategy_names{strategy}), portf_value{strategy}(day_ind_start), portf_value{strategy}(day_ind_end));

   end
     % Compute expected returns and covariances for the next period
 
   cur_returns = data_prices(day_ind_start+1:day_ind_end,:) ./ data_prices(day_ind_start:day_ind_end-1,:) - 1;
   mu = mean(cur_returns)';
   Q = cov(cur_returns);
   end
   portf_value{5}=reshape(portf_value{5},504,1)


% Plot the daily valule of 4 strategies
figure(1)
for(strategy = 1:4);

dayvalue(:,strategy) = portf_value{strategy};
prvalue(:,strategy)=cell2mat(value(strategy,:));
ts = timeseries(dayvalue(:,strategy),dates);
ts.Name = num2str(strategy_names{strategy});
ts.TimeInfo.Units = 'days';
ts.TimeInfo.Format = 'mmm dd, yy';
ts.Time = ts.Time - ts.Time(1)
p(1,strategy)=plot(ts);
hold on
scatter([1:12], prvalue(:,strategy),'d','filled');
%legend(num2str(strategy_names{strategy}));
hold on
title('Portfolio Value of Each Strategy (from Jan-02-2015 to Dec-30-2016)');
%xlabel('Day')
ylabel('Daily Portfolio Value (USD)');
end

date_frmt ='mmm dd, yy';
legend( p,'Buy and Hold','Equally Weighted Portfolio' ,'Mininum Variance Portfolio', 'Maximum Sharpe Ratio Portfolio','location','bestoutside')


% plot the asset weight change of min_variance strategy over 12 periods
for i = 1:20;
    str{i}=['Asset' num2str(i)];
end 
    figure(3)
for period =1:12
his_weight3(:,period)= weight{3,period};
end
for n=1:20
plot3= plot([1:12],his_weight3);
tit=[num2str(strategy_names{3}),'  Weight Changes over 12 Periods'];
title(tit);
legend(str,'location','bestoutside')

end
xlabel('Periods');
axis([1 12 0 1]);
% plot the asset weight change of max_sharpe ratio strategy over 12 periods
    figure(4)
for period =1:12
his_weight4(:,period)= weight{4,period};
end
for n=1:20
plot([1:12],his_weight4);
tit=[num2str(strategy_names{4}),'  Weight Changes over 12 Periods '];
title(tit);
legend(str,'location','bestoutside')
end
xlabel('Periods');
axis([1 12 0 1]);

% %%%%%%%%%%%%%QUESTION 3%%%%%%%%%%%%%%%%
%plot a comparison between new strategy and equally weighted, max_sharpe
%ratio strategy.
figure(5)
compare(:,1)=dayvalue(:,2);
compare(:,2)=dayvalue(:,4);
compare(:,3)=portf_value{5};
q3=timeseries(compare(:,1:2),dates);
q4= timeseries(compare(:,3),dates);
q3.TimeInfo.Units = 'days';
q3.TimeInfo.Format = 'mmm dd, yy';
q4.TimeInfo.Units = 'days';
q4.TimeInfo.Format = 'mmm dd, yy';
plot(q3,'--');
hold on;
plot(q4,'-.')
legend('Equally Weighted Portfolio' , 'Maximum Sharpe Ratio Portfolio', 'Dynamic Portfolio')
date_frmt ='mmm dd, yy';
title('Comparison between Dynamic Portfolio and Others');
ylabel('Daily Portfolio Value (USD)');






