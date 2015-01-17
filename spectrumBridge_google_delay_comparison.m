
tic;
clear;
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
%Plot parameters
ftsz=16;
lineWidth=1.5;
x_start = -0.09;
x_end = 0.69;
box_width = 0.3;
box1_pos = 0.1;
box2_pos = 0.5;
outlierSize = 3;

%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/Gproject/workspace/data/WSDB_DATA';

%%
%General querying parameters

%Global Google parameters (refer to https://developers.google.com/spectrum/v1/paws/getSpectrum)
type='"AVAIL_SPECTRUM_REQ"';
height='30.0'; %In meters; Note: 'height' needs decimal value
agl='"AMSL"';

%Global SpectrumBridge parameters (refer to WSDB_TVBD_Interface_v1.0.pdf [provided by Peter Stanforth])
AntennaHeight='30'; %In meters; Ignored for personal/portable devices
DeviceType='3'; %Examples: 8-Fixed, 3-40 mW Mode II personal/portable; 4-100 mW Mode II personal/portable


%Location of start and finish query
%Query start location
WSDB_data{1}.latitude='30.408274';
WSDB_data{1}.longitude='-96.853489';

%Query finish location
WSDB_data{2}.latitude='40.210220';
WSDB_data{2}.longitude='-79.846654';

longitude_start=str2num(WSDB_data{1}.longitude); %Start of the spectrum scanning trajectory
longitude_end=str2num(WSDB_data{2}.longitude); %End of spectrum scanning trajectory

longitude_interval=50;
longitude_step=(longitude_end-longitude_start)/longitude_interval;
no_queries=10; %Number of queries per individual location

delay_google=[];
delay_spectrumbridge=[];

inx=0; %Initialize position counter

%Initialize Google API request counter [important: it needs initliazed
%manually every time as limit of 1e3 queries per API is enforced. Check
%your Google API console to check how many queries are used already]
ggl_cnt=0;

for xx=longitude_start:longitude_step:longitude_end
    inx=inx+1;
    iny=0; %Initialize query counter
    for yy=1:no_queries
        iny=iny+1;
        fprintf('[Query no., Location no.]: %d, %d\n',iny,inx);
        
        %Fetch location data
        latitude=WSDB_data{1}.latitude;
        longitude=num2str(xx);
        
        if google_test==1
            %Query Google
            fprintf('Google\n')
            ggl_cnt=ggl_cnt+1;
            instant_clock=clock; %Start clock again if scanning only one database
            cd([my_path,'/google']);
            [msg_google,delay_google_tmp,error_google_tmp]=...
                query_database_google(type,latitude,longitude,height,agl,ggl_cnt, [my_path,'/google']);
            var_name=(['google_',num2str(longitude),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS')]);
            if error_google_tmp==0
                disp(msg_google)
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
end
%%
%Boxplot
figure('Position',[440 378 560 420/3]);
m = [delay_google' , delay_spectrumbridge'];
boxplot(m , 'notch' , 'on', 'widths' , [box_width box_width], 'outliersize' ,outlierSize ,...
    'positions' , [box1_pos box2_pos])
ylabel('Delay (sec)');
set(gca , 'XTickLabel' , {'Google' , 'SpectrumBridge' });
set(findobj(gca,'type','line'),'linew',lineWidth);
set(findobj('type' , 'axes') , 'FontSize' , ftsz);
set(findobj('type' , 'text'),'FontSize' , ftsz);
xlim([x_start x_end])

%%
%Compute means and variance of queries per operator
mean_delay_google = mean(delay_google)
mean_delay_spectrumbridge = mean(delay_spectrumbridge)

var_delay_google= var(delay_google)
var_delay_spectrumbridge = var(delay_spectrumbridge)
%%
save('google-spectrumBrige-delay-comparision');
%%
['Elapsed time: ',num2str(toc/60),' min']