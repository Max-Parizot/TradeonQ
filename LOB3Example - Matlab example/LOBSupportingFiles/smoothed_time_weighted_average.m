function smoothed_data = smoothed_time_weighted_average(data,  window)
%this function assumes that the data is evenly distributed with time. the
%user will specify a certain amount of ticks for the function
% data - dependent variable for weighted average
% time - time vector
% window - N - length of window for tick

% Define exponential weights
x = 1:window;
weights = exp(-0.5 .* x);
weights = weights / sum(weights);  % Normalize weights to sum to 1
smoothed_data = conv(data, flip(weights), 'same');
end
