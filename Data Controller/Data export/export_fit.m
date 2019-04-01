function export_fit(hData, path)
%
% This function allows to export fit data from Dispersion object in 
% formatted .txt file. If more than one model class is encountered,
% export_fit returned as many as .txt files than the number of unique
% model.
% 
% Input:
% *hData: 1xN Dispersion object. Be sure that a fit model is stored in your
%         Dispersion object (processingMethod property).
% *path (Optional): string corresponding to the path where output .txt 
%                   files are stored. If this string is not given, the
%                   function create a window to select the output folder.
%
% Output:
% *.txt file containing all the fit results of the input files. 
%
% Examples:
% export_fit(dispersion); dispersion is 1xN Dispersion
% export_fit(dispersion, pathname); pathname for saved folder
%
% Format:
% .txt file contains three parts: Header, Model and Data
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
% MODEL: ...
% 
% COEFFICIENTS
% parameters    1   2   3  ...
% ...          ... ... ... ...
% ...          ... ... ... ...
% ...          ... ... ... ...
%
% ERROR
% parameters   1   2   3  ...
% ...         ... ... ... ...
% ...         ... ... ... ...
%
% 
% M.Petit - 03/2019
% manuel.petit@inserm.fr



% check input
if isempty(hData)
    error('ExportData: No data input')
elseif ~isa(hData,'Dispersion')
    error('ExportData: Input should be Dispersion object')
end

% ask user a path if needed
if nargin < 2
    path = uigetdir(pwd, 'Export Dispersion data');   
    if isequal(path,0); return; end
end

% get the model
model = arrayfun(@(x) x.processingMethod, hData, 'Uniform', 0);

% check if empty
tf = cellfun(@isempty, model);

if all(tf == 1)
    error('No dispersion data fit found in files (processingMethod property is empty)')
elseif any(tf == 1)
    try % if no RelaxObj are linked
        str = sprintf('%s\n', getRelaxProp(hData(tf), 'filename'));
    catch
        str = sprintf('%s\n', hData(tf).displayName); %get displayName
    end
    warning('Some file(s) are empty (no fit data) and will be ignored:\n%s', str)
    model = model(~tf);
    hData = hData(~tf);
end

% check the number of unique model
model_class = cellfun(@(x) class(x), model, 'Uniform', 0); %do it one by one
[~, n, idx] = unique(model_class);

if numel(n) > 1
    fprintf('More than one model was detected, %d .txt files will be created!\n', numel(n));
end

for k = 1:numel(n)
    % select data corresponding to the model
    model_tpm = [model{idx == k}]; %concatenate objects
    
    % get the parameter list
    parameter = model_tpm(1).parameterName;
    
    % fill header information
    try
        dataset = getRelaxProp(hData(idx == k), 'dataset');
        sequence = getRelaxProp(hData(idx == k), 'sequence');
        filename = getRelaxProp(hData(idx == k), 'filename');
        label = getRelaxProp(hData(idx == k), 'label');
    catch
       warning(['It seems that header information is not available'...
       'Check if your Dispersion object has a RelaxObj linked (relaxObj property).'])
        dataset = repmat({'?'},1,sum(idx==k));
        sequence = repmat({'?'},1,sum(idx==k));
        filename = repmat({'?'},1,sum(idx==k));
        label = repmat({'?'},1,sum(idx==k));
    end
    displayName = {hData(idx == k).displayName};
    
    % check coefficients and errors data
    tf = ~cellfun(@isreal, {model_tpm.bestValue}); % check if complex

    if any(tf == 1)
        if ~strcmp(filename{1},'?')
            str = sprintf('%s\n', filename{tf}); %get displayName
        else
            str = sprintf('%s\n', displayName{tf}); %get displayName
        end
        warning('Some coefficients are complex, they are ignored:\n%s',str)
        model_tpm = model_tpm(~tf);
        filename = filename(~tf); sequence = sequence(~tf);
        dataset = dataset(~tf); label = label(~tf);
        displayName = displayName(~tf);
    end
    
    if isempty(filename)
        continue
    end
    
    % get coefficients and errors
    coeff = vertcat(model_tpm.bestValue)';
    err   = vertcat(model_tpm.errorBar)';
    
    % create output .txt file 
    % open file: 'filename.txt'
    if numel(n) > 1
        fid = fopen(strcat(path,'\','export_fit',num2str(k),'.txt'), 'w');
    else
        fid = fopen(strcat(path,'\','export_fit.txt'), 'w');
    end
    
    % set header
    fprintf(fid,'Header lines:,\t%d,\r\n', 12);
    fprintf(fid,'Date:,\t%s,\r\n\r\n', datetime('today'));

    fprintf(fid,'HEADER,\r\n');
    fprintf(fid,'Label:,\t%s\r\n', sprintf('%s,\t',label{:}));
    fprintf(fid,'Dataset:,\t%s\r\n', sprintf('%s,\t',dataset{:}));
    fprintf(fid,'Sequence:,\t%s\r\n', sprintf('%s,\t',sequence{:}));
    fprintf(fid,'Filename:,\t%s\r\n', sprintf('%s,\t',filename{:}));
    fprintf(fid,'Name:,\t%s\r\n\r\n', sprintf('%s,\t',displayName{:}));

    % set processing
    fprintf(fid,'MODEL:,\t%s,\r\n\r\n', model_tpm(1).modelName);

    % set data
    % + Y values
    fprintf(fid,'\r\nCOEFFICIENTS:,\r\n');
    fprintf(fid,'%8s,\t','Parameters');
    for i = 1:numel(model_tpm)-1
        fprintf(fid,'%8s,\t',num2str(i));
    end
    fprintf(fid,'%8s,\r\n',num2str(numel(model_tpm)));

    format = ['%8s,\t',repmat('%8f,\t',1,numel(model_tpm)-1),'%8f,\r\n'];
    for i = 1:numel(parameter) %line by line to avoid NaN problem
        fprintf(fid,format, parameter{i}, coeff(i,:));
    end

    % + DY values
    fprintf(fid,'\r\nERROR:,\r\n');
    fprintf(fid,'%8s,\t','Parameters');
    for i = 1:numel(model_tpm)-1
        fprintf(fid,'%8s,\t',num2str(i));
    end
    fprintf(fid,'%8s,\r\n',num2str(numel(model_tpm)));

    format = ['%8s,\t',repmat('%8f,\t',1,numel(model_tpm)-1),'%8f,\r\n'];
    for i = 1:numel(parameter) %line by line to avoid NaN problem
        fprintf(fid,format, parameter{i}, err(i,:));
    end

    % close file
    fclose(fid);
    
end %for loop over the unique model(s)

end

