function relaxObj = format_import_data(filelist, sequence, data, parameter)
%
% This function converts data in relaxObj object allowing the access to
% FitLike functions further. This function can be used after IMPORTDATA().
%
% Input: (output of importdata())
% - filelist: 1xN cell array of string containing the N filename(s).
% - sequence: 1xN cell array of string containing the sequences of the N
%             files. Each cell is an array of string of sequence.
% - data: 1xN cell array of structure containing the data of the N files.
%         Each structure has three fields (time, real, imag). Each field is
%         a cell array of double matrix. For the file i, this cell array
%         has the same size as the cell array of the sequence{i}.
% - parameter: 1xN cell array of ParamObj. See ParamObj class for details.
%
% Output: 
% - relaxObj: 1xM RelaxObj where M is the number of unique {filelist,
%             sequence} found (each file can contain multiple sequences).
%             Thus, M >= N in any case.
%
% M.Petit - 03/2019
% manuel.petit@inserm.fr

% calculate the total relaxObj length
M = sum(cellfun(@numel, sequence));
relaxObj(1,M) = RelaxObj();
tpm = 1;
for k = 1:numel(filelist)
    % make the DataUnit object
    dataObj = make_DataUnit(data{k}, sequence{k});
    % format and get length
    dataObj = num2cell(dataObj);
    n = numel(dataObj);
    filename = repmat(filelist(k),1,n);
    % make the corresponding RelaxObj
    relaxObj(tpm:tpm+n-1) = RelaxObj('filename',filename,'sequence',sequence{k},...
            'data',dataObj); 
    % add parameter if possible
    if ~isempty(parameter{k})
        param = num2cell(parameter{k});
        [relaxObj(tpm:tpm+n-1).parameter] = param{:};      
    end
    % update tpm
    tpm = tpm + n;
end % loop over the files

%% Nested function 
    % This function can allow further developement to create custom
    % DataUnit for other type of data. 
    % For now:
    % if .sdf file: complex signal from real and imaginary part for y-values
    %               and time for x-values. Make Bloc() object.
    % if .sef file (sequence == 'File SEF'): y is R1, dy is dR 1 and x is
    % B0. Make Dispersion object.
    %
    % data input should be a structure containing the wanted field (time,
    % real, imag,...).
    function dataObj = make_DataUnit(data, sequence)
        % check type of data
        if any(strcmp(sequence, 'SEF File') == 1)
            % make Dispersion object
            dataObj = Dispersion('x',data.x,'y',data.y,'dy',data.dy,...
                'xLabel','Magnetic Field (MHz)',...
                'yLabel','Relaxation Rate R_1 (s^{-1})');
        else
            % get data
            x = data.time;
            y = cellfun(@(x,y) complex(x,y), data.real, data.imag,'Uniform',0);
            % make Bloc object(s)
            dataObj = Bloc('x',x,'y',y);
        end
    end % make_DataUnit
end

