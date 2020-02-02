% ###################################################################
% #Script Name: calculate_backtraj.m
% #Description: Calculate 1 month of backtrajectories with 6hr time step resolution using
% #             HYSPLIT for moisture sources detection. The script requires monthly
% #             meteorological data in .ARL format (eg. Reanalysis II)
% #Args:        year and month of interest (eg. Feb.1997)
% #Output:      HYSPLIT output file...
% #Author:      Daniele Z.
% #Email:       daniele.zannoni@unive.it
% #Notes:       ALWAYS use
% #             trajectory output name with the following rule:
% #             meteodataset_hoursbackward_YYYYMMDD_HHmm
% #             e.g.: ERA5_240h_20050412_1200
% ###################################################################

%% Configuration 
% Date and time configuration ---------------------------------------------
% Variables required for scripting
if ~exist('year_to_calculate', 'var');year_to_calculate = 1997;end % YEAR OF INTEREST
if ~exist('month_to_calculate', 'var');month_to_calculate = 2;end % MONTH OF INTEREST

% Starting point configuration --------------------------------------------
starting_coordinates = [45 12 500; 
                        46 12 500; 
                        35 10 250]; % Example                   
% Otherwise you can load a list of starting points which contains 
% "starting_coordinates variable (lat (d.dd) lon(d.dd) altitude (mAGL))
% load('your_starting_coordinates.mat') % 
%                                       % points

% Back trajectories configuration -----------------------------------------
time_back = '-240'; % Define number of backward hours
model_type = '0'; % Use meteorological model data
max_height = '10000'; % Maximum air parcel height
working_path = "C:\hysplit4\working\"; % HYSPLIT working directory
trj_calc_sw = ".\hyts_std.exe"; % HYSPLIT executable (you can also make a copy/link of the exe in the working directory)
trj_control_file = "CONTROL"; % CONTROL filename
trj_cfg_file = "SETUP.CFG"; % Trajectory configuration filename (default SETUP.CFG)
output_file_directory = 'OUTPUT\';
output_file_prefix = 'REAN25_240h_';

% Meteo files configuration
meteo_file_directory = 'REAN25_240h_\';
meteo_file_extension = '.ARL'; % e.g. '.ARL' for 2000_01.ARL
% Take a look inside section "Define meteorological files required" for 
% understanding how meteo file names are formatted. It current version,
% meteo file name is printed as follows '%04d_%02d'

% Additional configuration ------------------------------------------------
disp_MSG = 1; % Display status prompt
disp_HY_ouptut = 0; % Display HYSPLIT prompt
% Time step between endpoints, don't change
hour_step = 6;

%% Setup of the date/time and locacation for calculation of trajectories
% Starting point setup
num_trj = sprintf('%d', size(starting_coordinates, 1)); % Define number of trajectory per run of the model
% Date and time setup
num_days_per_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
% Check if the year_to_calculate is a leap year
day_flag = day(datetime(year_to_calculate, 2, 28, 0, 0, 0) + days(1));
if day_flag == 29
    num_days_per_month(2) = 29; % leap year
else
    num_days_per_month(2) = 28; % non-leap year
end
% Prepare a datetime list
date_list = NaT(num_days_per_month(month_to_calculate)*24/hour_step, 1);
date_list(1) = datetime(year_to_calculate, month_to_calculate, 1, 0, 0, 0);
for i=2:num_days_per_month(month_to_calculate)*24/hour_step
    date_list(i) = date_list(i-1) + 1/(24/hour_step)*days(1);
end
% Convert the datetime list to a char list
starting_date = repmat("template", size(date_list, 1), 1);
for i=1:length(date_list)
    if year(date_list(i))-2000 >= 0
        starting_year = year(date_list(i))-2000;
    else
        starting_year = year(date_list(i))-1900;
    end
    starting_month = month(date_list(i));
    starting_day = day(date_list(i));
    starting_hour = hour(date_list(i));
    starting_date(i)=sprintf( '%02d %02d %02d %02d', starting_year, starting_month, starting_day, starting_hour);
end
%% Define which are the meteorological files required
month_required = [0 0];
month_required(2) = month_to_calculate;
year_required = [0 0];
year_required(2) = year_to_calculate;
if month_required(2) == 1
    month_required(1) = 12;
    year_required(1) = year_required(2)-1;
else
    month_required(1) = month_required(2)-1;
    year_required(1) = year_required(2);
