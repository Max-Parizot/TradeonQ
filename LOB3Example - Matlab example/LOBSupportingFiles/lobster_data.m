function [MOBid, bid_volume, MOAsk, ask_volume, Time] = lobster_data(data1, data2)
    % Extract time from the first column of data1
    Time = data1(:, 1);

    % Assuming data2 is a MATLAB array
    [num_rows, num_cols] = size(data2);
    num_levels = num_cols / 4;

    % Reshape data2 to match the desired structure
    data_reshaped = reshape(data2, [num_rows, 4, num_levels]);

    % Permute dimensions for easy extraction
    data_reshaped = permute(data_reshaped, [1, 3, 2]);

    % Extract MOBid, bid_volume, MOAsk, and ask_volume from reshaped data
    MOAsk = data_reshaped(:, :, 1);  % Ask Price
    ask_volume = data_reshaped(:, :, 2);  % Ask Size 
    MOBid = data_reshaped(:, :, 3);  % Bid Price
    bid_volume = data_reshaped(:, :, 4);  % Bid Size
end

