function export_data(hFile, path)
%
% This function allows to export dispersion data in formatted .txt file.
% 
% Input:
% *hFile: 1xN RelaxObj object containing Dispersion object(s). You can use
%         RelaxObj that contains different number of Dispersion object 
%         and/or different x-values.
% *path (Optional): string corresponding to the path where output .txt 
%                   files are stored. If this string is not given, the
%                   function create a window to select the output folder.
%
% Output:
% *.txt file containing all the dispersion data of the input files. 
%
% Format:
% .txt file contains three parts: Header, Processing and Data
%
% Example with N Dispersion object
%
% Header lines: ...
% Date: ...
%
% HEADER
% Label: {1xN cell array of string}
% Dataset: {1xN cell array of string}
% Sequence: {1xN cell array of string}
% Filename: {1xN cell array of string}
% DisplayName: {1xN cell array of string}
%
% PROCESSING
%      1              2          ...
% 1 AverageAbs  SignAverage      ...
% 2 Monoexp     Monoexp          ...
%
% DATA
% X   Y1  Y2  Y3...
% ... ... ... ... ...
% ... ... ... ... ...
% ... ... ... ... ...
%
% ERROR
% X   DY1 DY2 DY3...
% ... ... ... ... ...
% ... ... ... ... ...
%
% Note: number (1,2,3,...) corresponds to the header index (dataset,
% filename,...) i.e. Y1 corresponds to dataset{1}, sequence{1},... Same
% indexing is used for errors (DY1,...) and for PROCESSING.
% 
% M.Petit - 03/2019
% manuel.petit@inserm.fr


% check input
if isempty(hFile)
    error('ExportData: No data input')
elseif ~isa(hFile,'RelaxObj')
    error('ExportData: Input should be RelaxObj object')
end

% ask user a path if needed
if nargin < 2
    path = uigetdir(pwd, 'Export Dispersion data');
end

% check if files contains dispersion data
dispersion = arrayfun(@(x) getData(x,'Dispersion'), hFile, 'Uniform', 0);
tf = cellfun(@isempty, dispersion);

if all(tf == 1)
    error('No dispersion data found in files')
elseif any(tf == 1)
    str = sprintf('%s\n', hFile(tf).filename);
    warning('Some file(s) are empty (no dispersion data) and will be ignored:\n%s',str)
    dispersion = dispersion(~tf);
end
dispersion = [dispersion{:}];

n = numel(dispersion);
% init header
displayName = cell(1,n);
filename = cell(1,n);
sequence = cell(1,n); 
label = cell(1,n);
dataset = cell(1,n);

% init processing
processing = [];

% init x-values (make sure we have column vector)
x = {dispersion.x};
tf = ~cellfun(@iscolumn, x);
x(tf) = cellfun(@(x) x', x(tf), 'Uniform', 0);
X = unique(vertcat(x{:}));

Y = nan(numel(X), n);
DY = nan(numel(X), n);

% gather data
for k = 1:n
    % fill header information
    dataset{k} = getRelaxProp(dispersion(k), 'dataset');
    sequence{k} = getRelaxProp(dispersion(k), 'sequence');
    filename{k} = getRelaxProp(dispersion(k), 'filename');
    label{k} = getRelaxProp(dispersion(k), 'label');
    displayName{k} = dispersion(k).displayName;
    
    % get processing information
    hParent = dispersion(k);
    count = 1; list_process = [];
    while ~isempty(hParent.parent)
        hParent = hParent.parent;
        list_process{count,1} = class(hParent.processingMethod); %#ok<AGROW>
        count = count + 1;
    end
    list_process = [{num2str(k)}; flip(list_process)];

    if isempty(processing)
        processing = list_process;
    else
        % add new processing
        n = size(processing,1); m = numel(list_process);
        if n > m
            list_process = [list_process; cell(n-m,1)]; %#ok<AGROW>
        elseif m < n
            processing = [processing; cell(m-n,size(processing,2))]; %#ok<AGROW>
        end
        processing = [processing, list_process]; %#ok<AGROW>
    end
    
    % get data (do not include masked data)
    x = dispersion(k).x(dispersion(k).mask);
    y = dispersion(k).y(dispersion(k).mask); if ~iscolumn(y); y = y'; end
    dy = dispersion(k).dy(dispersion(k).mask); if ~iscolumn(dy); dy = dy'; end
    
    % prepare Y-values according to the x-values found
    [~,idx,~] = intersect(X, x);
    Y(idx,k) = y;
    DY(idx,k) = dy;
end %for loop

% struct processing output
processing = [vertcat({'Dispersion index:'},...
    cellfun(@num2str, num2cell(1:size(processing,1)-1)', 'Uniform', 0)), processing];

% open file: 'filename.txt'
fid = fopen(strcat(path,'\','export_dispersion.txt'), 'w');

% set header
fprintf(fid,'Header lines:,\t%d,\r\n', 12+size(processing,1));
fprintf(fid,'Date:,\t%s,\r\n\r\n', datetime('today'));

fprintf(fid,'HEADER,\r\n');
fprintf(fid,'Label:,\t%s\r\n', sprintf('%s,\t',label{:}));
fprintf(fid,'Dataset:,\t%s\r\n', sprintf('%s,\t',dataset{:}));
fprintf(fid,'Sequence:,\t%s\r\n', sprintf('%s,\t',sequence{:}));
fprintf(fid,'Filename:,\t%s\r\n', sprintf('%s,\t',filename{:}));
fprintf(fid,'Name:,\t%s\r\n\r\n', sprintf('%s,\t',displayName{:}));

% set processing
fprintf(fid,'PROCESSING:,\r\n');
format = [repmat('%s,\t',1,size(processing,2)-1),'%s,\r\n'];
for k = 1:size(processing,1)
    line = processing(k,:);
    fprintf(fid, format, line{:});
end

% set data
% + Y values
fprintf(fid,'\r\nDATA:,\r\n');
fprintf(fid,'%8s,\t','X');
for k = 1:size(Y,2)-1
    fprintf(fid,'%8s,\t',['Y',num2str(k)]);
end
fprintf(fid,'%8s,\r\n',['Y',num2str(size(Y,2))]);

format = [repmat('%8f,\t',1,size(Y,2)),'%8f,\r\n'];
for k = 1:numel(X) %line by line to avoid NaN problem
    fprintf(fid,format,[X(k), Y(k,:)]);
end

% + DY values
fprintf(fid,'\r\nERROR:,\r\n');
fprintf(fid,'%8s,\t','X');
for k = 1:size(DY,2)-1
    fprintf(fid,'%8s,\t',['DY',num2str(k)]);
end
fprintf(fid,'%8s,\r\n',['DY',num2str(size(DY,2))]);

format = [repmat('%8f,\t',1,size(DY,2)),'%8f,\r\n'];
for k = 1:numel(X) %line by line to avoid NaN problem
    fprintf(fid,format,[X(k), DY(k,:)]);
end

% close file
fclose(fid);
end

