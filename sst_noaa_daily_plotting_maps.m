%% noaa_sst_processMaster
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
    cd /Volumes//data/sst_noaa
elseif isunix
    load(['/data/projects/sst_noaa/geo_noaa_hiRes_sst.mat']);
    cd /data/sst_noaa
end
geo.lat_noaa_sst = Lat;
geo.lon_noaa_sst = Lon;
%%
now_time = datetime('now');
now_year = now_time.Year;

d = dir(['sst.day.mean.',num2str(now_year),'.nc']);

%% Make newest day 

    i = 1;
    fname = [d(i).name];
    time = ncread(fname,'time');
    time = datenum('01-Jan-1800','dd-mmm-yyyy')+ time;
    Time = array2table([time, datevec(time)],'VariableNames',{'daten','year','month','day','hh','mm','ss'});
    
    lat = ncread(fname,'lat');
    lon = ncread(fname,'lon');
    sst = ncread(fname,'sst');
%%
    sst(sst <-100)=nan;
    sst = flipud(rot90(sst));  
%%
    sst_today = sst(:,:,end);
    time_today = datetime(table2array(Time(end,1)),'ConvertFrom','datenum');

    axesm('MapProjection','mercator','MapLatLimit',[40 75],'MapLonLimit',[-60 40] ,'PLineLocation', 5, 'MLineLocation',10);
    hold on 
    pcolorm(double(Lat),double(Lon),sst_today);
    axis off; framem on; gridm on;
    plabel('on')
    mlabel('on')
    clim([0,25])
    bordersm('countries','k')
    cmocean('thermal')
    cb = colorbar
    ylabel(cb,'Sjávarhiti (°C)','FontSize',16,'Rotation',270)

    title(['Sjávarhiti fyrir ',datestr(time_today)])
    if ismac
        
    else
        cd '/projects/sst_noaa/daily_output'
        exportgraphics(gcf,'sst_daily_today_map.jpg');
        exportgraphics(gcf,'sst_daily_today_map.pdf');
    end

%% Make the daily anomaly
    if ismac
        d = dir('/Volumes/data/sst_noaa/sst.day.mean.ltm.1991-2020.nc')
    else
        d = dir('/data/sst_noaa/sst.day.mean.ltm.1991-2020.nc')
    end

    fname = [d(i).folder,filesep,d(i).name];
    time = ncread(fname,'time');
    time = datenum('01-Jan-1800','dd-mmm-yyyy')+ time;
    Time = array2table([time, datevec(time)],'VariableNames',{'daten','year','month','day','hh','mm','ss'});
    
    lat = ncread(fname,'lat');
    lon = ncread(fname,'lon');
    sst_ltm_1991_2020 = ncread(fname,'sst');
%% Find the reference time

time_ref = datetime(table2array(Time(:,1)),'ConvertFrom','datenum');

ix = find((time_today.Month==time_ref.Month)&...
    (time_today.Day==time_ref.Day));

time_ltm = time_ref(ix);
sst_ltm = double(sst_ltm_1991_2020(:,:,ix));

sst_ltm(sst_ltm <-100)=nan;
sst_ltm = flipud(rot90(sst_ltm));  

sst_today_anomaly = sst_today-sst_ltm;

 axesm('MapProjection','mercator','MapLatLimit',[40 75],'MapLonLimit',[-60 40] ,'PLineLocation', 5, 'MLineLocation',10);
    hold on 
    pcolorm(double(Lat),double(Lon),sst_today_anomaly);
    axis off; framem on; gridm on;
    plabel('on')
    mlabel('on')
    clim([-5,5])
    bordersm('countries','k')
    cmocean('balance','pivot',0)
    cb = colorbar
    ylabel(cb,'Frávik sjávarhita (°C) (1991-2020)','FontSize',16,'Rotation',270)
    
    title(['Frávik sjávarhita fyrir ',datestr(time_today)])

    if ismac
        
    else
        cd '/projects/sst_noaa/daily_output'
        exportgraphics(gcf,'sst_daily_today_map_anomaly.jpg');
        exportgraphics(gcf,'sst_daily_today_map_anomaly.pdf');
    end