end
meteofilename = ["template", "template"];
meteofilename(1) = strcat(sprintf('%04d_%02d', year_required(1), month_required(1)),meteo_file_extension);
meteofilename(2) = strcat(sprintf('%04d_%02d', year_required(2), month_required(2)),meteo_file_extension);
%% Default TRAJ.CFG
% Save all meteorological variables along back trajectories
fileID = fopen(strcat(working_path,trj_cfg_file),'w');
fprintf(fileID, ' &SETUP\n');
fprintf(fileID, ' tratio = 0.75,\n');
fprintf(fileID, ' mgmin = 10,\n');
fprintf(fileID, ' khmax = 9999,\n');
fprintf(fileID, ' kmixd = 0,\n');
fprintf(fileID, ' kmsl = 0,\n');
fprintf(fileID, ' nstr = 0,\n');
fprintf(fileID, ' mhrs = 9999,\n');
fprintf(fileID, ' nver = 0,\n');
fprintf(fileID, ' tout = 60,\n');
fprintf(fileID, ' tm_tpot = 1,\n');
fprintf(fileID, ' tm_tamb = 1,\n');
fprintf(fileID, ' tm_rain = 1,\n');
fprintf(fileID, ' tm_mixd = 1,\n');
fprintf(fileID, ' tm_relh = 1,\n');
fprintf(fileID, ' tm_sphu = 1,\n');
fprintf(fileID, ' tm_mixr = 1,\n');
fprintf(fileID, ' tm_dswf = 1,\n');
fprintf(fileID, ' tm_terr = 1,\n');
fprintf(fileID, ' dxf = 1.0,\n');
fprintf(fileID, ' dyf = 1.0,\n');
fprintf(fileID, ' dzf = 0.01,\n');
fprintf(fileID, ' /\n');
fprintf(fileID, '');
fclose(fileID);

%% Display status message?
n_runs = length(date_list);
if disp_MSG
    clc
    fprintf('A total number of %d trajectories be calculated\n', n_runs*size(starting_coordinates, 1));
    fprintf('HYSPLIT will be executed %d times\n', n_runs);
    fprintf('Trajectories will be stored in: %s\n', output_file_directory);
    fprintf('Press any key to continue....\n')
    pause(2);
end

%% Start HYSPLIT
for curr_run=1:n_runs
    % Display status message?
    if disp_MSG
        clc
        curr_date = starting_date(curr_run).char;
        fprintf('Current date time: %s\n', curr_date)
        status_percentage(curr_run, n_runs);
    end
    
    % Write CONTROL file
    fileID = fopen(strcat(working_path,trj_control_file),'w');
    fprintf(fileID, char(starting_date(curr_run))); % Starting date
    fprintf(fileID, '\n');
    fprintf(fileID, num_trj); % Number of trajectories to calculate
    fprintf(fileID, '\n');
    for i=1:size(starting_coordinates, 1)
        fprintf(fileID, '%.1f %.1f %d', starting_coordinates(i, 1:3)); % Starting position
        fprintf(fileID, '\n');
    end  
    fprintf(fileID, time_back); % Number of simulation hours backward
    fprintf(fileID, '\n');
    fprintf(fileID, model_type); % Use meteorological model
    fprintf(fileID, '\n');
    fprintf(fileID, max_height); % Max height of air parcel
    fprintf(fileID, '\n');
    fprintf(fileID, '%d', size(meteofilename, 2)); % Total number of meteorological files
    fprintf(fileID, '\n');
    for meteo_file_index=1:size(meteofilename, 2)
        fprintf(fileID, strcat(working_path, meteo_file_directory)); % Meteo File Directory
        fprintf(fileID, '\n');      
        fprintf(fileID, char(meteofilename(meteo_file_index))); % Meteo file name
        fprintf(fileID, '\n');
    end
    fprintf(fileID, strcat(working_path, output_file_directory)); % Trajectory output directory
    fprintf(fileID, '\n'); 
    % Prepare filename_string
    txt_1 = sprintf('%04d%02d%02d_%02d00', year(date_list(curr_run)), month(date_list(curr_run)), day(date_list(curr_run)), hour(date_list(curr_run)));
    output_name = strcat(output_file_prefix, txt_1);
    fprintf(fileID, output_name); % Trajectory output filename
    fprintf(fileID, '\n'); % Terminate with a space
    fclose(fileID); % Close CONTROL file
    
    % Exectute HYSPLIT
    % Launch HYSPLIT with command 
    command = char(trj_calc_sw);
    [status,cmdout] = system(command); 

      % Display HYSPLIT status?
      if disp_HY_ouptut
            disp(cmdout);
      end
end