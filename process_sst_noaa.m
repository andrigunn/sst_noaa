%% noaa_sst_processMaster

make_ts = 1  %0 to do nothring, 1 to remake all data 
make_nc = 1

addpath('/git/cdt');
addpath('/git/cdt/cdt_data');


% Load Lat and Lon for NOAA HiRes SST
load('/projects/sst_noaa/geo_noaa_hiRes_sst.mat');
geo.lat_noaa_sst = Lat;
geo.lon_noaa_sst = Lon;
%%
d = dir('/data/sst_noaa/sst.day.mean*.nc');
dall = d;

% Fjarlægjum ltm gögnin úr d
ix = contains({d.name},'ltm');
d(ix,:) = [];
% Fjarlægjum ltm gögnin úr dall
ix = contains({dall.name},'ltm');
dall(ix,:) = [];

%% Make daily data

switch make_ts
    case 1
        ik = 0;
        d = dall;
        for i = 1:length(d)
            fname = ['/data/sst_noaa/',d(i).name];
            time = ncread(fname,'time');
            time = datenum('01-Jan-1800','dd-mmm-yyyy')+ time;
            Time = array2table([time, datevec(time)],'VariableNames',{'daten','year','month','day','hh','mm','ss'});
            disp(d(i).name)
            lat = ncread(fname,'lat');
            lon = ncread(fname,'lon');
            sst = ncread(fname,'sst');

            sst(sst <-100)=nan;
            sst_ts = flipud(rot90(sst));
            x = size(sst);

            [mask_isl] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[70 60],[-10 -30]);
            msk = ~mask_isl; % Invert themask
            sst_isl = mask3(sst_ts,msk);

            [mask_sst_S] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[65 60],[-20 -30]);
            msk_S = ~mask_sst_S; % Invert themask
            sst_S = mask3(sst_ts,msk_S);

            [mask_sst_N] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[70 65],[-10 -20]);
            msk_N = ~mask_sst_N; % Invert themask
            sst_N = mask3(sst_ts,msk_N);

            [mask_sst_W] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[70 65],[-20 -30]);
            msk_W = ~mask_sst_W; % Invert themask
            sst_W = mask3(sst_ts,msk_W);

            [mask_sst_E] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[65 60],[-10 -20]);
            msk_E = ~mask_sst_E; % Invert themask
            sst_E = mask3(sst_ts,msk_E);

            % Cold blob epicenter is 53°N, 36°W from https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2019JC015379
            [mask_sst_cold_blob] = geomask(geo.lat_noaa_sst,geo.lon_noaa_sst,[56 50],[-33 -39]);
            msk_cold_blob = ~mask_sst_cold_blob; % Invert themask
            sst_cold_blob = mask3(sst_ts,msk_cold_blob);

            for it = 1:x(3)
                ik = ik+1;

                sst_island_ts.date(ik,1) = Time.daten(it);
                sst_island_ts.year(ik,1) = year(Time.daten(it));
                sst_island_ts.month(ik,1) = month(Time.daten(it));
                sst_island_ts.day(ik,1) = day(Time.daten(it));

                sst_island_ts.sst_isl(ik,1) = nanmean(nanmean(sst_isl(:,:,it)));
                sst_island_ts.sst_S(ik,1) = nanmean(nanmean(sst_S(:,:,it)));
                sst_island_ts.sst_N(ik,1) = nanmean(nanmean(sst_N(:,:,it)));
                sst_island_ts.sst_W(ik,1) = nanmean(nanmean(sst_W(:,:,it)));
                sst_island_ts.sst_E(ik,1) = nanmean(nanmean(sst_E(:,:,it)));
                sst_island_ts.sst_cold_blob(ik,1) = nanmean(nanmean(sst_cold_blob(:,:,it)));

            end

        end
        %
        SST = struct2table(sst_island_ts);;
        SST = table2timetable(SST,'RowTimes',datetime(SST.date,'ConvertFrom','datenum'));
        SSTM = retime(SST,'monthly')
        SSTMA = table();

        for i = 1:12

            ix = find((SSTM.Time.Month == i) & (SSTM.Time.Year >= 1990)&(SSTM.Time.Year <= 2020));
            ix2 = find(SSTM.Time.Month == i);

            mmean = mean(SSTM{ix,5:10},'omitnan');

            SSTMA(ix2,:) = splitvars(table(SSTM{ix2,5:10}-mmean));

        end

        SSTMA = table2timetable(SSTMA,'RowTimes',SSTM.Time);
        SSTMA.Properties.VariableNames = SST.Properties.VariableNames(5:10);

        % Make winter and summer mean
        SSTWinter = timetable();
        uqy = unique(SST.Time.Year)
        ik = 0;
        for i = 1:length(uqy)-1

            tr = timerange(datetime(uqy(i),10,01),datetime(uqy(i+1),04,01));
            ik = ik+1;
            %SSTWinter = ;
            SSTWinter = [SSTWinter;varfun(@mean, SST(tr,:), 'InputVariables', @isnumeric)]

        end
        SSTWinter = removevars(SSTWinter, ["mean_date","mean_year","mean_month","mean_day"]);

        SSTSummer = timetable();
        uqy = unique(SST.Time.Year);

        ik = 0;
        for i = 1:length(uqy)-1

            tr = timerange(datetime(uqy(i),05,01),datetime(uqy(i+1),09,01));
            ik = ik+1;

            SSTSummer = [SSTSummer;varfun(@mean, SST(tr,:), 'InputVariables', @isnumeric)]

        end
        SSTSummer = removevars(SSTSummer, ["mean_date","mean_year","mean_month","mean_day"]);

        cd('/projects/sst_noaa/daily_output')
        save('noaa_hiRes_sst.mat','SST','SSTMA','SSTM','SSTWinter',"SSTSummer")

    otherwise
