classdef DataUnit < handle & matlab.mixin.Heterogeneous
    %
    % Abstract class that define container for all the Stelar SPINMASTER
    % relaxometer data (bloc, zone, dispersion).
    % DataUnit and its subclasses handle structure as well as array of
    % structure.
    % Notice that attributes for properties are defined directly avoiding
    % the need for further checking.
    %
    % SEE ALSO BLOC, ZONE, DISPERSION
    
    % file data
    properties (Access = public)
        x@double = [];          % main measure X (time, Bevo,...)
        xLabel@char = '';       % name of the  variable X ('time','Bevo',...)
        y@double = [];          % main measure Y ('R1','fid',...)
        dy@double = [];         % error bars on Y
        yLabel@char = '';       % name of the variable Y ('R1','fid',...)
        mask@logical = true(0);           % mask the X and Y arrays
        legendTag@char;         % char array to place in the legend associated with the data
        subUnitList@DataUnit;          % stores DataUnits of the same type to merge data sets while keeping unmerge capabilities
    end   
    
    % file parameters
    properties (Access = public)
        parameter@ParamObj = ParamObj();       % list of parameters associated with the data
    end
    
    % file processing
    properties (Access = public)
        processingMethod@ProcessDataUnit = ProcessDataUnit(); % stores the processing objects that are associated with the data unit
    end
    
    % file properties
    properties (Access = public)
        filename@char = '';     % name of the file ('file1.sdf')
        sequence@char = '';     % name of the sequence ('IRCPMG')
        dataset@char = 'myDataset';      % name of the dataset('ISMRM2018')
        label@char = '0';        % label of the file ('control','tumour',...)
    end
    
    % other properties
    properties (Access = public, Hidden = true)
        fileID@char = '';       % ID of the file: [dataset sequence filename] 
        parent = [];            % parent of the object
        children = [];          % children of the object
    end
    
    methods 
        % Constructor: obj = DataUnit('field1',val1,'field2','val2',...)
        % DataUnit can build structure or array of structure depending on
        % the input:
        % x = num2cell(ones(10,1)); % array of cell
        % obj = DataUnit('x',x); % array of structure
        % obj = DataUnit('x',[x{:}]) % structure
        function obj = DataUnit(varargin)
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            
            % check if array of struct
            if ~iscell(varargin{2})
                % struct
                for ind = 1:2:nargin
                    try 
                        obj.(varargin{ind}) = varargin{ind+1};
                    catch ME
                        error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                    end                           
                end   
            else
                % array of struct
                % check for cell sizes
                n = length(varargin{2});
                if ~all(cellfun(@length,varargin(2:2:end)) == n)
                    error('Size input is not consistent for array of struct.')
                else
                    % initialise explicitely the array of object (required
                    % for heterogeneous array)
                    % for loop required to create unique handle.
                    for k = n:-1:1
                        % initialisation required to create unique handle!
                        obj(1,k) = DataUnit();
                        % fill arguments
                        for ind = 1:2:nargin 
                            [obj(k).(varargin{ind})] = varargin{ind+1}{k};                          
                        end
                    end
                end
            end   
            
            % generate mask if missing
            resetmask(obj);
            % generate fileID
            generateID(obj);
        end %DataUnit       
        
        
        % collect the display names from all the parents in order to get
        % the entire history of the processing chain, for precise legends
        function legendStr = collectLegend(self)
            legendStr = self.legendTag;
            if ~isempty(self.parent.legendTag)
                legendStr = [legendStr ', ' collectLegend(self.parent)];
            end
        end
        
        % make a copy of an object
        function other = copy(self)
            fh = str2func(class(self));
            other = fh();
            fld = fields(self);
            for ind = 1:length(fld)
                other.(fld{ind}) = self.(fld{ind});
            end
        end
        
    end % methods
    
    methods (Access = public, Sealed = true)
        
        % Generate fileID field
        function obj = generateID(obj)
            if length(obj) > 1
                ID = strcat({obj.dataset}, {obj.sequence},...
                    {obj.filename},repmat({'@'},1,numel({obj.dataset})),...
                    {obj.displayName});
                [obj.fileID] = ID{:};            
            else
                obj.fileID = [obj.dataset, obj.sequence,...
                    obj.filename,'@', obj.displayName];
            end
        end %generateID
        
        % Fill or adapt the mask to the "y" field 
        function obj = resetmask(obj)
            % check if input is array of struct or just struct
            if length(obj) > 1 
                % array of struct
                idx = ~arrayfun(@(x) isequal(size(x.mask),size(x.y)), obj);
                % reset mask
                new_mask = arrayfun(@(x) true(size(x.y)),obj(idx),'UniformOutput',0);
                % set new mask
                [obj(idx).mask] = new_mask{:};
            else
                % struct
                if ~isequal(size(obj.mask),size(obj.y))
                    % reset mask
                    obj.mask = true(size(obj.y));
                end
            end
        end %resetmask   
        
    end %methods
    
    % The methods described below are used to enable the merge capabilities
    % of the DataUnit object. They work by re-directing any quiry for the
    % x, y, dy and mask fields towards the list of sub-objects. Any
    % modification in here must take care to avoid recursive calls and to
    % limit the processing time, as these fields are used extensively
    % during processing.
    % LB 20/08/2018
    methods
        % check that new objects added to the list are of the same type as
        % the main object
        function self = set.subUnitList(self,objArray) %#ok<*MCSV,*MCHC,*MCHV2>
            test = arrayfun(@(o)isa(o,class(self)),objArray);
            if ~prod(test) % all the objects must have the correct type
                error('Merged objects must be of the same type as the object container.')
            end
            self.subUnitList = objArray;
        end
        
        % function that gathers the data from the sub-units and place them
        % in the correct field
        function value = gatherSubData(self,fieldName)
            value = [self.subUnitList.(fieldName)];
