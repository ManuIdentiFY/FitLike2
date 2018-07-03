function [time, zone, dzone] = bloc2zone(bloc, parameters, method)
%
% [TIME, ZONE, DZONE] = BLOC2ZONE(BLOC, PARAMETERS, METHOD) process the 
% FFC-NMR Stelar raw data (bloc) to obtain the zone data. The zone data 
% includes inversion time series as well as the corresponding values
% ("zone") and their errors ("dzone").
%
% BLOC2ZONE applies a phase-correction based on the data and a conversion
% from complex to double (real() or abs()).
%
% Input: 
% *bloc: bloc data specified as a matrix nPoints x nZone 
% *parameters: Stelar parameters as a structure (see READSDF)           
% *method: processing methods specified as a structure with 3
%          fields:
%     method.bound: [minBound maxBound]
%     method.phc0: 'first','all'
%     method.mode: 'real','abs'
%
% Output: 
% *time: time data specified as a vector 1 x nZone
% *zone: zone data specified as a vector 1 x nZone
% *dzone: zone error data specified as a vector 1 x nZone
%
% Example:
% filename = 'stelar_data.sdf';
% fid = fopen(filename, 'r'); % open the file in read only mode
% [bloc, parameters] = readsdfv1(fid); %read data
% 
% method = struct('bound',[6 120],'phc0','first','mode','abs');
% [time, zone, dzone] = bloc2zone(bloc{1}.y, parameters{1}, method);
%
% See also READSDFV1, READSDFV2, GETINVTIME, DATAUNIT
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr

% check input 
if nargin ~= 3
    error('bloc2zone: Incorrect number of input')
end

%get the time series
time = getinvtime(parameters);

%apply boundaries
bloc = bloc(method.bound(1):method.bound(2),:);

%get the phase receiver
phc0 = mod(angle(mean(bloc)),pi);
%phase correction
switch method.phc0
    case 'first'
        bloc = bloc*exp(-1i*phc0(1)); %re-phase using the first bloc phase value
    case 'all'
        bloc = bloc*exp(-1i*phc0); %re-phase each bloc separately
    otherwise
        error('bloc2zone: No phase-correction methods selected')
end

%convert to double (real or abs method)
switch method.mode
    case 'real'
        bloc = real(bloc);
    case 'abs'
        s = sign(real(bloc));
        bloc = s.*abs(bloc);
    otherwise
        error('bloc2zone: No conversion methods from complex to double selected')
end

%average the bloc values to obtain the zone ones
zone = mean(bloc);
dzone = std(bloc);
end %fun



