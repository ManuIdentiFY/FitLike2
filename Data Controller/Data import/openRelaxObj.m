function relaxlist = openRelaxObj(file,path,dataset)

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
elseif nargin == 1 
    [path,file,ext] = fileparts(file);
    if isempty(path)
        path = cd;
    end
    dataset = 'Default dataset';
else
    [pathfromfile,~,ext] = fileparts(file);
    if (nargin < 3) && (isempty(pathfromfile))
        dataset = 'Default dataset';
    elseif (nargin < 3) % the user provides the path attached to the file name, second argument must be the dataset name
        dataset = path;
        path = pathfromfile;
    end
    % check dataset output
    if isempty(dataset)
        return
    elseif ischar(dataset)
        dataset = {dataset};
    end
end
% check inputs
if isequal(file,0)
    % user canceled
    return
elseif ischar(file)
    file = {file};
end

%% create the bloc object
bloc = [];
% switch depending on the type of file
switch ext
    case '.sdf'
        % loop over the files
        for i = 1:length(file)
            filename = fullfile(path,[file{i} ext]);
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
                'parameter',num2cell(parameter),...
                'filename',name,'sequence',sequence);  
            new_bloc = checkBloc(new_bloc);
            
            % create the metadata object associated with this acquisition
            relax = RelaxObj('label','Default data',...                     % defines the category of data (user defined)
                             'filename',fullfile(path,file{i}),...             % store the data file name
                             'sequence',sequence{1},...   % name of the sequence
                             'dataset',dataset,...                          % dataset associated 
                             'data',new_bloc,...
                             'parameter', parameter);  

           
            % append them to the current data
            relaxlist = [relaxlist relax]; %#ok<AGROW>
        end
    case '.sef'
        % loop over the files
        for i = 1:length(file)
            filename = fullfile(path,[file{i} ext]);
            % read the file
            [x,y,dy] = readsef(filename);
            % format the output
            new_bloc = Dispersion('x',x,'xLabel','Magnetic Field (MHz)',...
                'y',y,'dy',dy,'yLabel','Relaxation Rate R_1 (s^{-1})',...
                'filename',file{i},'sequence','Unknown');
            % create the metadata object associated with this acquisition
            relax = RelaxObj('label','Default data',...                     % defines the category of data (user defined)
                             'filename',fullfile(path,file{i}),...             % store the data file name
                             'sequence','Unknown',...   % name of the sequence
                             'dataset',dataset,...                          % dataset associated 
                             'data',new_bloc,...
                             'parameter', ParamV1);  
            % append them to the current data
            relaxlist = [relaxlist relax]; %#ok<AGROW>
        end
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
            

% link the relaxobj and bloc data

    function bloc = checkBloc(bloc)
         % check if bloc are uniques
        [~,~,X] = unique(strcat({bloc.dataset},{bloc.sequence},...
            {bloc.filename}));
        Y = hist(X,unique(X));
        idx = find(Y > 1);
        for k = 1:numel(idx)
            ibloc = bloc(X == idx(k));
            new_filename = cellfun(@(x) [ibloc(1).filename,' (',num2str(x),')'],...
                num2cell(1:numel(ibloc)), 'Uniform',0);
            [bloc(X == idx(k)).filename] = new_filename{:};                        
        end
    end %checkBloc

end