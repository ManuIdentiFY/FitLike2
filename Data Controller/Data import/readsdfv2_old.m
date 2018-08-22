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
txt = textscan(fid,'%s','delimiter','\n');
txt = txt{1}; % remove the extra nesting for convenience
fclose(fid);

%% Preparations and preallocations
% the import startegy relies on finding key words at regular intervals
% ('PARAMETERS SUMMARY', 'NMRD SEQUENCE NAME' and 'DATA'). 

% formating the output structure
dataContent = struct();
parameter = []; % parameter array containing one element per dispersion dataset

%% Sort the data

% the header 'PARAMETER SUMMARY' separated each new dispersion acquisition
posParamSummary = find(strcmp(txt,'PARAMETER SUMMARY'));  % cannot use startWith for compatibility reasons with version older than 2017a
if isempty(posParamSummary) 
    return % exit if empty file
end

% now find the position of all the data zones and corresponding raw data
posSeqName = find(cellfun(@(x) ~isempty(x),strfind(txt,'NMRD SEQUENCE NAME:'))); 
posZone = find(cellfun(@(x) ~isempty(x),strfind(txt,'ZONE')));
posData = find(strcmp(txt,'DATA'));

% find the 'ZONE' labels that stop the 'PARAMETER SUMMARY sections
posSeqEnd = arrayfun(@(posIni)min(posZone(posZone>posIni)-posIni),posParamSummary);
posSeqEnd = posSeqEnd + posParamSummary;

% store the general lists of parameters
parameter = arrayfun(@(start,stop)ParamV2(text2structure(txt(start+1:stop-1))),posParamSummary,posSeqEnd,'UniformOutput',0);
parameter = [parameter{:}];

% collects the data for each dispersion acquisition
posParamSummary(end+1) = length(txt);
for acquisitionNumber = 1:length(parameter)
    % make a list of all the parameter structures to be merged later. Usually
    % contains BR and T1MAX, and in general contains the parameters that change
    % at each iteration
    posSubZone = posZone((posZone>=posParamSummary(acquisitionNumber)) & (posZone < posParamSummary(acquisitionNumber+1)));
    posSubData = posData((posZone>=posParamSummary(acquisitionNumber)) & (posZone < posParamSummary(acquisitionNumber+1)));
    posSubSeqName = posSeqName((posSeqName>=posParamSummary(acquisitionNumber)-2) & (posSeqName < posParamSummary(acquisitionNumber+1)-2)); % careful: this line comes before the parameters summary
    paramZone = arrayfun(@(start,stop)ParamV2(text2structure(txt(start+1:stop-1))),posSubZone,posSubData,'UniformOutput',0);
    paramZone = [paramZone{:}];
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
        [~,seqName] = arrayfun(@(ind)fileparts(txt{ind}(21:end)),posSubSeqName,'UniformOutput',false);
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
    data = arrayfun(@(start)cell2mat(cellfun(@(t)textscan(t,'%f'),txt(start+2:start+1+nLines))),posSubData,'UniformOutput',0); % all the data in one line
    data = cell2mat(data);
    
    % get the name of the column variables (only need to do this on one
    % line, they are all the same for a given experiment)
    colName = strsplit(txt{posSubData(1)+1},[char(9) char(9)])';
    colName{strncmp(colName,'TIME',4)} = 'TIME';  % remove imcompatible characters for field names
    % make sure the field names are consistent with previous versions
    colName = strrep(colName,'REAL','real');
    colName = strrep(colName,'IMG','imag');
    colName = strrep(colName,'TIME','time');
    for nField = 1:length(colName)
        if ~isfield(dataContent,colName{nField}) % initialise the fields
            dataContent = setfield(dataContent,colName{nField},cell(1,acquisitionNumber)); %#ok<*SFLD>
        end
        d = reshape(data(nField:length(colName):end),bs,nblk,length(posSubData));
        dataContent.(colName{nField}){acquisitionNumber}= d;
    end
    
end
    


