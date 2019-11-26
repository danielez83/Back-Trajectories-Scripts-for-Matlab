% Version 1-20191126 - Last update 26 Nov 2019
% This script import an ensamble of backtrajectories started at different
% heights
% *************************************************************************
% STEP A, select back trajectories path (directory)
% The script will determine filenames and numbers of backtrajectories
% ------------------------------------------------------------------------
btrj_path = 'C:\hysplit4\working\OUTPUT\';

% Make a list of back trajectories inside folder. 
btrj_file_names = dir(btrj_path);
file_list_size = size(btrj_file_names);

% *************************************************************************
%% STEP B
% ------------------------------------------------------------------------
% header_lines = 11; % Lines of text to skip
display_progress = 'yes'; % 'yes' or 'no'
delimiterIn = ' '; % Delimiter (space)
% headerlinesIn = header_lines;
% ------------------------------------------------------------------------
% Set variable definitions in back trajectory structure
variables_name = {'Label' 'MetGrid' 'Yr' 'Mn' 'Dy' 'Hr' 'Mn' 'For_Hour' 'Age' 'Lat'...
                'Lon' 'Height' 'Press' 'Theta' 'Air_Temp' 'Rainfall' 'PBLH' 'RH' 'SpecHum'...
                'MixRatio' 'Terr_MSL' 'Sun_Flux'};
btrj_index = 1;
file_index = 1;
btrj = struct('data',[]);
for i=1:length(btrj_file_names)
    if btrj_file_names(i).isdir ~= 1
        % Detect number of meteorological files
        fid = fopen(strcat(btrj_path, btrj_file_names(i).name), 'rt');
        tline = fgetl(fid);
        numgrid = sscanf(tline, '%f', 1);
        for gridnum = 1 : numgrid
          tline = fgetl(fid);  %read and discard
        end
        % Detect number of starting points
        tline = fgetl(fid);
        numtraj = sscanf(tline, '%f', 1);
        for trajnum = 1 : numtraj
          tline = fgetl(fid);  %read and discard
        end
        % Detect number of meteorological variables along trajectory
        tline = fgetl(fid);
        num_meteo_vars = sscanf(tline, '%f', 1);
        fclose(fid);
        
        % Number of text lines to skip for import trajectory file
        headerlinesIn = numgrid + numtraj + 3;
        
        curr_file_name = strcat(btrj_path, btrj_file_names(i).name);
        btrj_buff = importdata(curr_file_name, delimiterIn, headerlinesIn);
        % Separate multiple back trajectories into single back trajectories
        for j=btrj_buff.data(1,1):numtraj
            btrj(btrj_index).data = btrj_buff.data(btrj_buff.data(:,1)==j,:);
            btrj_index = btrj_index + 1;
        end
    end
    if strcmp(display_progress, 'yes')
        clc
        fprintf('Status: %0.2f%%\n', 100*i/length(btrj_file_names));
    end
end

clearvars -except btrj variables_name