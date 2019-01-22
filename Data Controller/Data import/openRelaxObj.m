function relaxlist = openRelaxObj(filename,dataset)

% creates a relaxobj instance with the data imported from the file
% provided.
% LB 10/01/19 - first version

%% open data file
relaxlist = [];

if nargin == 0
    % open interface to select files
    [file, path, indx] = uigetfile({'*.sdf','Stelar Raw Files (*.sdf)';...
                             '*.sef','Stelar Processed Files (*.sef)';...
                             '*.mat','FitLike Dataset (*.mat)'},...
                             'Select One or More Files', ...
                             'MultiSelect', 'on');   
    switch indx
        case 1
            ext = 'sdf';
        case 2
            ext = 'sef';
        case 3
            ext = 'mat';
    end
else 
    if iscell(filename) % case when the use provides a list of file names
        for ind = 1:length(filename)
            [path{ind},file{ind},ext{ind}] = fileparts(filename{ind});
        end
    elseif ischar(filename)
        [path{1},file{1},ext{1}] = fileparts(filename);
    elseif isobject(filename)
        if nargin < 2
            dataset = 'Default dataset';
        end
        relaxlist = RelaxObj('label','Default data',...                     % defines the category of data (user defined)
                         'filename','Manual entry',...             % store the data file name
                         'sequence','Unknown',...   % name of the sequence
                         'dataset',dataset,...                          % dataset associated 
                         'data',filename,...
                         'parameter', ParamV1);  
        return
    else
        error('Wrong type of input. First input must a file name or an array of file names')
    end
end

if nargin < 2
    for ind = 1:length(file)
        dataset{ind} = 'Default dataset';
    end
elseif ischar(dataset)
    dataset = {dataset};
end

% check inputs
if isequal(file,0)
    % user canceled
    return
elseif ischar(file)
    file = {file};
end

%% create the bloc object

% loop over the files
for i = 1:length(file)
    if isempty(path{i})
        path{i} = cd;
    end
    % switch depending on the type of file
    switch ext{i}
        case '.sdf'
            filename = fullfile(path{i},[file{i} ext{i}]);
            % check version and select the correct reader
            try
                ver = checkversion(filename);
                if isequal(ver,1)
                    [data, parameter] = readsdfv1(filename);
                else
                    [data, parameter] = readsdfv2(filename);
                end
            catch
                warning(['Error while importing file ' filename '. File not loaded.\n']) % simple error handling for file import
                continue
            end   
            % get the data
            y = cellfun(@(x,y) complex(x,y), data.real, data.imag,...
                'UniformOutput',0);
            name = getfield(parameter,'FILE','ForceCellOutput','True');
            sequence = getfield(parameter,'EXP','ForceCellOutput','True');
            % format the output
            new_bloc = Bloc('x',data.time,'y',y,...
                'xLabel',repmat({'Time'},1,length(name)),...
                'yLabel',repmat({'Signal'},1,length(name)),...
                'sequence',sequence,...
                'parameter', parameter);   % name of the sequence
            new_bloc = checkBloc(new_bloc);

            % create the metadata object associated with this acquisition
            relax = arrayfun(@(b) RelaxObj('label','Default data',...                     % defines the category of data (user defined)
                                           'filename',filename,...             % store the data file name
                                           'dataset',dataset{i},...                          % dataset associated 
                                           'data',b,...
                                           'parameter', parameter),new_bloc);  
            [new_bloc.relaxObj] = deal(relax);                  % link the bloc object to the relax object


            % append them to the current data
            relaxlist = [relaxlist relax]; %#ok<AGROW>
        case '.sef'
            % loop over the files
            filename = fullfile(path{i},[file{i} ext{i}]);
            % read the file
            [x,y,dy] = readsef(filename);
            % format the output
            new_bloc = Dispersion('x',x,'xLabel','Magnetic Field (MHz)',...
                'y',y,'dy',dy,'yLabel','Relaxation Rate R_1 (s^{-1})',...
                'filename',file{i},'sequence','Unknown');
            % create the metadata object associated with this acquisition
            relax = arrayfun(@(b) RelaxObj('label','Default data',...                     % defines the category of data (user defined)
                             'filename',filename,...             % store the data file name
                             'sequence','Unknown',...   % name of the sequence
                             'dataset',dataset{i},...                          % dataset associated 
                             'data',b,...
                             'parameter', ParamV1),new_bloc);  
            [new_bloc.relaxObj] = deal(relax);
            % append them to the current data
            relaxlist = [relaxlist relax]; %#ok<AGROW>
        case '.mat'
            for i = 1:length(file)
                filename = fullfile(path,[file{i} ext]);
                % read the .mat file
                obj = load(filename);
                if ~isequal(class(obj),'RelaxObj')
                    return
                end
                % append them to the current data
                relaxlist = [relaxlist obj]; %#ok<AGROW>
            end
    end
end            
            
    

% link the relaxobj and bloc data

    function bloc = checkBloc(bloc)
        % TODO
    end %checkBloc

end