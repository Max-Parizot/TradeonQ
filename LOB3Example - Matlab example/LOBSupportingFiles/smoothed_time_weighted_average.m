function twa = smoothed_time_weighted_average(data,  window)
%this function assumes that the data is evenly distributed with time. the
%user will specify a certain amount of ticks for the function

% data - dependent variable for weighted average
% time - time vector
% window - N - length of window for tick

% Define exponential weights
x = 1:window;
weights = exp(-0.5 .* x);

% Initialize smoothed_data variable
smoothed_data = NaN(size(data));
smoothed_data(1:window) = data(1:window);

% Iterate over each time point

for i = (window+1):length(data)
% Calculate the dot product of weights with a subset of data
        smoothed_data(i) = dot(weights,data( (i-window+1):i)) / sum(weights);  

    % Check if the current time point is within the specified window
end
% Output the smoothed time-weighted average
twa = smoothed_data;

end
