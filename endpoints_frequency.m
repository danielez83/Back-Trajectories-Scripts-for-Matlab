% Version 1-20191126 - Last update 26 Nov 2019
% Calculate frequency of trajectory endpoints per map unit and display on map
% Input: btrj structure, see "btrj_120h_test.mat"

% -------------------------------------------------------------------------
% Configuration
load('btrj_120h_test.mat') % test file with backtrajectories
load('dummy_jet.mat') % dummy color palette

resolution = 1; % Resolution of the map. 
                % Use only 1 or 0.1.
                % i.e. uptakes are itegrated per cell unit
                % e.g. 1° -> 1°x 1° roughly 10000 km^2
                % e.g. 0.1° -> 0.1°x 0.1° roughly 100000 km^2
max_time_back = 120; % Set how many hours back the computation of moisture 
                     % sources will go. Note that the maximum limits is the
                     % backward hours in back trajectory files.        
sigma_level = 1; % sigma level for gaussian filter

period_of_interest = [201 length(btrj)]; % Use whole dataset or subset data
% -------------------------------------------------------------------------

% Huge matrix with uptakes
frequency_map = zeros(90/resolution, 360/resolution);
latitude_vector = (90-resolution:-resolution:0)';
longitude_vector = (-180:resolution:180-resolution);

% Set resolution variable
switch resolution
    case 0.1
        round_to = 1;
    case 1
        round_to = 0;
    otherwise
        disp('Resolution not allowed')
end

tot_endpoints = 0; % Reset total number of endpoints on the map
for btrj_index=period_of_interest(1):period_of_interest(2)%length(btrj) 
    if ~isempty(btrj(btrj_index).data) % check only backtrajectories
        for hours_back_index=1:max_time_back
            lat_btrj = round(btrj(btrj_index).data(hours_back_index, 10), round_to);
            lon_btrj = round(btrj(btrj_index).data(hours_back_index, 11), round_to);
            lat_index = find(round(latitude_vector, round_to) == lat_btrj);
            lon_index = find(round(longitude_vector, round_to) == lon_btrj);
            frequency_map(lat_index, lon_index) = frequency_map(lat_index, lon_index) + 1;
            tot_endpoints = tot_endpoints + 1;
        end
        clc
        disp(100*(btrj_index-diff(period_of_interest)+1)/diff(period_of_interest))
    end
end
frequency_map = 100*frequency_map/tot_endpoints;
frequency_map_smoothed = imgaussfilt(frequency_map, sigma_level); % 1 Standard deviation for gaussian blur
frequency_map_smoothed(frequency_map_smoothed==0) = NaN;

%% Interpolate data
newpoints = 1000;
[xq,yq] = meshgrid(...
            linspace(min(min(longitude_vector,[],2)),max(max(longitude_vector,[],2)),newpoints ),...
            linspace(min(min(latitude_vector,[],1)),max(max(latitude_vector,[],1)),newpoints )...
          );
BDmatrixq = interp2(longitude_vector,latitude_vector,frequency_map_smoothed,xq,yq,'cubic');
% [c,h]=contourf(xq,yq,BDmatrixq);
BDmatrixq_nosmall = BDmatrixq;
BDmatrixq_nosmall(BDmatrixq_nosmall<0) = 0;

%% Construct a Globe Display
grs80 = referenceEllipsoid('grs80','km');
% fig = figure('Renderer','opengl')
gcf;
clf('reset');
ax = axesm('globe','Geoid',grs80,'Grid','on', ...
    'GLineWidth',1,'GLineStyle','--',...
    'Gcolor',[0.5 0.5 0.5],'Galtitude',100);
ax.Position = [0 0 1 1];
axis equal off


%% Add Various Global Map Data
land = shaperead('landareas','UseGeoCoords',true);
plotm([land.Lat],[land.Lon],'Color','black')

%% Display
% figure;
Latitude = 45.00;
Longitude = 12.00;
% display white background
geoshow(yq,xq, zeros(size(BDmatrixq)),'DisplayType','texturemap');
geoshow(yq,xq, BDmatrixq_nosmall,'DisplayType','surface');
% contourfm(yq,xq, BDmatrixq, 50, 'LevelList', [0.1:0.2:2]);

colormap(asd_jet)

% Display Svalbard Position
geoshow(Latitude, Longitude, 'DisplayType','Point', 'Marker', 'X', 'Color', 'white', 'Markersize',20, 'LineWidth',1.2)

%% Display world map
S = shaperead('landareas','UseGeoCoords',true);
geoshow([S.Lat], [S.Lon],'Color','black', 'LineWidth', 1);
colb.Location = 'southoutside';
colb.FontSize = 10;
colb.FontWeight = 'bold';
gm = gridm;
gm(1).Color = [.8 .8 .8];
gm(1).Visible = 'on';
gm(1).LineStyle = '--';
gm(2).Color = gm(1).Color;
gm(2).Visible = gm(1).Visible;
gm(2).LineStyle = gm(1).LineStyle;

%% Camera settings
set(gca,'CameraViewAngle',3)
view(100, 60)

%% Display settings
set(gcf, 'Color', [1 1 1]);
colorbar('eastoutside')
caxis([0 3])

