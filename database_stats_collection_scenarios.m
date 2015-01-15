%DATABASE_STATS_COLLECTION_SCENARIOS Script used in generating numerical
%results of [1, Section IV-B] 
%
%   Reference: [1] Will Dynamic Spectrum Access Drain my Battery?

%   Code development: 

%   Last update: 28 July 2014

%   This work is licensed under a Creative Commons Attribution 3.0 Unported
%   License. Link to license: http://creativecommons.org/licenses/by/3.0/

tic;
clear all;
close all;
clc;

%Switch which database you want to query
google_test=1; %Query Google database
microsoft_test=1; %Query Microsoft database
spectrumbridge_test=1; %Query spectrumBridge database

%%
%Create legend for the figures
legend_string={'Google','MSR','SpectrumBridge'};
legend_flag=[google_test,microsoft_test,spectrumbridge_test];
legend_string(find(~legend_flag))=[];

%%
%Select which scenario to test
message_size_distribution=0;
response_error_calculation=0;
delay_distribution_per_location=0;
delay_distribution_area=1;

%%
%Plot parameters
ftsz=16;

%%
%Path to save files (select your own)
my_path='/Users/przemek/Documents/Research/Research experiments and papers/White Space Databases/SVN/analysis/Matlab/WSDB access/WSDB responses';

%%
%General querying parameters

