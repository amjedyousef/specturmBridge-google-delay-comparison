function [response,delay]=database_connect_spectrumbridge_register(...
    AntennaHeight,DeviceType,Latitude,Longitude,my_path)
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
%Register device to the database

%Create XML file
spectrumbridge_register(AntennaHeight,DeviceType,Latitude,Longitude);

url_phrase=['"',server_url_base,'/devices/',SBI_CC,'/',SBI_ID,'/',SBI_SN,'"'];
text_coding='"content-type: application/xml; charset=utf-8"';

my_path=regexprep(my_path,' ','\\ ');

cmnd=['/usr/bin/curl -X PUT --header',' ',text_coding,' --data-binary @',my_path,'/xmlspectrumbridge.xml',' ',url_phrase,' -w %{time_total}'];

[status,response]=system(cmnd);

%Calculate registration delay
delay=str2num(response);

system('rm xmlspectrumbridge.xml');

function spectrumbridge_register(AntennaHeight,DeviceType,Latitude,Longitude);

%Address passed with dummy values
reg_xml=['<RegistrationRequest xmlns="http://schemas.datacontract.org/2004/07/SpectrumBridge.WhiteSpaces.Services.v3">',...
'<AntennaHeight>',AntennaHeight,'</AntennaHeight>',...
'<ContactCity>City</ContactCity>',...
'<ContactCountry>US</ContactCountry>',...
'<ContactEmail>email@email.com</ContactEmail>',...
'<ContactName>ContactName</ContactName>',...
'<ContactPhone>1111111111</ContactPhone>',...
'<ContactState>MD</ContactState>',...
'<ContactStreet>ContactStreet</ContactStreet>',...
'<ContactZip>00000</ContactZip>',...
'<DeviceOwner>DeviceOwner</DeviceOwner>',...
'<DeviceType>',DeviceType,'</DeviceType>',...
'<Latitude>',Latitude,'</Latitude>',...
'<Longitude>',Longitude,'</Longitude>',...
'</RegistrationRequest>'];

dlmwrite('xmlspectrumbridge.xml',reg_xml,'');