% Version 1-20190327 - Last update 27 Mar 2019
% Terrain height is added to PBLH when air parcel height is compared with
% mixing depth
% Version 1-20190225
% This function estimate the moisture uptakes along an HYSPLIT formatted
% back trajectory. An example back trajectory is given as follows:
% load('btrj_54h_test.mat').
% The function returns two vectors, with the same length of back
% trajectory, with attributed fraction below and above boundary layer 
% (UBPBLH and UAPBLH, respectively).
% How to use:
% [UBPBLH, UAPBLH] = moisture_uptake(btrj_data, btrj_height, btrj_terr_height, btrj_MIXDEPTH, blh_threshold, btrj_q, q_threshold, min_q, suppress_output)
% ******************* Parameters 
% btrj_data, the back trajectory matrix, which is by default a n*22 matrix,
%            where n is back trajectory age.
% btrj_height, trajectory height column
% btrj_terr_height, terrain height column
% btrj_MIXDEPTH, mixing layer depth i.e. planteray boundary layer height
%                PBLH column (default 20)
% blh_threshold, a threshold for accounting smal-scale variaiblity of the
%                marine BLH
% btrj_q, specific humidity column in HYSPLIT trajectory (default 19)
% q_threshold, only specific humidity variations greater (in absolute value)
%              than the threshold will be considered
% suppress_output, (0/1) if 0, some additional information are printed on
%                  console when the function is called
% ******************* End of Parameters

function [UBPBLH, UAPBLH] = moisture_uptake(btrj_data, btrj_height,...
                            btrj_terr_height, btrj_MIXDEPTH, blh_threshold,...
                            btrj_q, q_threshold, min_q, suppress_output)
    if suppress_output == 0
        tic
    end
    % Default parameters
    % blh_threshold = 1.5;    % Uncertainty of BLH (Sodeman et al. 2008 p.4; Pfahl and Wernli 2009).
    % q_threshold = 0.2;      % Specific humidity minimum variation in g/kg between time-steps (Sodeman et al. 2008)

    % Set variable definitions in a back trajectory structure (i.e.
    % with all the meteorological outputs along the back trajectory as default
    % option)
%     btrj_year = 3;
%     btrj_month = 4;
%     btrj_day = 5;
%     btrj_hour = 6;
%     btrj_age = 9;
%     btrj_lat = 10;
%     btrj_lon = 11;
%     btrj_height = 12;
%     btrj_press = 13;
%     btrj_theta = 14;
%     btrj_T = 15;
%     btrj_rainfall = 16;
%     btrj_MIXDEPTH = 17;
%     btrj_RH = 18;
%     btrj_q = 19;
%     btrj_H2OMIXRA = 20; 
%     btrj_terr_height = 21;
%     btrj_Sol_R = 22;
%     New Columns
%     btrj_WUPTK = 23;
%     btrj_WUPTK_OVERBLH = 24;

    % Add TWO new column to btrj structure
    btrj_data = horzcat(btrj_data, zeros(size(btrj_data, 1), 2));

    % ---------------------------------------------------------
    % Uptake_hystory matrix
    uptake_hystory = zeros(size(btrj_data, 1), 9);
    % uptake_hystory = single(uptake_hystory);

    % Column 1 q
    % Column 2 uptake unweighted (Delta_q_0)
    % Column 3 change in humidity weighted by the rain-out during transport(Delta_q)
    % Column 4 uptake above BLH,
    % Column 5 attributed fraction
    % Column 6 above BL uptake fraction
    % Column 7 total above-BLH uptake fracion - NOT IMPLEMENTED
    % Column 8 BTRJ HEIGHT AGL
    % Column 9 BLH
    % --------------------------------------------------------

    %% Check for specific humidity variation and estimate water vapor uptake

    % Save the specific humidity
    uptake_hystory(:, 1) = btrj_data(:, btrj_q);
    % Calculate humidity variation
    uptake_hystory(1:end-1, 2) = -diff(btrj_data(:, btrj_q));

    % Remove humidity variations lower than the humidity threshold
    uptake_hystory(find(abs(uptake_hystory(:,2))<q_threshold), 2) = 0;

    % 1 - Save back trajectory height and PBL height
    row = 1;
    % Estimate moisture uptakes until q is greater than 0.05 g/kg
    while uptake_hystory(row, 1)>min_q && row <= size(btrj_data, 1)-1
        % Save BTRJ HEIGHT and BLH
        uptake_hystory(row, 8) = (mean(btrj_data(row:row+1, btrj_height)) + mean(btrj_data(row:row+1, btrj_terr_height)));
