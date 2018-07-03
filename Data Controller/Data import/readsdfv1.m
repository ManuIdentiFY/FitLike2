function [bloc, parameters] = readsdfv1(path,filename)
%
% [BLOC, PARAMETERS] = READSDFV1(PATH,FILENAME) reads data from a Stelar file .sdf
% version 1. It returns the data as DataUnit and the parameters as cells.
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
% path = 'myfolder/';
% filename = 'stelar_data.sdf';
% [bloc, parameters] = readsdfv1(path,filename);
%
% See also DATAUNIT, READSDFV2
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr


N_MAX_PARAMETERS = 150; % maximum number of parameter in the header

bloc = DataUnit(); % preallocation 
parameters = cell(1,1); %preallocation
iAcq = 1; % number of acquisition

fid = fopen([path filename], 'r'); % open the file in read only mode

%% Read the file
while 1 
    %+ Get the header information   
    % Find the length of the header by reading a bloc and catch 'DATA'
    pos = ftell(fid); %memorize the position       
    txt = textscan(fid,'%s',N_MAX_PARAMETERS,'delimiter','\r'); %read the bloc
    if length(txt{1}) < N_MAX_PARAMETERS
        % simplify the last structure if possible
        if length(parameters{iAcq}) > 1
            parameters{iAcq} = arrayofstruct2struct(parameters{iAcq});
        end
        break %end of the file
    end     
    offset = find(startsWith(txt{1},'ZONE'),1); %find the offset (all cells before 'ZONE')
    nRow = find(startsWith(txt{1},'DATA'),1) - offset + 1; %get the number of rows  by finding 'DATA'   
    % Read the header
    fseek(fid,pos,'bof'); %replace the position
    hdr = textscan(fid, '%5s %s', nRow, 'delimiter', '\r','Headerlines',offset-1);
    % Format the header's field
    hdr{1} = regexprep(hdr{1},'=',''); %remove the '=' symbol from the parameter's field
    hdr{1} = strtrim(hdr{1}); %deblank the input      
    % Format the header's values
    isdouble = cellfun(@str2double, hdr{2}); 
    hdr{2}(~isnan(isdouble)) = num2cell(isdouble(~isnan(isdouble)));
    % Create the header
    header = cell2struct(hdr{2},hdr{1},1); 
    % Add filename
    header.FILE = filename;
    
    %+ Get the data 
    if header.NBLK == 0 % this happens when the sequence is not staggered (not over multiple fields such as PP, NP, etc...)
        header.NBLK = 1;
    end
    pos = ftell(fid); %memorize the position  
    fgets(fid); %move to the next line
    % count the number of column before reading
    ncol = numel(regexp(fgets(fid),'\d*'));
    % set the delimiter according to the number of columns and the type
    % of sequence (if CPMG, take column 2 and 3; if not 1 and 2)
    switch ncol
        case 2
            format = '%f %f';
        case 3
            format = '%*f %f %f';
        otherwise
            % ask the user
            % TO DO
    end
    % read the data
    fseek(fid,pos,'bof'); %replace the position
    data = textscan(fid, format, ...
              header.NBLK*header.BS, 'delimiter',' ');
    % format the data 
    data = complex(data{1},data{2});
    data = reshape(data,[header.BS,header.NBLK]);
    
    %+ Generate the time axis and other related data 
    if isfield(header,'EDLY') % if an echo is used
        ListDelay = header.SWT+2*header.EDLY; % delay between the readout pulse and the first measurement
        time = header.EDLY*1e-6*(1:header.BS);
    else
        ListDelay = header.SWT;           
        time = header.DW*1e-6*(1:header.BS);
    end
    header.DELAY = 1e-6*ListDelay;     
    
    %+ concatenate the data if the fields, the sequence and the data size are
    %the same
    if isempty(parameters{iAcq})
        % first loop
        bloc(iAcq) = DataUnit('dataType','bloc','x',time','xLabel',...
               'Time (us)','y',data,'yLabel','A.U.');  %creation of an object 'StelarData'
        parameters{iAcq} = header;
        continue
    elseif isequal(fieldnames(parameters{iAcq}),fieldnames(header)) &&...
            size(bloc(iAcq).y,1) == size(data,1) &&...
            size(bloc(iAcq).y,2) == size(data,2) &&...
            isequal(parameters{iAcq}.EXP,header.EXP) &&...
            size(bloc(iAcq).x,1) == size(time',1)
        % concatenate the acquisitions
        bloc(iAcq).x = cat(3,bloc(iAcq).x,time');
        bloc(iAcq).y = cat(3,bloc(iAcq).y,data);
        resetmask(bloc(iAcq));
        parameters{iAcq} = [parameters{iAcq} header];
    else
        % simplify the previous structure if possible
        if length(parameters{iAcq}) > 1
            parameters{iAcq} = arrayofstruct2struct(parameters{iAcq});
        end
        % create a new acquisition storage
        iAcq = iAcq + 1;
        bloc(iAcq) = DataUnit('dataType','bloc','x',time','xLabel',...
               'Time (us)','y',data,'yLabel','A.U.');  %creation of an object 'StelarData'
        parameters{iAcq} = header;
    end
end %while

end