% 
% 
% %% open the file and check the result
% 
% fid = fopen(filename, 'r'); % open the file in read only mode
% if fid == -1
%     errordlg(['File ' filename ' not found!'])
%     return
% end
% 
% %% Preparations and preallocations
% % the import startegy relies on finding key words at regular intervals
% % ('PARAMETERS SUMMARY', 'NMRD SEQUENCE NAME' and 'DATA'). For efficiency we have to suppose that
% % these two words are less than 150 lines apart for a given bloc.
% N_MAX_PARAMETERS = 150; % maximum number of parameter in the header
% 
% % formating the output structure
% dataContent = struct();
% acquisitionNumber = 0; % index of the acquisition being processed
% frewind(fid); % read the file from the start
% dispNumber = 0;
%  
% %% Read the file
% while 1 
%     startPos = ftell(fid); %memorize the position  % remember the position of the start of the current bloc
%     
%     % Get the header information   
%     % Find the length of the header by reading a large section and catch 'DATA'
%     txt = textscan(fid,'%s',N_MAX_PARAMETERS,'delimiter','\n');
%     if feof(fid) % check for end file, exit if found
%         if acquisitionNumber>0
%             parameter(acquisitionNumber).paramList.T1MX = parameter(acquisitionNumber).paramList.T1MX*1e-6; % convert to seconds
%             parameter(acquisitionNumber).paramList.BRLX = parameter(acquisitionNumber).paramList.BRLX*1e6;  % convert to Hz
%             parameter(acquisitionNumber).paramList.FILE = filename;
%             parameter(acquisitionNumber).paramList.EXP = seqName;
%         end
%         break 
%     end  
%     
%     % check the content of the headers.
%     posSeqName = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'NMRD SEQUENCE NAME:'))); 
%     if ~isempty(posSeqName)
%         [~,seqName] = fileparts(txt{1}{posSeqName}(21:end));
%     end
%     posParamSummary = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'PARAMETER SUMMARY')),1)+1;  % cannot use startWith for compatibility reasons with version older than 2017a
%     posZone = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'ZONE')),1);
%     posData = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'DATA')),1);
%     
%     % finalise the previous acquisition if it reached another one
%     if acquisitionNumber > 0
%         if ~isempty(posParamSummary) || isempty(parameter(acquisitionNumber))
%             if acquisitionNumber > 0
%                 fname = fields(parameter(acquisitionNumber).paramList);
%                 for ind = 1:length(fname)
%                     cont = getfield(parameter(acquisitionNumber),fname{ind});
%                     if length(cont)>1 && iscell(cont)
%                         if isnumeric(cont{1})
%                             parameter(acquisitionNumber) = setfield(parameter(acquisitionNumber),fname{ind},cell2mat(cont)); %#ok<AGROW>
%                         end
%                     end
%                 end
%                 parameter(acquisitionNumber).paramList.T1MX = parameter(acquisitionNumber).paramList.T1MX*1e-6; % convert to seconds
%                 parameter(acquisitionNumber).paramList.BRLX = parameter(acquisitionNumber).paramList.BRLX*1e6;  % convert to Hz
%                 parameter(acquisitionNumber).paramList.FILE = filename;
%                 parameter(acquisitionNumber).paramList.EXP = seqName;
%             end
%             % now store the incoming data and parameters into a new section.
%             acquisitionNumber = acquisitionNumber+1;
%             dispNumber = 0;
%             fseek(fid,startPos,'bof'); % back to the 'PARAMETER SUMMARY' line
%             % get the parameters into a new structure:
%             parameter(acquisitionNumber) = ParamV2(text2structure(txt{1}(posParamSummary+1:posZone-1)));
%         end
%     end
%         
%     % now extracting the data from each bloc, with the corresponding parameters 
%     % starting with the additional parameters:
%     dispNumber = dispNumber + 1;
%     paramZone = ParamV2(text2structure(txt{1}(posZone + 1 : posData -1)));
%     % change fields names for consistency with previous versions
%     paramZone = changeFieldName(paramZone,'BR','BRLX');
%     paramZone = changeFieldName(paramZone,'T1MAX','T1MX');
%     % get the values
% %     fieldCont = struct2cell(paramZone);
% %     for nField = 1:length(fieldName)
% %         parameter(acquisitionNumber) = setfield(parameter(acquisitionNumber),{1},fieldName{nField},{dispNumber},{fieldCont{nField}});
% %     end
%     parameter(acquisitionNumber) = merge(parameter(acquisitionNumber),paramZone);
%     
%     % get the data
%     colName = strsplit(txt{1}{posData+1},[char(9) char(9)])'; % cannot use split for compatibility reasons with version older than 2018a
%     colName{strncmp(colName,'TIME',4)} = 'TIME';  % remove imcompatible characters for field names
%     % make sure the field names are consistent with previous versions
%     colName = strrep(colName,'REAL','real');
%     colName = strrep(colName,'IMG','imag');
%     colName = strrep(colName,'TIME','time');
%     for nField = 1:length(colName)
%         if ~isfield(dataContent,colName{nField}) % initialise the fields
%             dataContent = setfield(dataContent,colName{nField},cell(1,acquisitionNumber)); %#ok<*SFLD>
%         end
%     end
%     % store the data at the correct place
%     fseek(fid,startPos,'bof');
%     if isfield(parameter(acquisitionNumber).paramList,'BS')
%         bs = parameter(acquisitionNumber).paramList.BS;
%     else
%         bs = 1;
%     end
%     if isfield(parameter(acquisitionNumber).paramList,'NBLK')
%         nblk = parameter(acquisitionNumber).paramList.NBLK;
%     else
%         nblk = 1;
%     end
%     nLines = bs*nblk;
%     data = textscan(fid,'%f %f %f %f',nLines,'delimiter',' ','HeaderLines',posData+1);
%     for nField = 1:length(colName)
%         c = getfield(dataContent,colName{nField}); %#ok<*GFLD>
%         c{acquisitionNumber}(:,:,dispNumber) = reshape(data{nField},bs,nblk);
%         dataContent = setfield(dataContent,colName{nField},c);
%     end
%        
%     
% end %while
% 
% % finalise last acquisition...
% if acquisitionNumber > 0
%     fname = fields(parameter(acquisitionNumber).paramList);
%     for ind = 1:length(fname)
%         cont = getfield(parameter(acquisitionNumber).paramList,fname{ind});
%         if length(cont)>1 && iscell(cont)
%             if isnumeric(cont{1})
%                 parameter(acquisitionNumber) = setfield(parameter(acquisitionNumber),fname{ind},cell2mat(cont));
%             end
%         end
%     end
% end
% 
% %% Tidying up
% fclose(fid);
% 
