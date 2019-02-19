function export_data(hData, path)
%
% This function allows to export dispersion data in formatted .txt file.
%

% check input
if isempty(hData)
    error('ExportData: No data input')
elseif ~isa(hData,'Dispersion')
    error('ExportData: Input should be dispersion data')
end

% ask user a path if needed
if nargin < 2
    path = uigetdir(pwd, 'Export Dispersion data');
end

% loop over the dispersion data
for k = 1:numel(hData)
    % get processing information
    hParent = hData(k);
    count = 1;
    while ~isempty(hParent.parent)
        hParent = hParent.parent;
        mdl{count,1} = hParent.processingMethod; %#ok<AGROW>
        count = count + 1;
    end
    
    % get data and check size (need column)
    x = hData(k).x(hData(k).mask); if ~isrow(x); x = x'; end
    y = hData(k).y(hData(k).mask); if ~isrow(y); y = y'; end
    dy = hData(k).dy(hData(k).mask); if ~isrow(dy); dy = dy'; end
    
    
    % open file: 'filename.txt'
    fid = fopen(strcat(path,'\',hData(k).filename,'.txt'), 'w');
    
    % set header
    fprintf(fid,'Header lines:,\t%d,\r\n\r\n', 12+numel(mdl));
    fprintf(fid,'HEADER,\r\n');
    fprintf(fid,'Date:,\t%s,\r\n', datetime('today'));
    fprintf(fid,'Dataset:,\t%s,\r\n', hData(k).dataset);
    fprintf(fid,'Sequence:,\t%s,\r\n', hData(k).sequence);
    fprintf(fid,'Filename:,\t%s,\r\n', hData(k).filename);
    fprintf(fid,'Label:,\t%s,\r\n\r\n', hData(k).label);
    
    % set processing
    fprintf(fid,'PROCESSING:,\r\n');
    mdl = flip(mdl);
    for p = 1:numel(mdl) % to get the oldest first
        c = superclasses(mdl{p});
        fprintf(fid,'%d,\t%s,\t%s,\r\n', p, mdl{p}.functionName, c{1});
    end

    % set data
    fprintf(fid,'\r\nDATA:,\r\n');
    fprintf(fid,'%8s,\t%8s,\t%8s,\r\n','X','Y','DY');
    fprintf(fid,'%8f,\t%8f,\t%8f,\r\n',[x, y, dy].');
    
    % close file
    fclose(fid);
end %for loop
end

