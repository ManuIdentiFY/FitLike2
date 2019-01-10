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
    
    properties (Hidden)
        fileID@char;                   % generate unique ID 
        subRelaxObj@RelaxObj
    end
    
    % data properties
    properties (Access = public)
        data@DataUnit
        parameter@ParamObj = ParamObj();  
    end  
    
    methods
        % Constructor: RelaxObj()
        function obj = RelaxObj(varargin)           
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            % fill the structure
            for ind = 1:2:nargin
                try 
                    obj.(varargin{ind}) = varargin{ind+1};
                catch ME
                    error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                end                           
            end 
            % add fileID
            obj.fileID = char(java.util.UUID.randomUUID);
        end %RelaxObj         
        
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
            
            
            
%             % check if files are already merged
%             switch isMerged(obj_list)
%                 case 0
%                     % merge data and parameter
%                     merged_data = merge([obj_list.data]);
%                     merged_parameter = merge([obj_list.parameter]);
%                     % create merged object from first object list
%                     obj_list(1).data = merged_data;
%                     obj_list(1).parameter = merged_parameter;
%                     obj_list(1).subRelaxObj = obj_list;
%                     obj = obj_list(1);
%                 case 1
%                     % unmerge data and parameter
%                     unmerged_data = merge([obj_list.data]);
%                     unmerged_parameter = merge([obj_list.parameter]);
%                     % create unmerged object
% %                     obj_list(1).data = merged_data;
% %                     obj_list(1).parameter = merged_parameter;
% %                     obj = obj_list.subRelaxObj;
%                 otherwise
%                     % mix of merged and unmerged files
%                     return
%             end
        end %mergeFile
    end
    
    % Data access functions
    methods (Access = public)
        % This function to get DataUnit object from the RelaxObj.
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
            
            % start by finding the deepest object: Bloc object
            obj = this.data;
            
            while ~isempty(obj(1).parent)
                obj = obj(1).parent;
            end
            
            % check if we need to find a particular type of object
            if nargin > 1
                % find all the object corresponding to this class
                while ~strcmp(class(obj), varargin{1}) || isempty(obj(1).children)
                    obj = [obj.children];
                end
                
                % check result
                if ~strcmp(class(obj), varargin{1})
                    error('No object was found with this class!')
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
                while ~isempty(obj(1).children)
                    obj = [obj.children];
                    data = [data, obj]; %#ok<AGROW>
                end
            end
        end %getData
    end
end

