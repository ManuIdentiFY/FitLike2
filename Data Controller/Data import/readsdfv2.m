function [dataContent, parameter] = readsdfv2(fid)

% [BLOC, PARAMETERS] = READSDFV2(FID) reads data from a Stelar file .sdf
% version 2. Use FOPEN to open the file and obtain FID. It returns the data
% as DataUnit and the parameters as cells.
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
%
% Example:
% filename = 'stelar_data.sdf';
% fid = fopen(filename, 'r');
% [bloc, parameters] = readsdfv2(fid);
%
% See also DATAUNIT, READSDFV1
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr
%
% Modified by L Broche 2018
% l.broche@abdn.ac.uk

%% Preparations and preallocations
% the import startegy relies on finding key words at regular intervals
% ('PARAMETERS SUMMARY', 'NMRD SEQUENCE NAME' and 'DATA'). For efficiency we have to suppose that
% these two words are less than 150 lines apart for a given bloc.
N_MAX_PARAMETERS = 150; % maximum number of parameter in the header

% formating the output structure
dataContent = struct();
acquisitionNumber = 0; % index of the acquisition being processed
frewind(fid); % read the file from the start
 
%% Read the file
while 1 
    startPos = ftell(fid); %memorize the position  % remember the position of the start of the current bloc
    
    % Get the header information   
    % Find the length of the header by reading a large section and catch 'DATA'
    txt = textscan(fid,'%s',N_MAX_PARAMETERS,'delimiter','\n');
    if feof(fid) % check for end file, exit if found
        break 
    end  
    
    % check the content of the headers.
    posParamSummary = find(startsWith(txt{1},'PARAMETER SUMMARY'),1)+1;
    posZone = find(startsWith(txt{1},'ZONE'),1);
    posData = find(startsWith(txt{1},'DATA'),1);
    
    if ~isempty(posParamSummary)||isempty(parameter(acquisitionNumber))
        % now store the incoming data and parameters into a new section.
        acquisitionNumber = acquisitionNumber+1;
        dispNumber = 0;
        fseek(fid,startPos,'bof'); % back to the 'PARAMETER SUMMARY' line
        % get the parameters into a new structure:
        parameter{acquisitionNumber} = text2structure(txt{1}(posParamSummary+1:posZone-1));

    end
        
    % now extracting the data from each bloc, with the corresponding parameters 
    % starting with the additional parameters:
    dispNumber = dispNumber + 1;
    paramZone = text2structure(txt{1}(posZone + 1 : posData -1));
    fieldName = fields(paramZone);
    % change fields names for consistency with previous versions
    fieldName = replace(fieldName,'BR','BRLX');
    fieldName = replace(fieldName,'T1MAX','T1MX');
    % get the values
    fieldCont = struct2cell(paramZone);
%     if zoneNumber == 1 % initialise the fields
%         for nField = 1:length(fieldName)
%             parameter =...
%                     setfield(parameter,{acquisitionNumber},fieldName{nField},{1},{}); %#ok<*SFLD>
%         end
%     end
    for nField = 1:length(fieldName)
        parameter{acquisitionNumber} = setfield(parameter{acquisitionNumber},{1},fieldName{nField},{dispNumber},fieldCont{nField});
    end
    
    % get the data
    colName = split(txt{1}{posData+1},[char(9) char(9)])';
    colName{strncmp(colName,'TIME',4)} = 'TIME';  % remove imcompatible characters for field names
    % make sure the field names are consistent with previous versions
    colName = replace(colName,'REAL','real');
    colName = replace(colName,'IMG','imag');
    colName = replace(colName,'TIME','time');
    for nField = 1:length(colName)
        if ~isfield(dataContent,colName{nField}) % initialise the fields
            dataContent = setfield(dataContent,colName{nField},cell(1,acquisitionNumber)); %#ok<*SFLD>
        end
    end
    % store the data at the correct place
    fseek(fid,startPos,'bof');
    if isfield(parameter{acquisitionNumber},'BS')
        bs = parameter{acquisitionNumber}.BS;
    else
        bs = 1;
    end
    if isfield(parameter{acquisitionNumber},'NBLK')
        nblk = parameter{acquisitionNumber}.NBLK;
    else
        nblk = 1;
    end
    nLines = bs*nblk;
    data = textscan(fid,'%f %f %f %f',nLines,'delimiter',' ','HeaderLines',posData+1);
    for nField = 1:length(colName)
        c = getfield(dataContent,colName{nField});
        c{acquisitionNumber}(:,:,dispNumber) = reshape(data{nField},bs,nblk);
        dataContent = setfield(dataContent,colName{nField},c);
    end
       
    
end %while




