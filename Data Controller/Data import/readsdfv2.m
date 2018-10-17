function [dataContent, parameter] = readsdfv2(filename,varargin)

% [BLOC, PARAMETERS] = READSDFV2(FILENAME,VARARGIN) reads data from a
% Stelar file .sdf version 2. Use FOPEN to open the file and obtain FID. It
% returns the data as DataUnit and the parameters as cells.
%
% The number of DataUnit and cell is determined by the number of different
% acquisitions in the Stelar file. Two acquisitions are different if one of
% the following condition is not fullfilled:
% 1. The sequence are not the same (see the field "EXP")
% 2. The size of the data is not consistent between the acquisitions 
% 3. The parameter's fields are not the same
% 
% Notes:
% When two acquisitions are the same, data (fields: x,y) are stacked along 
% the third dimensions and parameters are concatenated.
% Note also that additional inputs can be added for compatibility with
% other readsdf functions, but are ignored.
%
% Example:
% filename = 'stelar_data.sdf';
% [bloc, parameters] = readsdfv2(fullfile(cd,filename));
%
% See also DATAUNIT, READSDFV1
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr
%
% Modified by L Broche 2018 for whole-text reading
% l.broche@abdn.ac.uk

%% Read the file

fid = fopen(filename, 'r'); % open the file in read only mode
if fid == -1
    errordlg(['File ' filename ' not found!'])
    return
end
txt = fread(fid,'*char')';
fclose(fid);

%% Preparations and preallocations
% the import startegy relies on finding key words at regular intervals
% ('PARAMETERS SUMMARY', 'NMRD SEQUENCE NAME' and 'DATA'). 

% formating the output structure
dataContent = struct();

%% analyse the data

% the header 'PARAMETER SUMMARY' separated each new dispersion acquisition
[posExpHeader, posExpStart] = regexp(txt,'SEQUENCE NAME:[^\n]*\n*\s\nPARAMETER SUMMARY\n*');
posExpHeader = [posExpHeader length(txt)]; % add the end of the file for reference

% now find the position of all the data zones and corresponding raw data,
% as well as empty lines
[posSeqName,posSeqNameEnd] = regexp(txt,'SEQUENCE NAME:[^\n]*\n'); 
[posZone, posParamStart] = regexp(txt,'ZONE \w*.\w*\n');
[posData, posDataStart] = regexp(txt,'DATA *\n');
posEmpty = regexp(txt,'\n *\n');
posEmpty = [posEmpty, length(txt)];  % add the end of the file in case it ends without carriage returns
posParamEnd = posData-1;

%% pair up the start and end of data zones and read all the data zones
for i = 1:length(posData)
    % find where the data zone ends
    posDataEnd(i) = min(posEmpty(posEmpty>posData(i)) - posData(i)) + posData(i); 
    % get the name of the column variables (only need to do this on one
    % line, they are all the same for a given experiment)
    colNameLine = textscan(txt(posDataStart(i) + (0:1000)),'%s',1,'delimiter','\n','HeaderLines',1);
    colName{i} = strsplit(colNameLine{1}{1},[char(9) char(9)])';
    colName{i}{strncmp(colName{i},'TIME',4)} = 'TIME';  % remove imcompatible characters for field names
    % make sure the field names are consistent with previous versions
    colName{i} = strrep(colName{i},'REAL','real');
    colName{i} = strrep(colName{i},'IMG','imag');
    colName{i} = strrep(colName{i},'TIME','time');
    % now read the data zone
    format{i} = repmat('%f ',1,length(colName{i}));
end
%% now collect all the zone data and parameters efficiently
dataList = arrayfun(@(i,f,e)textscan(txt(i:e),f{1},'delimiter','\n ','HeaderLines',2),posDataStart,format,posDataEnd,'UniformOutput',0);
txtZone  = arrayfun(@(i,e)  textscan(txt(i:e),'%s','delimiter','\n'),posParamStart,posParamEnd,'UniformOutput',0);
paramList = cellfun(@(t)   ParamV2(text2structure(t{1})), txtZone,'UniformOutput',0);
paramList = [paramList{:}];

%% now regroup the data and parameters for each experiements
for acquisitionNumber = 1:length(posExpHeader)-1  % last element of posExpHeader is the end of the file
    % get the sequence name
    seqName{acquisitionNumber} = txt(posExpHeader(acquisitionNumber)+15:posExpStart(acquisitionNumber)-21);
    % get the parameter header
    posHeadEnd(acquisitionNumber) = min(posEmpty(posEmpty>posExpStart(acquisitionNumber)) - posExpStart(acquisitionNumber)) + posExpStart(acquisitionNumber); 
    txtHead  = textscan(txt(posExpStart(acquisitionNumber):posHeadEnd(acquisitionNumber)),'%s','delimiter','\n');
    paramHeader = ParamV2(text2structure(txtHead{1}));
    % find the indexes corresponding to that experiment
    expIndex{acquisitionNumber} = (posParamStart>posExpHeader(acquisitionNumber))&(posParamStart<posExpHeader(acquisitionNumber+1));
    % regroup all the data and parameters included in that zone
    if length(paramList)>1 && sum(expIndex{acquisitionNumber})>1
        newPar = merge(paramList(expIndex{acquisitionNumber}));
        parameter(acquisitionNumber) = replace([paramHeader newPar]);
    else
        parameter(acquisitionNumber) = paramHeader;
    end
    parameter(acquisitionNumber).paramList.BRLX = parameter(acquisitionNumber).paramList.BR; % rename some of the fields for compatibility
    parameter(acquisitionNumber) = changeFieldName(parameter(acquisitionNumber),'T1MAX','T1MX');
    % scaling the field and T1MX values to standard units
    parameter(acquisitionNumber).paramList.BRLX = parameter(acquisitionNumber).paramList.BRLX*1e6;
    parameter(acquisitionNumber).paramList.T1MX = parameter(acquisitionNumber).paramList.T1MX/1e6;
    % Additional fields are needed that are not present in sdf v2
    [path,name] = fileparts(filename);
    ind = strfind(path,filesep);
    parameter(acquisitionNumber).paramList.FILE = fullfile(path(ind(end)+1:end),name);
    [~,parameter(acquisitionNumber).paramList.EXP] = fileparts(seqName{acquisitionNumber});
    % now gather the data
    columns = colName(expIndex{acquisitionNumber});
    columns = columns{1}; % all the column names should be the same for a given experiment
    for nField = 1:length(columns)
        if ~isfield(dataContent,columns{nField}) % initialise the fields if needs be
            dataContent = setfield(dataContent,columns{nField},cell(1,acquisitionNumber)); %#ok<*SFLD>
        end
        d = dataList(expIndex{acquisitionNumber});  % get the data for this particular group
        % the data may be arranged in a way that differs depending on the
        % acquisition strategy. If using the profile wizard, the zones are
        % saved independantly, but when using the loop tab the format is
        % different. Here we try to unify everything.
        % detecting the use of profile wizard:
%         if 
        BlocSize = parameter(acquisitionNumber).paramList.BS;
        ZoneSize = parameter(acquisitionNumber).paramList.NBLK;
        for indDisp = 1:length(d)
            dataContent.(columns{nField}){acquisitionNumber}(:,:,indDisp) = reshape(d{indDisp}{nField},BlocSize,ZoneSize);
        end
    end
end

%% check that all the data has been captured, otherwise put the remaining data into a separate experiment 

% TO DO


    