%             self.(fieldName) = value;
        end
        
        % function that spreads the data from the contained object to the
        % sub-units
        function self = distributeSubData(self,fieldName,value)
            % list the number of element needed in each sub-object
            lengthList = arrayfun(@(o)length(o.(fieldName)),self.subUnitList);
            endList = cumsum(lengthList);
            startList = [1 endList(1:end-1)+1];
            s = arrayfun(@(o,s,e)setfield(o,fieldName,value(s:e)),self.subUnitList,startList,endList,'UniformOutput',0); %#ok<SFLD>
            self.subUnitList = [s{:}];
        end
        
        % functions used to make sure that merged objects behave
        % consistently with their own object type. (see Matlab help on
        % 'Modify Property Values with Access Methods')
        function self = set.x(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'x',value);
            end
            self.x = value;
        end
        
        function x = get.x(self)
            if ~isempty(self.subUnitList)
                x = gatherSubData(self,'x');
            else
                x = self.x;
            end
        end
        
        function self = set.y(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'y',value);
            end
            self.y = value;
        end
        
        function y = get.y(self)
            if ~isempty(self.subUnitList)
                y = gatherSubData(self,'y');
            else
                y = self.y;
            end
        end
        
        function self = set.dy(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'dy',value);
            end
            self.dy = value;
        end
        
        function dy = get.dy(self)
            if ~isempty(self.subUnitList)
                dy = gatherSubData(self,'dy');
            else
                dy = self.dy;
            end
        end
        
        function self = set.mask(self,value)
            if ~isempty(self.subUnitList) %#ok<*MCSUP>
                % distribute the values to the sub-units
                self = distributeSubData(self,'mask',value);
            end
            self.mask = value;
        end
        
        function mask = get.mask(self)            
            if ~isempty(self.subUnitList)
                mask = gatherSubData(self,'mask');
            else
                mask = self.mask;
            end
        end
        
    end
     
end

