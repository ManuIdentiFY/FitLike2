classdef RelaxObj < handle
    % This class manage Stelar data from the SPINMASTER relaxometer.
    %
    % See also DATAUNIT, BLOC, ZONE, DISPERSION
    
    % file properties
    properties (Access = public)
        label@char = '';               % label of the file ('control','tumour',...)
        filename@char = '';            % name of the file ('file1.sdf')
        sequence@char = '';            % name of the sequence ('IRCPMG')
        dataset@char = 'myDataset';    % name of the dataset('ISMRM2018')
    end
    
    % data properties
    properties (Access = public)
        data@DataUnit
        parameter@ParamObj = ParamObj();  
    end  
    
    % ID and subfiles
    properties (Hidden)
        fileID@char;
        subRelaxObj@RelaxObj
    end
    
    
    events
        FileHasChanged
        FileIsDeleted
    end
    
    % Constructor/Destructor
    methods
        % Constructor: obj = RelaxObj('field1',val1,'field2','val2',...)
        % RelaxObj can build structure or array of structure depending on
        % the input:
        %
        % Example:
        % filename = {'file1','file2','file3'}; % cell array
        % obj = RelaxObj('filename',filename); % array of structure
        % obj = RelaxObj('filename',[filename{:}]) % structure
        %
        function this = RelaxObj(varargin)           
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            
            % check if array of struct
            if ~iscell(varargin{2})                
                % fill the structure
                for ind = 1:2:nargin
                    this.(varargin{ind}) = varargin{ind+1};
                end 
                % add fileID
                this.fileID = char(java.util.UUID.randomUUID);
            else
                % array of struct
                % check for cell sizes
                n = length(varargin{2});
                if ~all(cellfun(@length,varargin(2:2:end)) == n)
                    error('Size input is not consistent for array of struct.')
                else
                    for k = n:-1:1
                        % fill arguments
                        for ind = 1:2:nargin
                            [this(k).(varargin{ind})] = varargin{ind+1}{k};
                        end
                        % add fileID
                        this(k).fileID = char(java.util.UUID.randomUUID);
                    end
                end
            end
        end %RelaxObj
        
        % Destructor
        function delete(this)
           % call to the data 
           delete(this.data);
           % notify destruction
           notify(this,'FileIsDeleted');
        end %delete
    end
    
    % Data formating functions
    methods (Access = public)
        % Search for duplicates in array of RelaxObj.
        % This function check the unicity of the triplet (dataset, sequence, filename)
        % If duplicates are found, the concerned RelaxObj's
        % filename are modified as:
        % RelaxObj(i).filename = [RelaxObj(i).filename (n)]
        % with n the index of the duplicated files.
        function this = check(this)
            % check if bloc are uniques
            [~,~,X] = unique(strcat({this.dataset},{this.sequence},...
                {this.filename}));
            Y = hist(X,unique(X));
            idx = find(Y > 1);
            for k = 1:numel(idx)
                obj = this(X == idx(k));
                new_filename = cellfun(@(x) [obj(1).filename,' (',num2str(x),')'],...
                    num2cell(1:numel(obj)), 'Uniform',0);
                [this(X == idx(k)).filename] = new_filename{:};
            end
        end %check
        
        % Data formating: mergeFile()
        % merge several objects, considering only the DataUnit at the level
        % provided (Bloc, Zone or Dispersion)
        function obj = merge(obj_list,level)
            % check input
            if numel(obj_list) < 2
                return
            end
            if nargin == 1
                level = 'Bloc'; % default level for merging the two objects
            end
            % check that the data from the list of object is compatible at
            % the level provided (same number of objects, and same type of 
            % process performed)
            list = arrayfun(@(x) getData(x, level),obj_list,'UniformOutput',0);
            
            % check for consitency in the type of data to be merged (TO BE IMPROVED, NEED TO CHECK PROCESSING TYPE)
            nunit = cellfun(@(x) length(x),list);
            if ~prod(nunit == nunit(1))
                error('The objects selected contain a different number of data units. They may have been processed differently.')
            end
            
            % find the objects to be merged
            for ind = 1:length(list(1))
                datamerge(ind) = merge(cellfun(@(x) x(ind),list)); %#ok<AGROW,NASGU>
            end
            
            % Generate the empty object that will contain the merged data
            obj = RelaxObj('label',obj_list(1).label,...
                           'filename',obj_list(1).filename, ...
                           'sequence',obj_list(1).sequence, ...
                           'dataset', obj_list(1).dataset,...
                           'data', datamerge,... 
                           'parameter',merge(arrayfun(@(x) x.parameter,obj_list)));
            
           
        end %mergeFile
    end
    
    % Data access functions
    methods (Access = public)
        % This function extract DataUnit object(s) from the RelaxObj.
        %
        % Optionnal input: 
        % - 'class': char between {'Dispersion','Zone','Bloc'}
        % - 'name': char (corresponding to the displayName property in DataUnit
        %
        % Example:
        % data = getData(this); % Get all the data in RelaxObj
        %
        % data = getData(this, 'Dispersion'); % get all the Dispersion 
        % object in RelaxObj
        %
        % data = getData(this, 'Zone', 'Zone (Abs)')% get the zone object
        % in RelaxObj named 'Zone (Abs)'
        function data = getData(this, varargin)
            % check if data are available
            if isempty(this.data)
                data = []; return;
            end
            
            obj = this.data;
            % check if we need to find a particular type of object
            if nargin > 1                
                % find all the object corresponding to this class
                while ~strcmpi(class(obj), varargin{1})
                    % check if parent are available
                    if  isempty(obj(1).parent)
                       error('No object was found with this class!') 
                    end
                    % get parent and remove duplicates
                    obj = unique([obj.parent]);
                end
                
                % check if we need to find a particular named obj
                if nargin > 2
                    tf = strcmp({obj.displayName}, varargin{2});
                    
                    if all(tf == 0)
                        error('No object was found with this name!')
                    else
                        data = obj(tf);
                    end
                else
                    data = obj;
                end
            else
                data = obj;
                % get all the object
                while ~isempty(obj(1).parent)
                    obj = unique([obj.parent]);
                    data = [data, obj]; %#ok<AGROW>
                end
            end
        end %getData
        
        % This function extract the DataUnit meta-data from the RelaxObj.
        % Any DataUnit is defined by its displayName property, returned by
        % this function.
        % Output is a struct where fieldname are the class and value are
        % the displayName(s) found.
        %
        % Optionnal input:
        % - 'class': char between {'Dispersion','Zone','Bloc'};
        %
        % Example!
        % name = getDataInfo(this); % Get all the displayName in RelaxObj
        % 
        % name = getDataInfo(this, 'Dispersion'); % get all the displayName
        % of dispersion object in RelaxObj.
        function displayName = getDataInfo(this, varargin)
            % get the data object wanted
            obj = getData(this,varargin{:});
            
            % get their class
            c = arrayfun(@class, obj, 'Uniform', 0); % because heterogeneous array
            cc = unique(c,'stable');
            
            % loop over the class
            for k = 1:numel(cc)
                tf = strcmp(c, cc{k});
                displayName.(cc{k}) = {obj(tf).displayName};
            end            
        end %getDataInfo
        
        % Wrapper to the ParamObj setfield/getfield methods. See ParamObj
        % for more details.
        % Syntax: val = getfield(self, 'field')
        %         val = getfield(self, 'field', 'ForceCellOutput', 'True')
        function val = getfield(this, fld, varargin)
            val = getfield(this.parameter, fld, varargin);
        end %getfield
        
        function this = setfield(this, field, val)
            this.parameter = setfield(this.parameter, field, val); %#ok<SFLD>
        end %setfield
    end
end

