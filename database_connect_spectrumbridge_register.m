function [response,delay]=database_connect_spectrumbridge_register(...
    AntennaHeight,DeviceType,Latitude,Longitude,my_path)
%DATABASE_CONNECT_SPECTRUMBRIDGE Script used in querying SpectrumBridge WSDB.
%   Last update: 12 January 2015

% Reference:
%   P. Pawelczak et al. (2014), "Will Dynamic Spectrum Access Drain my
%   Battery?," submitted for publication.

%   Code development: Amjed Yousef Majid (amjadyousefmajid@student.tudelft.nl),
%                     Przemyslaw Pawelczak (p.pawelczak@tudelft.nl)

% Copyright (c) 2014, Embedded Software Group, Delft University of
% Technology, The Netherlands. All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
% contributors may be used to endorse or promote products derived from this
% software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

delay=[]; %Default delay value
error=false; %Default error value

%%
%Query constants

SBI_ID='TUDELFT'; %FCC ID [replace by your own]
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