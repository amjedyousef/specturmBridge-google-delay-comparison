function [response,delay,error]=database_connect_spectrumbridge(...
    DeviceType,Latitude,Longitude)
%DATABASE_CONNECT_SPECTRUMBRIDGE Script used in querying SpectrumBridge WSDB [1].
%
%   Reference: [1] Will Dynamic Spectrum Access Drain my Battery?

%   Code development: 

%   Last update: 29 June 2014

%   This work is licensed under a Creative Commons Attribution 3.0 Unported
%   License. Link to license: http://creativecommons.org/licenses/by/3.0/

delay=[]; %Default delay value
error=false; %Default error value

%%
%Query constants

SBI_ID=''; %FCC ID [replace by your own]
SBI_SN='101'; %Device serial number; Set of possible serial numbers [101,102,103,104,105];
SBI_CC='US'; %Country code
server_url_base='https://tvws-demo.spectrumbridge.com/v3';

%%
%Query the database

%Perform actual query
cmnd=['/usr/bin/curl "',server_url_base,'/channels/',SBI_CC,'/',Latitude,'/',Longitude,'/?fccid=',SBI_ID,'&serial=',SBI_SN,'&type=',DeviceType,'" -w %{time_total}'];

[status,response]=system(cmnd);

%Calculate query delay and flag error
end_query_str='</ChannelResponse>';
pos_end_query_str=findstr(response,end_query_str);
if isempty(pos_end_query_str)
    error=true;
    'SpectrumBridge Error'
    delay=Inf;
else
    length_end_query_str=length(end_query_str);
    delay=str2num(response(pos_end_query_str+length_end_query_str:end));
    response(pos_end_query_str+length_end_query_str:end)=[];
end