function [data, parameter] = readsdfv1(filename, formatFile)
%
% [DATA, PARAMETER] = READSDFV1(FILENAME, FORMATFILE) read data from a 
% Stelar file .sdf version 1. Version 1 is organised as pair of
% header(parameter)/data for each "ZONE". FORMATFILE is a .mat file that
% helps the file reading. If this .mat file does not exist, a new one is
% created under the name FORMATFILE. See determineColumnSelectionGUI() for
% further information about this file.
%
% Warning: always use the same FORMATFILE to avoid apparition of Data 
% Helper GUI (and speed up the process). 
%
% READSDFV1 returns Stelar parameters as 1xN cell array of structure where N
% corresponds to the number of experiment. Similarely, data is return as a
% structure where each field is a 1xN cell array of 3D matrix (double).
%
% An experiment is defined by the succession (or not) of "ZONE" with
% identical data size (BS, NBLK), identical parameter structure (fieldnames)
% and identical sequence name (EXP field).
%
% READSDFV1 concatenates successive "ZONE" belonging to the same experiment 
% along the third dimension resulting in a 3D matrix (for each data fields:
% time, real, imag, ...).
% For example: size(data.time) = [BS, NBLK, nZONE]. 
%
% Example:
% formatFile = 'settings.mat';
% filename = 'myfolder/stelar_data.sdf';
% [data, parameter] = readsdfv1(filename, formatFile);
%
% See also READSDFV2, DETERMINECOLUMNSELECTIONGUI
%
% Manuel Petit, June 2018
% manuel.petit@inserm.fr

N_MAX_PARAMETERS = 150; % maximum number of parameter in the header
iAcq = 1; % number of acquisition

% open file and check if ok
fid = fopen(filename, 'r'); % open the file in read only mode
if fid == -1
    errordlg(['File ' filename ' not found!'])
    return
end

% get the name of the file
[~,name,~] = fileparts(filename);

% check the formatFile existence: to change if formatFile moved
listFile = dir();
if nargin > 1 % check if the file was given at the first place
    if sum(strcmp({listFile.name}, formatFile)) == 0
        formatFlag = 0;
    else
        formatFlag = 1;
    end
else
    formatFlag = 0; % if the user does not have a format file, start the allocation process
end

