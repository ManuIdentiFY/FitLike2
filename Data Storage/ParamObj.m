classdef ParamObj < matlab.mixin.Heterogeneous
    
    properties
        paramList@struct;   % list of parameters
    end
    
    methods 
         
        function self = ParamObj(paramStruct)           
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0
                % default value
                return
            end
            
            % check if array of struct
            if ~iscell(paramStruct)
                self.paramList = paramStruct;
            else
                % initialise explicitely the array of object (required
                % for heterogeneous array)
                fh = str2func(class(self));
                % for loop required to create unique handle.
                for k = numel(paramStruct):-1:1
                    self(1,k) = fh();
                    self(k).paramList = paramStruct{k};
                end
            end   
        end
        
        % reshape the data in all fields according to the template provided
        function self = reshape(self,dim)
            fname = fields(self.paramList);
            for ind = 1:length(fname)
                val = getfield(self.paramList,fname{ind});
                if iscell(val) || isnumeric(val)
                    if (size(val,1)==dim(1) && size(val,2)==dim(2) && size(val,3)==dim(3))
                        val = reshape(val,dim);
                    end
                end
                self.paramList = setfield(self.paramList,fname{ind},val);
            end
        end
        
        % Syntax: val = getfield(self, 'field')
        %         val = getfield(self, 'field', 'ForceCellOutput', 'True')
        function value = getfield(self, field, varargin)
            % check if the field exist in all the parameter structures
            isfld = arrayfun(@(x) isfield(x.paramList,field), self);
            % check input size
            if length(self) > 1
                if all( isfld == 1) 
                    % get value
                    value = arrayfun(@(x) x.paramList.(field), self, 'UniformOutput',0);
                else
                    % initialise empty cell array
                    value = cell(1,length(self));
                    % fill what you can
                    value(isfld) = arrayfun(@(x) x.paramList.(field), self, 'UniformOutput',0);
                    % throw a warning
                    warning('getfield:MissingField',['One or more structure(s)'...
                                        ' miss the field required'])
                end
            else
                if isfld ~= 1
                    error('getfield:MissingField',['The required field does'...
                                         ' not exist'])
                else
                    if nargin > 2
                        if strcmp(varargin{1},'ForceCellOutput') &&...
                                strcmpi(varargin{2},'true')
                            value = {self.paramList.(field)};
                        elseif strcmpi(varargin{2},'false')
                            value = self.paramList.(field);
                        else
                            error('getfield:ForceCellOutput',['Wrong optional argument'...
                                          ' or value associated'])
                        end
                    else                           
                        value = self.paramList.(field);
                    end
                end
            end
        end %getfield

        
        function other = copy(self)
            fh = str2func(class(self));
            other = fh();
            other.paramList = self.paramList;
        end
        
        
        function self = setfield(self, field, value)
            if length(self) > 1 
                % check if the field exist in all the parameter structures
                isfld = arrayfun(@(x) isfield(x.paramList,field), self);
                % check the size of value
                if ~iscell(value) || length(value) ~= length(self)
                    error('setfield:WrongSizeInput',['The size of the value input'...
                        ' does not fit with the size of the array OR value input'...
                        'is not a cell'])
                end
                % because we are working with substructure, a for loop is
                % required
                if all(isfld ~= 1)
                    warning('setfield:MissingField',['One or more structure(s)'...
                                    ' miss the field required'])
                    self = self(isfld);
                    value = value(isfld);
                end
                % loop
                for i = 1:length(self)
                    self(i).paramList.(field) = value{i};
                end
            else
                % check if the field exist
                if ~isfield(self.paramList,field)
                    error('setfield:MissingField',['The field required does'...
                                          ' not exist'])
                else
                    self.paramList.(field) = value;
                end
            end
        end %setfield
        
        function self = changeFieldName(self,old,new)
            for i = 1:length(self)
                self(i).paramList  = setfield(self(i).paramList ,new,getfield(self(i),old));
                self(i).paramList = rmfield(self(i).paramList,old);
            end
        end
        
        % merging two parameter files. This is a complex operation and the
        % function below may be largely optimised.
        function new = merge(self)
            f2 = fieldnames(self(2).paramList);
            new = copy(self(1));
            
            % place the exeptions here
            
            % check the consistency of TAU values
            if sum(strcmp(f2,'TAU')) % if there is a TAU field, then check
                try
                    tau = arrayfun(@(s)s.paramList.TAU,self,'UniformOutput',0);
                    if ~isequal(tau{:})
                        new.paramList.TAU = tau;
%                         warning('TAU values differ between acquisitions, the results may be meaningless.')
                    else
                        new.paramList.TAU = tau{1};
                    end
                catch ME
                    warning('Inconsistent TAU values, the results may be meaningless.')
                    disp(ME.message)
                end
                f2(strcmp(f2,'TAU')) = [];
            end
            
            % start merging
            for indfname = 1:length(f2)
                fname = f2(indfname);
                fname = fname{1};
                val2 = getfield(self(2),fname);
                if isfield(new.paramList,fname)
                    val1 = getfield(new.paramList,fname);
                    try
                        if isnumeric(val1) && isnumeric(val2) %#ok<*GFLD>
                            new.paramList = setfield(new.paramList,fname,[val1,val2]); %#ok<*SFLD>
                        elseif iscell(val1) && iscell(val2)
                            new.paramList = setfield(new.paramList,fname,[val1,val2]);
                        else
                            new.paramList = setfield(new.paramList,fname,{val1,val2});
                        end
                    catch
                        new.paramList = setfield(new.paramList,fname,val2); % in case of an incompatibility, erase the old value altogether
                    end
                else
                    new.paramList = setfield(new.paramList,fname,val2);
                end
            end
            % treat additional items to merge recursively
            if length(self)>2
                new = merge([new, self(3:end)]);
            end            
        end
        
        % replace the field values with the new ones
        function new = replace(self)
            for numobj = 2:length(self)
                f2 = fieldnames(self(numobj).paramList);
                for ind = 1:length(f2)
                    if isfield(self(1).paramList,f2{ind})
                        self(1).paramList.(f2{ind}) = [];
                    end
                end
            end
            new = merge(self);
        end
                
        function x = struct2cell(self)
            x = struct2cell(self.paramList);
        end

        % GETDISPAXIS(SELF) get the magnetic fields
        % The input can not be an array of object, instead call GETDISPAXIS
        % with the following syntax:
        % brlx = arrayfun(@(x) getDispAxis(x), self, 'UniformOutput', 0);
        function BRLX = getDispAxis(self)
            % check input
            if length(self) > 1
                error('GetDispAxis:InputSize',['It seems that the input is'...
                    ' an array of object. Use the following syntax instead: '...
                    'arrayfun(@(x) getDispAxis(x), self, ''UniformOutput'', 0);'])
            else
                BRLX = self.paramList.BRLX(:);
            end
        end
        
    end
end