%         uptake_hystory(row, 9) = blh_threshold * btrj_data(row+1,btrj_MIXDEPTH) + btrj_data(row+1,btrj_terr_height);
        uptake_hystory(row, 9) = (mean(blh_threshold * btrj_data(row:row+1, btrj_MIXDEPTH)) + mean(btrj_data(row:row+1, btrj_terr_height)));
        row = row + 1;
    end % End of humidity check inside the back trajectory
    % 2 - Clear moisture uptakes once humidity reach 0.05 g/kg
    if row < size(uptake_hystory, 1) && uptake_hystory(row, 1)<min_q
        uptake_hystory(row:size(btrj_data, 1), :) = 0;
    end

    %% Copy unweighted moisture increases to weighted moisture uptake column

    uptake_hystory(uptake_hystory(:,2)>0, 3) = uptake_hystory(uptake_hystory(:,2)>0,2);

    % Proceed forward in time
    row = size(btrj_data, 1); 
    while row > 0   
        % Calculate fractional contribution if uptake is air parcel height is
        % lower than BLH*threshold. For uptake, I assume that the variation of
        % specific humidity is positive
        if uptake_hystory(row, 8) < uptake_hystory(row, 9) && uptake_hystory(row, 2) > 0
            uptake_hystory(row, 5) = uptake_hystory(row, 3)/uptake_hystory(row, 1);
        end

        % Reduce contribution of precedent uptakes *************
        if uptake_hystory(row, 2) > q_threshold 
            for t=row:size(btrj_data, 1)
                    uptake_hystory(t, 5) = uptake_hystory(t, 3)/uptake_hystory(row, 1);
            end
        end
        % end of reduce contribution of precedent uptakes *****

        % Discount contribution of precedent uptakes by
        % pecipitation ++++++++++++++++++++++++++++++++++++++++
        if uptake_hystory(row, 2) <= q_threshold*-1 && row>1
            for t=row:size(btrj_data, 1)
                uptake_hystory(t, 3) = uptake_hystory(t, 3) + uptake_hystory(row, 2)*uptake_hystory(t, 5);
                if uptake_hystory(t, 4) ~= 0
                    uptake_hystory(t, 4) = uptake_hystory(t, 3) + uptake_hystory(row, 2)*uptake_hystory(t, 5);
                end
            end
        end
        % end of reduce contribution of precedent uptake by
        % pecipitation ++++++++++++++++++++++++++++++++++++++++

        row = row - 1;
    end

    % Move uptake fraction above BLH to another column
    for row=1:size(uptake_hystory, 1)
        if uptake_hystory(row, 8) > uptake_hystory(row, 9)
            uptake_hystory(row, 6) = uptake_hystory(row, 5);
            uptake_hystory(row, 5) = 0;
        end
    end
    
    %% Export data
    % Add attributed fraction to original btrj data matrix
    %btrj_data(:, btrj_WUPTK) = uptake_hystory(:,5);
    UBPBLH = uptake_hystory(:,5);

    % Add fraction above BLH to original btrj data matrix
    %btrj_data(:, btrj_WUPTK_OVERBLH) = uptake_hystory(:,6);
    UAPBLH = uptake_hystory(:,6);
    
    % Display some data on console
    if suppress_output == 0
        toc
        fprintf('Attributed fraction: %f %%\n', 100*sum(uptake_hystory(:,5)))
        fprintf('Fraction above BLH: %f %%\n', 100*sum(uptake_hystory(:,6)))
        if ~isempty(find(uptake_hystory(:,5)<0))
            fprintf('Negative fraction rows: %d\n', length(find(uptake_hystory(:,5)<0)))
            fprintf('Negative fraction: %f %%\n', 100*sum(uptake_hystory(find(uptake_hystory(:,5)<0),5)))
            pause
        end
        if sum(uptake_hystory(:,5)) + sum(uptake_hystory(:,6)) > 1
            fprintf('Total attributed fraction: %d\n', 100*(sum(uptake_hystory(:,5)) + sum(uptake_hystory(:,6))))
        end
    end
    
end    