% loop over the acquisitions 
while 1 
    %% Get the header information   
    % Find the length of the header by reading a bloc and catch 'DATA'
    pos = ftell(fid); %memorize the position       
    txt = textscan(fid,'%s',N_MAX_PARAMETERS,'delimiter','\r'); %read the bloc
    
    offset = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'ZONE')),1); %find the offset: 'ZONE'
    nRow = find(cellfun(@(x) ~isempty(x),strfind(txt{1},'DATA')),1) - offset + 1; %get the number of rows  by finding 'DATA'  
    
    if isempty(offset) || isempty(nRow) %eof condition
        % simplify the last structure if possible
        if length(parameter{iAcq}) > 1
            parameter{iAcq} = arrayofstruct2struct(parameter{iAcq}); %#ok<AGROW>
        end
        break %end of the file
    end     
 
    % Read the header. Stelar .sdf files are organized as:
    % [parameterName (4 characters), '=', value (n characters)]
    fseek(fid,pos,'bof'); %replace the position
    hdr = textscan(fid, '%5s %s', nRow, 'delimiter', '\r','Headerlines',offset-1);
    % Format the header's field
    hdr{1} = regexprep(hdr{1},'=',''); %remove the '=' symbol from the parameter's field
    hdr{1} = strtrim(hdr{1}); %deblank the input      
    % Format the header's values
    isdouble = cellfun(@str2double, hdr{2}); % Really slow, need to be speed up
    hdr{2}(~isnan(isdouble)) = num2cell(isdouble(~isnan(isdouble)));
    % Create the header
    header = cell2struct(hdr{2},hdr{1},1); 
    % Add filename
    header.FILE = name;
    
    %% Get the data 
    if header.NBLK == 0 % this happens when the sequence is not staggered (not over multiple fields such as PP, NP, etc...)
        header.NBLK = 1;
    end
    pos = ftell(fid); %memorize the position     
    fgets(fid); %move to the next line
    
    % count the number of column before reading
    ncol = numel(regexp(fgets(fid),'\d*'));
    
    % create the format 
    format = [repmat('%f ',1,ncol-1),'%f'];   
    % read the data
    fseek(fid,pos,'bof'); %replace the position
    bloc = textscan(fid, format, ...
              header.NBLK*header.BS, 'delimiter',' ');
    bloc = [bloc{:}]; % append columns
    
    % Use the formatFile to know which column corresponds to the real and
    % imag signal. If unknown call GUI so user can do it
    if ~formatFlag
        % no formatFile exists: create it
        % call a GUI to help user to select its columns
        [realcol, imagcol, timecol] = determineColumnSelectionGUI(name,...
            header.EXP, ncol, bloc, [], formatFile);
        % check if formatFile has been created
        if sum(strcmp({listFile.name}, formatFile))
            formatFlag = 1;
        end
    else
        % open the formatFile and get the table T
        formatObj = load(formatFile);
        var = fieldnames(formatObj);
        T = formatObj.(var{1});    
        % check if the sequence/format is already known
        isKnown = strcmp(T.Sequence, header.EXP) & T.nCol == ncol;
        if sum(isKnown)
            % get the index
            realcol = T.realIdx(isKnown);
            imagcol = T.imagIdx(isKnown);
            timecol = T.timeIdx(isKnown);
        else
            % call GUI
            [realcol, imagcol, timecol] = determineColumnSelectionGUI(name,...
                header.EXP, ncol, bloc, [], formatFile);
        end
    end
    
    % check output
    if isempty(realcol)
        errordlg('File not openned: no column index found!')
        continue
    end
    
    % select real and imag according to the index selected
    % initialise as 3D to fit with output format
    real = bloc(:,realcol);
    imag = bloc(:,imagcol);   
    % format the data 
    real = reshape(real,[header.BS,header.NBLK]);
    imag = reshape(imag,[header.BS,header.NBLK]);
    
    %+ Generate the time axis and other related data 
    if isfield(header,'EDLY') % if echo used
        header.DELAY = header.SWT+2*header.EDLY; % delay between the readout pulse and the first measurement
        timeFactor = header.EDLY;
    else
        header.DELAY = header.SWT;
        timeFactor = header.DW;
    end
    
    if isnan(timecol)
        time = timeFactor*1e-6*(1:header.BS);
        time = repmat(time',1,header.NBLK); %just rep to obtain same dim as real and imag
    else
        time = bloc(:,timecol);
        time = reshape(time,[header.BS, header.NBLK]);
    end 
    
    %+ concatenate the data if the fields, the sequence and the data size are
    %the same
    if ~exist('parameter','var')
        % first loop
        data.time{iAcq} = time;
        data.real{iAcq} = real;
        data.imag{iAcq} = imag;
        parameter{iAcq} = header; %#ok<AGROW>
    elseif isequal(fieldnames(parameter{iAcq}),fieldnames(header)) &&...
            size(data.time{iAcq},1) == size(time,1) &&...
            size(data.time{iAcq},2) == size(time,2) &&...
            isequal(parameter{iAcq}.EXP,header.EXP)
        % concatenate the acquisitions
        data.time{iAcq} = cat(3,data.time{iAcq}, time);
        data.real{iAcq} = cat(3,data.real{iAcq}, real);
        data.imag{iAcq} = cat(3,data.imag{iAcq}, imag);
        parameter{iAcq} = [parameter{iAcq} header]; %#ok<AGROW>
    else
        % simplify the previous structure if possible
        if length(parameter{iAcq}) > 1
            parameter{iAcq} = arrayofstruct2struct(parameter{iAcq}); %#ok<AGROW>
        end
        % create a new acquisition storage
        iAcq = iAcq + 1;
        data.time{iAcq} = time;
        data.real{iAcq} = real;
        data.imag{iAcq} = imag;
        parameter{iAcq} = header; %#ok<AGROW>
    end
end %while

%% Tidying up
fclose(fid);

end

