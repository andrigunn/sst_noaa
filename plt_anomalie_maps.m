%% 
addpath(genpath('/git/cdt'));

set(0,'defaultfigurepaperunits','centimeters');
set(0,'DefaultAxesFontSize',16)
set(0,'defaultfigurecolor','w');
set(0,'defaultfigureinverthardcopy','off');
set(0,'defaultfigurepaperorientation','landscape');
set(0,'defaultfigurepapersize',[35 21]);
set(0,'defaultfigurepaperposition',[.25 .25 [35 21]-0.5]);
set(0,'DefaultTextInterpreter','none');
set(0, 'DefaultFigureUnits', 'centimeters');
set(0, 'DefaultFigurePosition', [.25 .25 [35 21]-0.5]);

% Load Lat and Lon for NOAA HiRes SST
if ismac
    load(['/Volumes/data/projects/sst_noaa/geo_noaa_hiRes_sst.mat']);
    cd /Volumes//data/projects/sst_noaa/daily_output/
elseif isunix
    load(['/data/projects/sst_noaa/geo_noaa_hiRes_sst.mat']);
    cd /data/sst_noaa
end
geo.lat_noaa_sst = Lat;
geo.lon_noaa_sst = Lon;
%%
d = dir(['sst.MJJA.mean.*.nc']);
%%
for i = 1:length(d)
    c = strsplit([d(i).name],'.');
    d(i).year = str2num(char(c(end-1)));
end
%%

baseline_period = [datetime(1981,01,01),datetime(2010,12,31)];

% Find base years
ix = find(...
    ([d.year]>=baseline_period.Year(1)) &...
    ([d.year]<=baseline_period.Year(2)))

% Find ref year
reference_period = [datetime(2024,06,01),datetime(2024,06,30)];

ix_ref = find( ([d.year]==reference_period.Year(1)));

sst_baseperiod = [];

for i = 1:length(d(ix))
    fn = [d(ix(i)).folder,filesep,d(ix(i)).name]

    nc = ncread(fn,'sst.MJJA.mean');
    disp(d(ix(i)).name)
    sst_baseperiod = cat(3,sst_baseperiod,nc);
end
%%
    sst_baseperiod(sst_baseperiod <-100)=nan;
    sst_baseperiod = flipud(rot90(sst_baseperiod));  
%%
    fn = [d(ix_ref).folder,filesep,d(ix_ref).name]
    disp(d(ix_ref).name)
    sst_refperiod = ncread(fn,'sst.MJJA.mean');
%%
    sst_refperiod(sst_refperiod <-100)=nan;
    sst_refperiod = flipud(rot90(sst_refperiod));  
%%
sst_baseperiod_mean = mean(sst_baseperiod,3,'omitmissing');
%%
    figure,
    axesm('MapProjection','mercator','MapLatLimit',[40 75],'MapLonLimit',[-60 40] ,'PLineLocation', 5, 'MLineLocation',10);
    hold on 
    pcolorm(double(Lat),double(Lon),sst_refperiod-sst_baseperiod_mean);
    axis off; framem on; gridm on;
    plabel('on')
    mlabel('on')
    clim([-0.1,0.1])
    bordersm('countries','k')
    cmocean('balance','pivot',0)
    cb = colorbar
    ylabel(cb,'Frávik sjávarhita (°C)','FontSize',16,'Rotation',270)

    title(['Frávik sjávarhita - Sumar 2024 - Viðmið 2000-2020' ])

    if ismac
        cd '/Users/andrigun/Dropbox/01-Projects/samantekt_afkomu/2023-24/'
        exportgraphics(gcf,'sst_mjja_anomap_2024.jpg');
        exportgraphics(gcf,'sst_mjja_anomap_2024.pdf');
    else
        cd '/projects/sst_noaa/daily_output'
        exportgraphics(gcf,'sst_mjja_anomap_2024.jpg');
        exportgraphics(gcf,'sst_mjja_anomap_2024.pdf');
    end