%Global Microsoft parameters (refer to http://whitespaces.msresearch.us/api.html)
PropagationModel='"Rice"';
CullingThreshold='-114'; %In dBm
IncludeNonLicensed='true';
IncludeMicrophones='true';
UseSRTM='false';
UseGLOBE='true';
UseLRBCast='true';

%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height='30.0'; %In meters; Note: 'height' needs decimal value
agl='"AMSL"';

%Global SpectrumBridge parameters (refer to WSDB_TVBD_Interface_v1.0.pdf [provided by Peter Stanforth])
AntennaHeight='30'; %In meters; Ignored for personal/portable devices
DeviceType='3'; %Examples: 8-Fixed, 3-40 mW Mode II personal/portable; 4-100 mW Mode II personal/portable

if message_size_distribution==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LA'; %Los Aneles, CA, USA (Wilshire Blvd 1) [downtown]
    WSDB_data{1}.latitude='34.047955';
    WSDB_data{1}.longitude='-118.256013';
    WSDB_data{1}.delay_microsoft=[];
    WSDB_data{1}.delay_google=[];
    
    %Query finish location
    WSDB_data{2}.name='CB'; %Carolina Beach, NC, USA [ocean coast]
    WSDB_data{2}.latitude='34.047955';
    WSDB_data{2}.longitude='-77.885639';
    WSDB_data{2}.delay_microsoft=[];
    WSDB_data{2}.delay_google=[];
    
    longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
    longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory
    
    longitude_interval=100;
    longitude_step=(longitude_end-longitude_start)/longitude_interval;
    
    delay_google=[];
    delay_microsoft=[];
    delay_spectrumbridge=[];
    
    in=0; %Initialize request number counter
    %Initialize Google API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Google API console to check how many queries are used already]
    ggl_cnt=0;
    
    for xx=longitude_start:longitude_step:longitude_end
        in=in+1;
        fprintf('Query no.: %d\n',in)
        
        %Fetch location data
        latitude=WSDB_data{1}.latitude;
        longitude=num2str(xx);
        
        instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
        if google_test==1
            %Query Google
            ggl_cnt=ggl_cnt+1;
            instant_clock=clock; %Start clock again if scanning only one database
            cd([my_path,'/google']);
            [msg_google,delay_google_tmp,error_google_tmp]=...
                database_connect_google(type,latitude,longitude,height,agl,...
                [my_path,'/google'],ggl_cnt);
            var_name=(['google_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
            fprintf('Google\n');
            if error_google_tmp==0
                dlmwrite([var_name,'.txt'],msg_google,'');
                delay_google=[delay_google,delay_google_tmp];
            end
        end
        if microsoft_test==1
            %Query Microsoft
            instant_clock=clock; %Start clock again if scanning only one database
            cd([my_path,'/microsoft']);
            [msg_microsoft,delay_microsoft_tmp,error_microsoft_tmp]=...
                database_connect_microsoft(longitude,latitude,PropagationModel,...
                CullingThreshold,IncludeNonLicensed,IncludeMicrophones,...
                UseSRTM,UseGLOBE,UseLRBCast,[my_path,'/microsoft']);
            var_name=(['microsoft_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
            fprintf('Microsoft\n')
            if error_microsoft_tmp==0
                dlmwrite([var_name,'.txt'],msg_microsoft,'');
                delay_microsoft=[delay_microsoft,delay_microsoft_tmp];
            end
        end
        if spectrumbridge_test==1
            %Query SpectrumBridge
            instant_clock=clock; %Start clock again if scanning only one database
            cd([my_path,'/spectrumbridge']);
            delay_spectrumbridge_tmp_r=0;
            if DeviceType=='8'
                [msg_spectrumbridge,delay_spectrumbridge_tmp_r]=database_connect_spectrumbridge_register(...
                    AntennaHeight,DeviceType,Latitude,Longitude,[my_path,'/spectrumbridge']);
            end
            [msg_spectrumbridge,delay_spectrumbridge_tmp,error_spectrumbridge_tmp]=...
                database_connect_spectrumbridge(DeviceType,latitude,longitude);
            var_name=(['spectrumbridge_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
            fprintf('SpectrumBridge\n')
            if error_spectrumbridge_tmp==0
                dlmwrite([var_name,'.txt'],msg_spectrumbridge,'');
                delay_spectrumbridge_tmp=delay_spectrumbridge_tmp+delay_spectrumbridge_tmp_r;
                delay_spectrumbridge=[delay_spectrumbridge,delay_spectrumbridge_tmp];
            end
        end
    end
    if google_test==1
        %Clear old query results
        cd([my_path,'/google']);
        %Message size distribution (Google)
        list_dir=dir;
        [rowb,colb]=size({list_dir.bytes});
        google_resp_size=[];
        for x=4:colb
            google_resp_size=[google_resp_size,list_dir(x).bytes];
        end
        %system('rm *');
        
    end
    if microsoft_test==1
        %Clear old query results
        cd([my_path,'/microsoft']);
        
        %Message size distribution (Microsoft)
        list_dir=dir;
        [rowb,colb]=size({list_dir.bytes});
        microsoft_resp_size=[];
        for x=4:colb
            microsoft_resp_size=[microsoft_resp_size,list_dir(x).bytes];
        end
        %system('rm *');
        
    end
    if spectrumbridge_test==1
        %Clear old query results
        cd([my_path,'/spectrumbridge']);
        
        %Message size distribution (SpectrumBridge)
        list_dir=dir;
        [rowb,colb]=size({list_dir.bytes});
        spectrumbridge_resp_size=[];
        for x=4:colb
            spectrumbridge_resp_size=[spectrumbridge_resp_size,list_dir(x).bytes];
        end
        %system('rm *');
        
    end
    
    %%
    %Plot figure
    if google_test==1
        figure('Position',[440 378 560 420/3]);
        [fg,xg]=ksdensity(google_resp_size,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,'g-');
        grid on;
        box on;
        hold on;
        set(gca,'FontSize',ftsz);
        xlabel('Message size (bytes)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
    end
    if microsoft_test==1
        %figure('Position',[440 378 560 420/2]);
        [fm,xm]=ksdensity(microsoft_resp_size,'support','positive');
        fm=fm./sum(fm);
        plot(xm,fm,'b--');
        grid on;
        box on;
        hold on;
        set(gca,'FontSize',ftsz);
        xlabel('Message size (bytes)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
    end
    if spectrumbridge_test==1
        %figure('Position',[440 378 560 420/2]);
        [fs,xs]=ksdensity(spectrumbridge_resp_size,'support','positive');
        fs=fs./sum(fs);
        plot(xs,fs,'k-.');
        grid on;
        box on;
        hold on;
        set(gca,'FontSize',ftsz);
        xlabel('Message size (bytes)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
    end
    %Add common legend
    legend(legend_string);
    
    %%
    %Calculate statistics of message sizes for each WSDB
    
    %Mean
    mean_spectrumbridge_resp_size=mean(spectrumbridge_resp_size)
    mean_microsoft_resp_size=mean(microsoft_resp_size)
    mean_google_resp_size=mean(google_resp_size)
    
    %Variance
    var_spectrumbridge_resp_size=var(spectrumbridge_resp_size)
    var_microsoft_resp_size=var(microsoft_resp_size)
    var_google_resp_size=var(google_resp_size)
    
end
if response_error_calculation==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LA'; %Los Aneles, CA, USA (Wilshire Blvd 1) [downtown]
    WSDB_data{1}.latitude='34.047955';
    WSDB_data{1}.longitude='-118.256013';
    WSDB_data{1}.delay_microsoft=[];
    WSDB_data{1}.delay_google=[];
    
    %Query finish location
    WSDB_data{2}.name='CB'; %Carolina Beach, NC, USA [ocean coast]
    WSDB_data{2}.latitude='34.047955';
    WSDB_data{2}.longitude='-77.885639';
    WSDB_data{2}.delay_microsoft=[];
    WSDB_data{2}.delay_google=[];
    
    number_queries=100;
    number_batches=20;
    
    %Initialize error counter vectors
    error_google_vec=[];
    error_microsoft_vec=[];
    error_spectrumbridge_vec=[];
    
    %Initialize Google API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Google API console to check how many queries are used already]
    ggl_cnt=0;
    
    for bb=1:number_batches
        %Initialize error counters
        error_google=0;
        error_microsoft=0;
        error_spectrumbridge=0;
        %Initialize request number counter
        in=0;
        for xx=1:number_queries
            in=in+1;
            fprintf('[Batch no., Query no.]: %d, %d\n',bb,xx)
            
            %Fetch location data
            latitude=WSDB_data{1}.latitude;
            %Generate random longitude for one query
            a=str2num(WSDB_data{1}.longitude);
            b=str2num(WSDB_data{2}.longitude);
            longitude=num2str((b-a)*rand+a);
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if google_test==1
                %Query Google
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/google']);
                [msg_google,delay_google_tmp,error_google_tmp]=...
                    database_connect_google(type,latitude,longitude,height,agl,...
                    [my_path,'/google'],ggl_cnt);
                if error_google_tmp==1
                    error_google=error_google+1;
                end
            end
            if microsoft_test==1
                %Query Microsoft
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/microsoft']);
                [msg_microsoft,delay_microsoft_tmp,error_microsoft_tmp]=...
                    database_connect_microsoft(longitude,latitude,PropagationModel,...
                    CullingThreshold,IncludeNonLicensed,IncludeMicrophones,...
                    UseSRTM,UseGLOBE,UseLRBCast,[my_path,'/microsoft']);
                if error_microsoft_tmp==1
                    error_microsoft=error_microsoft+1;
                end
            end
            if spectrumbridge_test==1
                %Query SpectrumBridge
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/spectrumbridge']);
                delay_spectrumbridge_tmp_r=0;
                if DeviceType=='8'
                    [msg_spectrumbridge,delay_spectrumbridge_tmp_r]=database_connect_spectrumbridge_register(...
                        AntennaHeight,DeviceType,Latitude,Longitude,[my_path,'/spectrumbridge']);
                end
                delay_spectrumbridge_tmp=delay_spectrumbridge_tmp+delay_spectrumbridge_tmp_r;
                [msg_spectrumbridge,delay_spectrumbridge_tmp,error_spectrumbridge_tmp]=...
                    database_connect_spectrumbridge(DeviceType,latitude,longitude);
                if error_spectrumbridge_tmp==1
                    error_spectrumbridge=error_spectrumbridge+1;
                end
            end
        end
        if google_test==1
            %Clear old query results
            cd([my_path,'/google']);
            error_google_vec=[error_google_vec,error_google/number_queries];
        end
        if microsoft_test==1
            %Clear old query results
            cd([my_path,'/microsoft']);
            error_microsoft_vec=[error_microsoft_vec,error_microsoft/number_queries];
        end
        if spectrumbridge_test==1
            %Clear old query results
            cd([my_path,'/spectrumbridge']);
            error_spectrumbridge_vec=[error_spectrumbridge_vec,error_spectrumbridge/number_queries];
        end
    end
    if google_test==1
        er_google=mean(error_google_vec)*100
        var_google=var(error_google_vec)*100
    end
    if microsoft_test==1
        er_microsoft=mean(error_microsoft_vec)*100
        var_microsoft=var(error_microsoft_vec)*100
    end
    if spectrumbridge_test==1
        er_spectrumbridge=mean(error_spectrumbridge_vec)*100
        var_spectrumbridge=var(error_spectrumbridge_vec)*100
    end
end

if delay_distribution_per_location==1
    
    no_queries=50; %Select how many queries per location
    
    %Location data
    WSDB_data{1}.name='LA'; %Los Aneles, CA, USA (Wilshire Blvd 1) [downtown]
    WSDB_data{1}.latitude='34.047955';
    WSDB_data{1}.longitude='-118.256013';
    WSDB_data{1}.delay_microsoft=[];
    WSDB_data{1}.delay_google=[];
    
    WSDB_data{2}.name='WV'; %West Village (Manhattan), NY, USA [urban canyon]
    WSDB_data{2}.latitude='40.729655';
    WSDB_data{2}.longitude='-74.002854';
    WSDB_data{2}.delay_microsoft=[];
    WSDB_data{2}.delay_google=[];
    
    WSDB_data{3}.name='SC'; %Scipio, OH, USA [flatland]
    WSDB_data{3}.latitude='41.102884';
    WSDB_data{3}.longitude='-82.957361';
    WSDB_data{3}.delay_microsoft=[];
    WSDB_data{3}.delay_google=[];
    
    WSDB_data{4}.name='LE'; %Cleveland (Lake Erie), USA [lake coast]
    WSDB_data{4}.latitude='41.575416';
    WSDB_data{4}.longitude='-81.585442';
    WSDB_data{4}.delay_microsoft=[];
    WSDB_data{4}.delay_google=[];
    
    WSDB_data{5}.name='CB'; %Carolina Beach, NC, USA [ocean coast]
    WSDB_data{5}.latitude='34.047955';
    WSDB_data{5}.longitude='-77.885639';
    WSDB_data{5}.delay_microsoft=[];
    WSDB_data{5}.delay_google=[];
    
    %     WSDB_data{6}.name='RD'; %Microsoft Research, Redmond, WA, USA
    %     WSDB_data{6}.latitude='47.642565';
    %     WSDB_data{6}.longitude='-122.138401';
    %     WSDB_data{6}.delay_microsoft=[];
    %     WSDB_data{6}.delay_google=[];
    
    [wsbx,wsby]=size(WSDB_data); %Get location data size
    
    delay_google_vector=[];
    delay_microsoft_vector=[];
    delay_spectrumbridge_vector=[];
    
    legend_label_google=[];
    legend_label_microsoft=[];
    legend_label_spectrumbridge=[];
    
    %Initialize Google API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Google API console to check how many queries are used already]
    ggl_cnt=250;
    
    for ln=1:wsby
        
        delay_google=[];
        delay_microsoft=[];
        delay_spectrumbridge=[];
        for xx=1:no_queries
            fprintf('[Query no., Location no.]: %d, %d\n',xx,ln)
            
            %Fetch location data
            latitude=WSDB_data{ln}.latitude;
            longitude=WSDB_data{ln}.longitude;
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if google_test==1
                %Query Google
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/google']);
                [msg_google,delay_google_tmp,error_google_tmp]=...
                    database_connect_google(type,latitude,longitude,height,agl,...
                    [my_path,'/google'],ggl_cnt);
                var_name=(['google_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_google_tmp==0
                    dlmwrite([var_name,'.txt'],msg_google,'');
                    delay_google=[delay_google,delay_google_tmp];
                end
            end
            if microsoft_test==1
                %Query Microsoft
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/microsoft']);
                [msg_microsoft,delay_microsoft_tmp,error_microsoft_tmp]=...
                    database_connect_microsoft(longitude,latitude,PropagationModel,...
                    CullingThreshold,IncludeNonLicensed,IncludeMicrophones,...
                    UseSRTM,UseGLOBE,UseLRBCast,[my_path,'/microsoft']);
                var_name=(['microsoft_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_microsoft_tmp==0
                    dlmwrite([var_name,'.txt'],msg_microsoft,'');
                    delay_microsoft=[delay_microsoft,delay_microsoft_tmp];
                end
            end
            if spectrumbridge_test==1
                %Query SpectrumBridge
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/spectrumbridge']);
                delay_spectrumbridge_tmp_r=0;
                if DeviceType=='8'
                    [msg_spectrumbridge,delay_spectrumbridge_tmp_r]=database_connect_spectrumbridge_register(...
                        AntennaHeight,DeviceType,Latitude,Longitude,[my_path,'/spectrumbridge']);
                end
                [msg_spectrumbridge,delay_spectrumbridge_tmp,error_spectrumbridge_tmp]=...
                    database_connect_spectrumbridge(DeviceType,latitude,longitude);
                var_name=(['spectrumbridge_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_spectrumbridge_tmp==0
                    dlmwrite([var_name,'.txt'],msg_spectrumbridge,'');
                    delay_spectrumbridge_tmp=delay_spectrumbridge_tmp+delay_spectrumbridge_tmp_r;
                    delay_spectrumbridge=[delay_spectrumbridge,delay_spectrumbridge_tmp];
                end
            end
        end
        if google_test==1
            %Clear old query results
            cd([my_path,'/google']);
            %system('rm *');
            
            %Save delay data per location
            WSDB_data{ln}.delay_google=delay_google;
            legend_label_google=[legend_label_google,...
                repmat(ln,1,length(delay_google))]; %Label items for boxplot
            delay_google_vector=[delay_google_vector,delay_google];
            labels_google(ln)={WSDB_data{ln}.name};
        end
        if microsoft_test==1
            %Clear old query results
            cd([my_path,'/microsoft']);
            %system('rm *');
            
            %Save delay data per location
            WSDB_data{ln}.delay_microsoft=delay_microsoft;
            legend_label_microsoft=[legend_label_microsoft,...
                repmat(ln,1,length(delay_microsoft))]; %Label items for boxplot
            delay_microsoft_vector=[delay_microsoft_vector,delay_microsoft];
            labels_micosoft(ln)={WSDB_data{ln}.name};
        end
        if spectrumbridge_test==1
            %Clear old query results
            cd([my_path,'/spectrumbridge']);
            %system('rm *');
            
            %Save delay data per location
            WSDB_data{ln}.delay_spectrumbridge=delay_spectrumbridge;
            legend_label_spectrumbridge=[legend_label_spectrumbridge,...
                repmat(ln,1,length(delay_spectrumbridge))]; %Label items for boxplot
            delay_spectrumbridge_vector=[delay_spectrumbridge_vector,delay_spectrumbridge];
            labels_spectrumbridge(ln)={WSDB_data{ln}.name};
        end
    end
    
    %Query general web services for comparison
    delay_google_web=[];
    delay_microsoft_web=[];
    delay_spectrumbridge_web=[];
    for xx=1:no_queries
        fprintf('Query no.: %d\n',xx)
        if google_test==1
            dg=connect_webserver(1);
            delay_google_web=[delay_google_web,dg];
        end
        if microsoft_test==1
            dm=connect_webserver(2);
            delay_microsoft_web=[delay_microsoft_web,dm];
        end
        if spectrumbridge_test==1
            ds=connect_webserver(3);
            delay_spectrumbridge_web=[delay_spectrumbridge_web,ds];
        end
    end
    if google_test==1
        legend_label_google=[legend_label_google,...
            repmat(ln+1,1,length(delay_google_web))]; %Label items for boxplot
        delay_google_vector=[delay_google_vector,delay_google_web];
        labels_google(ln+1)={'[GL]'};
    end
    if microsoft_test==1
        legend_label_microsoft=[legend_label_microsoft,...
            repmat(ln+1,1,length(delay_microsoft_web))]; %Label items for boxplot
        delay_microsoft_vector=[delay_microsoft_vector,delay_microsoft_web];
        labels_micosoft(ln+1)={'[BG]'};
    end
    if spectrumbridge_test==1
        legend_label_spectrumbridge=[legend_label_spectrumbridge,...
            repmat(ln+1,1,length(delay_spectrumbridge_web))]; %Label items for boxplot
        delay_spectrumbridge_vector=[delay_spectrumbridge_vector,delay_spectrumbridge_web];
        labels_spectrumbridge(ln+1)={'[SB]'};
    end
    
    %%
    %Plot figure: Box plots for delay per location
    
    %Select maximum Y axis
    max_el=max([delay_google_vector(1:end),...
        delay_microsoft_vector(1:end),...
        delay_spectrumbridge_vector(1:end)]);

    if google_test==1
        figure('Position',[440 378 560/2.5 420/2]);

        boxplot(delay_google_vector,legend_label_google,...
            'labels',labels_google,'symbol','g+','jitter',0,'notch','on',...
            'factorseparator',1);
        ylim([0 max_el]);
        set(gca,'FontSize',ftsz);
        ylabel('Response delay (sec)','FontSize',ftsz);
        set(findobj(gca,'Type','text'),'FontSize',ftsz); %Boxplot labels size
        %Move boxplot labels below to avoid overlap with x axis
        txt=findobj(gca,'Type','text');
        set(txt,'VerticalAlignment','Top');
    end
    if microsoft_test==1
        figure('Position',[440 378 560/2.5 420/2]);

        boxplot(delay_microsoft_vector,legend_label_microsoft,...
            'labels',labels_micosoft,'symbol','b+','jitter',0,'notch','on',...
            'factorseparator',1);
        ylim([0 max_el]);
        set(gca,'FontSize',ftsz);
        ylabel('Response delay (sec)','FontSize',ftsz);
        set(findobj(gca,'Type','text'),'FontSize',ftsz); %Boxplot labels size
        %Move boxplot labels below to avoid overlap with x axis
        txt=findobj(gca,'Type','text');
        set(txt,'VerticalAlignment','Top');
    end
    if spectrumbridge_test==1
        figure('Position',[440 378 560/2.5 420/2]);

        boxplot(delay_spectrumbridge_vector,legend_label_spectrumbridge,...
            'labels',labels_spectrumbridge,'symbol','k+','jitter',0,'notch','on',...
            'factorseparator',1);
        ylim([0 max_el]);
        set(gca,'FontSize',ftsz);
        ylabel('Response delay (sec)','FontSize',ftsz);
        set(findobj(gca,'Type','text'),'FontSize',ftsz); %Boxplot labels size
        %Move boxplot labels below to avoid overlap with x axis
        txt=findobj(gca,'Type','text');
        set(txt,'VerticalAlignment','Top');
    end
        
    %Plot figure: plot delay request PDF estimates per location
    Markers={'k-','r--','g.-','b-.','mx-','cv-'};
    
    %Reserve axex properties for all figures
    fm=[];
    xm=[];
    fs=[];
    xs=[];
    fg=[];
    xg=[];
    
    if google_test==1
        figure('Position',[440 378 560 420/3]);
        name_location_vector=[];
        for ln=1:wsby
            delay_google=WSDB_data{ln}.delay_google;
            
            %Outlier removal (Google delay)
            outliers_pos=abs(delay_google-median(delay_google))>3*std(delay_google);
            delay_google(outliers_pos)=[];
            
            [fg,xg]=ksdensity(delay_google,'support','positive');
            fg=fg./sum(fg);
            plot(xg,fg,Markers{ln});
            hold on;
            name_location=WSDB_data{ln}.name;
            name_location_vector=[name_location_vector,{name_location}];
        end
        %Add plot for general webservice
        
        %Outlier removal (Google delay)
        outliers_pos=abs(delay_google_web-median(delay_google_web))>3*std(delay_google_web);
        delay_google_web(outliers_pos)=[];
        
        name_location_vector=[name_location_vector,'[GL]'];
        
        [fm,xg]=ksdensity(delay_google_web,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,Markers{wsby+1});
        
        box on;
        grid on;
        set(gca,'FontSize',ftsz);
        xlabel('Response delay (sec)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
        legend(name_location_vector,'Location','Best');
    end
    if microsoft_test==1
        figure('Position',[440 378 560 420/3]);
        name_location_vector=[];
        for ln=1:wsby
            delay_microsoft=WSDB_data{ln}.delay_microsoft;
            
            %Outlier removal (Microsoft delay)
            outliers_pos=abs(delay_microsoft-median(delay_microsoft))>3*std(delay_microsoft);
            delay_microsoft(outliers_pos)=[];
            
            [fm,xm]=ksdensity(delay_microsoft,'support','positive');
            fm=fm./sum(fm);
            plot(xm,fm,Markers{ln});
            hold on;
            name_location=WSDB_data{ln}.name;
            name_location_vector=[name_location_vector,{name_location}];
        end
        %Add plot for general webservice
        
        %Outlier removal (Microsoft delay)
        outliers_pos=abs(delay_microsoft_web-median(delay_microsoft_web))>3*std(delay_microsoft_web);
        delay_microsoft_web(outliers_pos)=[];
        
        name_location_vector=[name_location_vector,'[BG]'];
        
        [fm,xm]=ksdensity(delay_microsoft_web,'support','positive');
        fm=fm./sum(fm);
        plot(xm,fm,Markers{wsby+1});
        
        box on;
        grid on;
        set(gca,'FontSize',ftsz);
        xlabel('Response delay (sec)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
        legend(name_location_vector,'Location','Best');
    end
    if spectrumbridge_test==1
        figure('Position',[440 378 560 420/3]);
        name_location_vector=[];
        for ln=1:wsby
            delay_spectrumbridge=WSDB_data{ln}.delay_spectrumbridge;
            
            %Outlier removal (SpectrumBridge delay)
            outliers_pos=abs(delay_spectrumbridge-median(delay_spectrumbridge))>3*std(delay_spectrumbridge);
            delay_spectrumbridge(outliers_pos)=[];
            
            [fs,xs]=ksdensity(delay_spectrumbridge,'support','positive');
            fs=fs./sum(fs);
            plot(xs,fs,Markers{ln});
            hold on;
            name_location=WSDB_data{ln}.name;
            name_location_vector=[name_location_vector,{name_location}];
        end
        %Add plot for general webservice
        
        %Outlier removal (SpectrumBridge delay)
        outliers_pos=abs(delay_spectrumbridge_web-median(delay_spectrumbridge_web))>3*std(delay_spectrumbridge_web);
        delay_spectrumbridge_web(outliers_pos)=[];
        
        name_location_vector=[name_location_vector,'[SB]'];
        
        [fs,xs]=ksdensity(delay_spectrumbridge_web,'support','positive');
        fs=fs./sum(fs);
        plot(xs,fs,Markers{wsby+1});
        
        box on;
        grid on;
        set(gca,'FontSize',ftsz);
        xlabel('Response delay (sec)','FontSize',ftsz);
        ylabel('Probability','FontSize',ftsz);
        legend(name_location_vector,'Location','Best');
    end
    
%Set y axis limit manually at the end of plot
ylim([0 max([fg,fm,fs])]);    
end

if delay_distribution_area==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LA'; %Los Aneles, CA, USA (Wilshire Blvd 1) [downtown]
    WSDB_data{1}.latitude='34.047955';
    WSDB_data{1}.longitude='-118.256013';
    WSDB_data{1}.delay_microsoft=[];
    WSDB_data{1}.delay_google=[];
    
    %Query finish location
    WSDB_data{2}.name='CB'; %Carolina Beach, NC, USA [ocean coast]
    WSDB_data{2}.latitude='34.047955';
    WSDB_data{2}.longitude='-77.885639';
    WSDB_data{2}.delay_microsoft=[];
    WSDB_data{2}.delay_google=[];
    
    longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
    longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory
    
    longitude_interval=100;
    longitude_step=(longitude_end-longitude_start)/longitude_interval;
    no_queries=20; %Number of queries per individual location
    
    delay_google=[];
    delay_microsoft=[];
    delay_spectrumbridge=[];
    
    inx=0; %Initialize position counter
    
    %Initialize Google API request counter [important: it needs initliazed
    %manually every time as limit of 1e3 queries per API is enforced. Check
    %your Google API console to check how many queries are used already]
    ggl_cnt=2029;
    
    for xx=longitude_start:longitude_step:longitude_end
        inx=inx+1;
        iny=0; %Initialize query counter
        for yy=1:no_queries
            iny=iny+1;
            fprintf('[Query no., Location no.]: %d, %d\n',iny,inx);
            
            %Fetch location data
            latitude=WSDB_data{1}.latitude;
            longitude=num2str(xx);
            
            instant_clock=clock; %Save clock for file name (if both WSDBs are queried)
            if google_test==1
                %Query Google
                fprintf('Google\n')
                ggl_cnt=ggl_cnt+1;
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/google']);
                [msg_google,delay_google_tmp,error_google_tmp]=...
                    database_connect_google(type,latitude,longitude,height,agl,...
                    [my_path,'/google'],ggl_cnt);
                var_name=(['google_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_google_tmp==0
                    dlmwrite([var_name,'.txt'],msg_google,'');
                    delay_google=[delay_google,delay_google_tmp];
                end
            end
            if microsoft_test==1
                %Query Microsoft
                fprintf('Microsoft\n')
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/microsoft']);
                [msg_microsoft,delay_microsoft_tmp,error_microsoft_tmp]=...
                    database_connect_microsoft(longitude,latitude,PropagationModel,...
                    CullingThreshold,IncludeNonLicensed,IncludeMicrophones,...
                    UseSRTM,UseGLOBE,UseLRBCast,[my_path,'/microsoft']);
                var_name=(['microsoft_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_microsoft_tmp==0
                    dlmwrite([var_name,'.txt'],msg_microsoft,'');
                    delay_microsoft=[delay_microsoft,delay_microsoft_tmp];
                end
            end
            if spectrumbridge_test==1
                %Query SpectrumBridge
                fprintf('SpectrumBridge\n')
                instant_clock=clock; %Start clock again if scanning only one database
                cd([my_path,'/spectrumbridge']);
                delay_spectrumbridge_tmp_r=0;
                if DeviceType=='8'
                    [msg_spectrumbridge,delay_spectrumbridge_tmp_r]=database_connect_spectrumbridge_register(...
                        AntennaHeight,DeviceType,Latitude,Longitude,[my_path,'/spectrumbridge']);
                end
                [msg_spectrumbridge,delay_spectrumbridge_tmp,error_spectrumbridge_tmp]=...
                    database_connect_spectrumbridge(DeviceType,latitude,longitude);
                var_name=(['spectrumbridge_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
                if error_spectrumbridge_tmp==0
                    dlmwrite([var_name,'.txt'],msg_spectrumbridge,'');
                    delay_spectrumbridge_tmp=delay_spectrumbridge_tmp+delay_spectrumbridge_tmp_r;
                    delay_spectrumbridge=[delay_spectrumbridge,delay_spectrumbridge_tmp];
                end
            end
        end
        %%
        %Assign delay per location per WSDB to a new variable
        if google_test==1
            delay_google_loc{inx}=delay_google;
            delay_google=[];
        end
        if microsoft_test==1
            delay_microsoft_loc{inx}=delay_microsoft;
            delay_microsoft=[];
        end
        if spectrumbridge_test==1
            delay_spectrumbridge_loc{inx}=delay_spectrumbridge;
            delay_spectrumbridge=[];
        end
    end
    
    %%
    %Get elavation data
    Elev=[];
    for xx=longitude_start:longitude_step:longitude_end
        pause(0.5); %Google imposes cap on number of queries - delay query
        elevation=elevation_google_maps(str2num(latitude),xx);
        Elev=[Elev,elevation];
    end
    
    %%
    %Compute means of queries per location
    if google_test==1
        Vm_google=[];
        for xx=1:inx
            mtmp_google=delay_google_loc{xx};
            Vm_google=[Vm_google,mean(mtmp_google)];
        end
        %Clear old query results
        cd([my_path,'/google']);
        %system('rm *');
    end
    if microsoft_test==1
        Vm_microsoft=[];
        for xx=1:inx
            mtmp_microsoft=delay_microsoft_loc{xx};
            Vm_microsoft=[Vm_microsoft,mean(mtmp_microsoft)];
        end
        %Clear old query results
        cd([my_path,'/microsoft']);
        %system('rm *');
    end
    if spectrumbridge_test==1
        Vm_spectrumbridge=[];
        for xx=1:inx
            mtmp_spectrumbridge=delay_spectrumbridge_loc{xx};
            Vm_spectrumbridge=[Vm_spectrumbridge,mean(mtmp_spectrumbridge)];
        end
        %Clear old query results
        cd([my_path,'/spectrumbridge']);
        %system('rm *');
    end
    
    %%
    %Plot distribution curves
    Markers={'g-','b--','k-.'};
    %Plot figures
    if google_test==1
        figure('Position',[440 378 560 420/3]);
        [fg,xg]=ksdensity(Vm_google,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,Markers{1});
        hold on;
    end
    if microsoft_test==1
        %figure('Position',[440 378 560 420/3]);
        [fm,xm]=ksdensity(Vm_microsoft,'support','positive');
        fm=fm./sum(fm);
        plot(xm,fm,Markers{2});
        hold on;
    end
    if spectrumbridge_test==1
        %figure('Position',[440 378 560 420/3]);
        [fs,xs]=ksdensity(Vm_spectrumbridge,'support','positive');
        fs=fs./sum(fs);
        plot(xs,fs,Markers{3});
        hold on;
    end
    
    box on;
    grid on;
    set(gca,'FontSize',ftsz);
    xlabel('Response delay (sec)','FontSize',ftsz);
    ylabel('Probability','FontSize',ftsz);
    legend(legend_string,'Location','Best');
    
    %Plot delay per location curves
    if google_test==1
        figure('Position',[440 378 560 420/3]);
        hold on;
        plot(1:longitude_interval+1,Vm_google./sum(Vm_google),Markers{1});
    end
    if microsoft_test==1
        %figure('Position',[440 378 560 420/2]);
        hold on;
        plot(1:longitude_interval+1,Vm_microsoft./sum(Vm_microsoft),Markers{2});
    end
    if spectrumbridge_test==1
        %figure('Position',[440 378 560 420/2]);
        hold on;
        plot(1:longitude_interval+1,Vm_spectrumbridge./sum(Vm_spectrumbridge),Markers{3});
    end
    
    %Plot elevation
    %plot(Elev./sum(Elev),Markers{4});
    
    box on;
    grid on;
    set(gca,'FontSize',ftsz);
    xlim([0 longitude_interval+1]);
    xlabel('Location number','FontSize',ftsz);
    ylabel('Response delay (sec)','FontSize',ftsz);
    legend([legend_string],'Location','Best');
    %legend([legend_string,'Normalized elevation'],'Location','Best');
    
end

%%
['Elapsed time: ',num2str(toc/60),' min']