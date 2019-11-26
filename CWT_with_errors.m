% WORK IN PROGRESS

% Revision 1 31/10/2018 - DRAFT
% Try to estimate also the error associated to CWT map
% Following the analogy of a weighted mean, for cell i,j the associated
% Weighted sample variance can be estimated as described in 
% https://en.wikipedia.org/wiki/Weighted_arithmetic_mean#Weighted_sample_variance
% or 
% https://stackoverflow.com/questions/10049402/calculating-weighted-mean-and-standard-deviation
% where w_i (the weight) is tau (residence time), x_i is the isotopic
% composition measured for backtrajectory l, mu_star is C(i,j), V1 is
% sum(tau)

% Configuration
data_column = 18; % 


%% Associa valore composizione isotopica del vapore ad una determinata
% Revision 1 31/10/2018
load('btrj_120h_test.mat')

% convert measurement dates into MATLAB dates

WV_Dates_datenum = datetime(WV_Dates(:,1),WV_Dates(:,2),WV_Dates(:,3),WV_Dates(:,4),0,0);
delta_values = NaN(length(btrj),3);

for i=3:length(btrj)
    if ~isempty(btrj(i).data)
        % convert date of btrj in MATLAB datetime
        btrj_datenum =  datetime(btrj(i).data(1,3)+2000, btrj(i).data(1,4), btrj(i).data(1,5), btrj(i).data(1,6), 0, 0);
        % find the index of minimum indexe
        index_minimum = find(abs(hours(btrj_datenum - WV_Dates_datenum)) == min(abs(hours(btrj_datenum - WV_Dates_datenum))));
        % avoid multiple indexing
        if length(index_minimum)>1
            index_minimum = index_minimum(1);
        end
        % save_delta_values
        btrj(i).data(1,data_column) = WV_Data(index_minimum, 3); % save d-excess
    end
end

%% CWT
back_trajectories = btrj;
back_trajectories(1) = [];
back_trajectories(1) = [];
clearvars btrj;

% LOAD YOU BACK TRAJECTORIES FIRST
% e.g. back_trajectories_HYP_errors.mat


% Domain to perform CWT (it's processor consuming!!)
domainlat = [0 90];
domainlon = [-180 180];


latitude_vector = (0:1:90);
longitude_vector = (-180:1:180);
freq_map = zeros(size(latitude_vector, 2), size(longitude_vector, 2));


% Calculate frequency map
for i=3:size(back_trajectories, 2)
    if ~isempty(back_trajectories(i).data)
        for time_index=1:size(back_trajectories(1).data, 1)
            latitude = round(back_trajectories(i).data(time_index, 10), 0);
            longitude = round(back_trajectories(i).data(time_index, 11), 0);
            latitude_index = find(round(latitude_vector) == round(latitude));
            longitude_index = find(round(longitude_vector) == round(longitude));
            freq_map(latitude_index, longitude_index) = freq_map(latitude_index, longitude_index) + 1;
        end
    end
end
% Revision 1 31/10/2018 ----------------------------
% Calculate relative frequency map
rel_freq_map = freq_map./sum(sum(freq_map));
% --------------------------------------------------

CWT_map = freq_map; %Same dimensions of frequency map
CWT_map(:,:) = 0;
CWT_map_error = CWT_map;

% Convert domain range in index range
domainlat(1) = find(round(latitude_vector - domainlat(1), 0) == 0);
domainlat(2) = find(round(latitude_vector - domainlat(2), 0) == 0);
domainlon(1) = find(round(longitude_vector - domainlon(1), 0) == 0);
domainlon(2) = find(round(longitude_vector - domainlon(2), 0) == 0);
advance = 1;
tot_advance = (domainlat(2)-domainlat(1))*(domainlon(2)-domainlon(1));
for i=domainlat(1):domainlat(2)
    for j=domainlon(1):domainlon(2)
        if freq_map(i,j) ~= 0 % Avoid calculation for empty cells!
            for tau=1:size(back_trajectories, 2)
                if ~isempty(back_trajectories(tau).data)
                     lats = find(round(back_trajectories(tau).data(:,10), 0) == round(latitude_vector(i), 0));
                     end_points = 0;
                     if(size(lats, 1)~=0)
                         for omega=1:size(lats, 1)
                             if(round(back_trajectories(tau).data(lats(omega), 11), 0) == round(longitude_vector(j), 0))
                                 end_points = end_points + 1;
                             end
                         end
                     end
                     if size(back_trajectories(tau).data,2) > 22 % do the task only if the variable in position data_column exists!
                        CWT_map(i,j) = CWT_map(i,j) + (back_trajectories(tau).data(1, data_column)*end_points);
                     end
                end
            end
            CWT_map(i,j) = CWT_map(i,j)/freq_map(i,j);
            % Revision 1 31/10/2018 Try to estimate error -----------------
            k = 1;
            data_buffer = zeros(1000, 2); % buffer used to sto isotope data and estimate weighted sample variance for grid cell
            for tau=1:size(back_trajectories, 2) % first column weight, second column isotope data
                if ~isempty(back_trajectories(tau).data)
                    % Check if an endpoint of the 'tau' backtrajectory falls
                    % into the i,j cell
                    % it should exist at least one endpoint inside cell i,j!
                    if sum((round(back_trajectories(tau).data(:,10), 0) == round(latitude_vector(i), 0)) & (round(back_trajectories(tau).data(:, 11), 0) == round(longitude_vector(j), 0)))>0 
                        % how many endpoint of this back trajectory inside cell i,j?
                        num_endpoint_in_cell = sum((round(back_trajectories(tau).data(:,10), 0) == round(latitude_vector(i), 0)) & (round(back_trajectories(tau).data(:, 11), 0) == round(longitude_vector(j), 0)));                                            
                        data_buffer(k, 1) = num_endpoint_in_cell;
                        data_buffer(k, 2) = (back_trajectories(tau).data(1, data_column));
                        k = k + 1;
                    end
                end
            end
            % remove all zeros from data_buffer
            data_buffer(data_buffer==0) = nan;
            % calculate weighted sample variance
            CWT_map_error(i,j) = sqrt(nansum(data_buffer(:, 1).*(data_buffer(:, 2) - CWT_map(i,j)).^2)/nansum(data_buffer(:, 1)));
            % -------------------------------------------------------------
        end
        advance = advance + 1;
    end
    clc
    disp('(%)...')
    disp(100*advance/tot_advance)
end

clearvars advance tot_advance