end
%% Búum til vetrar og sumarmeðaltöl

%%
%d = dir(['sst.day','*.nc']);
% Make month mean of SST NOAA data
switch make_nc
    case 1
        for i = 1:length(d)
            time = ncread([d(i).folder,filesep,d(i).name],'time');
            time = datenum('01-Jan-1800','dd-mmm-yyyy')+ time;
            Time = array2table([time, datevec(time)],'VariableNames',{'daten','year','month','day','hh','mm','ss'});

            lat = ncread([d(i).folder,filesep,d(i).name],'lat');
            lon = ncread([d(i).folder,filesep,d(i).name],'lon');
            sst = ncread([d(i).folder,filesep,d(i).name],'sst');
            % sst= flipud(rot90(sst));

            uqm = unique([Time.month]);

            sst_annual_mean = nanmean(sst(:,:,:),3);
            Year = Time.year(1);

            data_date = datestr([Year,1,1,00,00,00],'yyyy')
            fname = ['sst.year.mean.',data_date ,'.nc'];
            %Delete NC file if it exists in the data write directory
            if exist(fname, 'file')==2;
                delete(fname);
            end
            disp(['Writing data to ', fname])
            nccreate(fname,'sst.year.mean','Dimensions', {'x',1440,'y',720});
            ncwrite(fname,'sst.year.mean',sst_annual_mean);

            for ii = 1:length(uqm)
                ix = find(Time.month == uqm(ii));
                sst_mean = nanmean(sst(:,:,ix),3);
                Year = Time.year(1);
                Month = uqm(ii);

                data_date = datestr([Year,Month,1,00,00,00],'yyyy.mm')
                fname = ['sst.month.mean.',data_date ,'.nc'];
                %Delete NC file if it exists in the data write directory
                if exist(fname, 'file')==2;
                    delete(fname);
                end
                disp(['Writing data to ', fname])
                nccreate(fname,'sst.month.mean','Dimensions', {'x',1440,'y',720});
                ncwrite(fname,'sst.month.mean',sst_mean);
            end
        end
        %% Make Winter mean
        d = dir(['sst.month','*.nc']);
        d = rmfield(d, {'date', 'bytes', 'isdir', 'datenum'});
        for i = 1:length(d)
            d(i).month = str2num(d(i).name(end-4:end-3));
            d(i).year = str2num(d(i).name(end-9:end-6));
        end
        %%
        uqm = unique([d.month]);
        uqy = unique([d.year]);
        clc
        for i = 1:length(uqy)%-1
            iyear = uqy(i);
            ix1 = find([d.year]==iyear & [d.month]==9 | [d.year]==iyear & [d.month]==10 | [d.year]==iyear & [d.month]==11 | [d.year]==iyear & [d.month]==12);
            ix2 = find([d.year]==iyear+1 & [d.month]==1 | [d.year]==iyear+1 & [d.month]==2 | [d.year]==iyear+1 & [d.month]==3 | [d.year]==iyear+1 & [d.month]==4);

            ix = [ix1,ix2];

            s = [];
            disp('##')
            disp('Reading data from:')
            for ii = 1:length(ix)
                sst(:,:,ii) = ncread(d(ix(ii)).name,'sst.month.mean');
                disp(d(ix(ii)).name)
            end
            sstMean = nanmean(sst,3);
            data_date = datestr([uqy(i),1,1,00,00,00],'yyyy');
            fname = ['sst.SONDJFMA.mean.',data_date ,'.nc'];
            % Delete NC file if it exists in the data write directory
            if exist(fname, 'file')==2;
                delete(fname);
            end
            disp(['Writing data to ', fname])
            nccreate(fname,'sst.SONDJFMA.mean','Dimensions', {'x',1440,'y',720});
            ncwrite(fname,'sst.SONDJFMA.mean',sstMean);

        end

        %% Make Summer mean
        for i = 1:length(uqy)%-1
            iyear = uqy(i);
            ix = find([d.year]==iyear & [d.month]==5 | [d.year]==iyear & [d.month]==6 | [d.year]==iyear & [d.month]==7 | [d.year]==iyear & [d.month]==8);

            s = [];
            disp('##')
            disp('Reading data from:')
            for ii = 1:length(ix)
                sst(:,:,ii) = ncread(d(ix(ii)).name,'sst.month.mean');
                disp(d(ix(ii)).name)
            end
            sstMean = nanmean(sst,3);
            data_date = datestr([uqy(i),1,1,00,00,00],'yyyy');
            fname = ['sst.MJJA.mean.',data_date ,'.nc'];
            % Delete NC file if it exists in the data write directory
            if exist(fname, 'file')==2;
                delete(fname);
            end
            disp(['Writing data to ', fname])
            nccreate(fname,'sst.MJJA.mean','Dimensions', {'x',1440,'y',720});
            ncwrite(fname,'sst.MJJA.mean',sstMean);

        end

    otherwise
end
