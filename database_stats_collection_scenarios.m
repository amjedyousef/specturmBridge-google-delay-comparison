
tic;
clear all;
close all;
clc;

%Switch which database you want to query
google_test=1; %Query Google database
spectrumbridge_test=1; %Query spectrumBridge database

%%
%Create legend for the figures
legend_string={'Google','SpectrumBridge'};
legend_flag=[google_test,spectrumbridge_test];
legend_string(find(~legend_flag))=[];

%%
%Select which scenario to test
delay_distribution_area=1;

%%
%Plot parameters
ftsz=16;

%%
%Path to save files (select your own)
my_path='';

%%
%General querying parameters

%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height='30.0'; %In meters; Note: 'height' needs decimal value
agl='"AMSL"';

%Global SpectrumBridge parameters (refer to WSDB_TVBD_Interface_v1.0.pdf [provided by Peter Stanforth])
AntennaHeight='30'; %In meters; Ignored for personal/portable devices
DeviceType='3'; %Examples: 8-Fixed, 3-40 mW Mode II personal/portable; 4-100 mW Mode II personal/portable

if delay_distribution_area==1
    
    %Location of start and finish query
    %Query start location
    WSDB_data{1}.name='LA'; %Los Aneles, CA, USA (Wilshire Blvd 1) [downtown]
    WSDB_data{1}.latitude='34.047955';
    WSDB_data{1}.longitude='-118.256013';
    WSDB_data{1}.delay_google=[];
    
    %Query finish location
    WSDB_data{2}.name='CB'; %Carolina Beach, NC, USA [ocean coast]
    WSDB_data{2}.latitude='34.047955';
    WSDB_data{2}.longitude='-77.885639';
    WSDB_data{2}.delay_google=[];
    
    longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
    longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory
    
    longitude_interval=100;
    longitude_step=(longitude_end-longitude_start)/longitude_interval;
    no_queries=20; %Number of queries per individual location
    
    delay_google=[];
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
    Markers={'g-','b--'};
    %Plot figures
    if google_test==1
        figure('Position',[440 378 560 420/3]);
        [fg,xg]=ksdensity(Vm_google,'support','positive');
        fg=fg./sum(fg);
        plot(xg,fg,Markers{1});
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