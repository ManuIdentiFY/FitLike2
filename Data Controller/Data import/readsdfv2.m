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
parameter = []; % parameter array containing one element per dispersion dataset

%% Sort the data

% the header 'PARAMETER SUMMARY' separated each new dispersion acquisition
posParamSummary = regexp(txt,'PARAMETER SUMMARY')+length('PARAMETER SUMMARY');  % cannot use startWith for compatibility reasons with version older than 2017a
if isempty(posParamSummary) 
    return % exit if empty file
end

% now find the position of all the data zones and corresponding raw data
posSeqName = regexp(txt,'NMRD SEQUENCE NAME:'); 
posZone = regexp(txt,'ZONE');
posData = regexp(txt,'DATA');

% find the 'ZONE' labels that stop the 'PARAMETER SUMMARY sections
posSeqEnd = arrayfun(@(posIni)min(posZone(posZone>posIni)-posIni),posParamSummary);
posSeqEnd = posSeqEnd + posParamSummary;

% store the general lists of parameters
parameter = ParamV2;

% collects the data for each dispersion acquisition
posParamSummary(end+1) = length(txt);
for acquisitionNumber = 1:length(posParamSummary)-1
    % generate the new Parameter object from the new header
    txtcell = textscan(txt(posParamSummary(acquisitionNumber)+1:posSeqEnd(acquisitionNumber)-3),'%s','delimiter','\n');
    parameter(acquisitionNumber) = ParamV2(text2structure(txtcell{1}));
    % make a list of all the parameter structures to be merged later. Usually
    % contains BR and T1MAX, and in general contains the parameters that change
    % at each iteration
    posSubZone = posZone((posZone>=posParamSummary(acquisitionNumber)) & (posZone < posParamSummary(acquisitionNumber+1)));
    posSubData = posData((posZone>=posParamSummary(acquisitionNumber)) & (posZone < posParamSummary(acquisitionNumber+1)));
    % finding the sequence name is tricky since it is also located before
    % the PARAMETER header 
    nameInd = find((posSeqName>=posParamSummary(acquisitionNumber)-1) & (posSeqName < posParamSummary(acquisitionNumber+1)-1));
    posSubSeqName = posSeqName(min(nameInd)-1:max(nameInd)-1);  % careful: this line comes before the parameters summary
    zoneParamList = arrayfun(@(start,stop)textscan(txt(start+1:stop-3),'%s','delimiter','\n'),posSubZone,posSubData,'UniformOutput',0);
    paramZone = cellfun(@(t)ParamV2(text2structure(t{1})),zoneParamList);

    % rename some of the fields for compatibility
    paramZone = changeFieldName(paramZone,'BR','BRLX');
    paramZone = changeFieldName(paramZone,'T1MAX','T1MX');
    % scaling the field and T1MX values to standard units
    for indj = 1:length(paramZone)
        paramZone(indj).paramList.BRLX = paramZone(indj).paramList.BRLX*1e6;
        paramZone(indj).paramList.T1MX = paramZone(indj).paramList.T1MX/1e6;
    end
    
    % some files are not formed correctly and do not have the sequence name.
    % Fix this by imposing a name from the file name
    if ~isempty(posSubSeqName)
%         [~,seqName] = arrayfun(@(start,stop)fileparts(txt(start+20:stop-3)),posSubSeqName,[posParamSummary(acquisitionNumber) posSubZone(2:end)],'UniformOutput',false);
        [~,seqName] = fileparts(txt(posSubSeqName(1)+20:posParamSummary(acquisitionNumber)-3));
    else
        seqName = filename;
    end

    % merge all the parameters for this acquisition of dispersion
    parameter(acquisitionNumber) = merge([parameter(acquisitionNumber),paramZone]);
    % Additional fields are needed that are not present in sdf v2
    parameter(acquisitionNumber).paramList.FILE = filename;
    parameter(acquisitionNumber).paramList.EXP = seqName;
    
    % now get the data for that acquisition
    if isfield(parameter(acquisitionNumber).paramList,'BS')
        bs = parameter(acquisitionNumber).paramList.BS;
    else
        bs = 1;
    end
    if isfield(parameter(acquisitionNumber).paramList,'NBLK')
        nblk = parameter(acquisitionNumber).paramList.NBLK;
    else
        nblk = 1;
    end
    nLines = bs*nblk; % number of lines to read
    % get the name of the column variables (only need to do this on one
    % line, they are all the same for a given experiment)
    colNameLine = textscan(txt(posSubData(1):posSubData(1)+1000),'%s',1,'delimiter','\n','HeaderLines',1);
    colName = strsplit(colNameLine{1}{1},[char(9) char(9)])';
    colName{strncmp(colName,'TIME',4)} = 'TIME';  % remove imcompatible characters for field names
    % make sure the field names are consistent with previous versions
    colName = strrep(colName,'REAL','real');
    colName = strrep(colName,'IMG','imag');
    colName = strrep(colName,'TIME','time');
    
    % now read the data
    indEnd = arrayfun(@(i)min([posSeqName(posSeqName>i) length(txt)]),posSubData); % indexes of the end of the data blocs
    format = repmat('%f ',1,length(colName));
    data = arrayfun(@(i,e)textscan(txt(i:e),format,nLines,'delimiter','\n ','HeaderLines',2),posSubData,indEnd,'UniformOutput',0);
    
    % finally, place the data into the corresponding fields of the dataContent structure
    for nField = 1:length(colName)
        if ~isfield(dataContent,colName{nField}) % initialise the fields
            dataContent = setfield(dataContent,colName{nField},cell(1,acquisitionNumber)); %#ok<*SFLD>
        end
        for indDisp = 1:length(data)
            dataContent.(colName{nField}){acquisitionNumber}(:,:,indDisp) = reshape(data{indDisp}{nField},bs,nblk);
        end
    end
    
end
    
