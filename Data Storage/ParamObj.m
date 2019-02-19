classdef ParamObj < matlab.mixin.Heterogeneous
    
    properties
        paramList@struct;   % list of parameters
    end
    
    methods          
        function this = ParamObj(paramStruct)           
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0
                % default value
                return
            end
            
            % check if array of struct
            if ~iscell(paramStruct)
                this.paramList = paramStruct;
            else
                % initialise explicitely the array of object (required
                % for heterogeneous array)
                fh = str2func(class(this));
                % for loop required to create unique handle.
                for k = numel(paramStruct):-1:1
                    this(1,k) = fh();
                    this(k).paramList = paramStruct{k};
                end
            end   
        end %ParamObj
        
        % reshape the data in all fields according to the template provided
        function this = reshape(this,dim)
            fname = fields(this.paramList);
            for ind = 1:length(fname)
                val = getfield(this.paramList,fname{ind});
                if iscell(val) || isnumeric(val)
                    if (size(val,1)==dim(1) && size(val,2)==dim(2) && size(val,3)==dim(3))
                        val = reshape(val,dim);
                    end
                end
                this.paramList = setfield(this.paramList,fname{ind},val);
            end
        end %reshape
        
        % Syntax: val = getfield(self, 'field')
        %         val = getfield(self, 'field', 'ForceCellOutput', 'True')
        function val = getfield(this, fld, varargin)
            % check if the field exist in all the parameter structures
            isfld = arrayfun(@(x) isfield(x.paramList,fld), this);
            % check input size
            if length(this) > 1
                if all( isfld == 1) 
                    % get value
                    val = arrayfun(@(x) x.paramList.(fld), this, 'UniformOutput',0);
                else
                    % initialise empty cell array
                    val = cell(1,length(this));
                    % fill what you can
                    val(isfld) = arrayfun(@(x) x.paramList.(fld), this, 'UniformOutput',0);
                    % throw a warning
                    warning('getfield:MissingField',['One or more structure(s)'...
                                        ' miss the field required'])
                end
            else
                if isfld ~= 1
                    error('getfield:MissingField',['The required field does'...
                                         ' not exist'])
                else
                    if numel(varargin) > 1
                        if strcmp(varargin{1},'ForceCellOutput') &&...
                                strcmpi(varargin{2},'true')
                            val = {this.paramList.(fld)};
                        elseif strcmpi(varargin{2},'false')
                            val = this.paramList.(fld);
                        else
                            error('getfield:ForceCellOutput',['Wrong optional argument'...
                                          ' or value associated'])
                        end
                    else                           
                        val = this.paramList.(fld);
                    end
                end
            end
        end %getfield

        
        function other = copy(this)
            fh = str2func(class(this));
            other = fh();
            other.paramList = this.paramList;
        end %copy
        
        
        function this = setfield(this, fld, val)
            if length(this) > 1 
                % check if the field exist in all the parameter structures
                isfld = arrayfun(@(x) isfield(x.paramList,fld), this);
                % check the size of value
                if ~iscell(val) || length(val) ~= length(this)
                    error('setfield:WrongSizeInput',['The size of the value input'...
                        ' does not fit with the size of the array OR value input'...
                        'is not a cell'])
                end
                % because we are working with substructure, a for loop is
                % required
                if all(isfld ~= 1)
                    warning('setfield:MissingField',['One or more structure(s)'...
                                    ' miss the field required'])
                    this = this(isfld);
                    val = val(isfld);
                end
                % loop
                for i = 1:length(this)
                    this(i).paramList.(fld) = val{i};
                end
            else
                % check if the field exist
                if ~isfield(this.paramList,fld)
                    error('setfield:MissingField',['The field required does'...
                                          ' not exist'])
                else
                    this.paramList.(fld) = val;
                end
            end
        end %setfield
        
        function this = changeFieldName(this,old,new)
            for i = 1:length(this)
                this(i).paramList  = setfield(this(i).paramList ,new,getfield(this(i),old));
                this(i).paramList = rmfield(this(i).paramList,old);
            end
        end %changeFieldName
        
        % merging two parameter files. This is a complex operation and the
        % function below may be largely optimised.
        function new = merge(this)
            f2 = fieldnames(this(2).paramList);
            new = copy(this(1));
            
            % place the exeptions here
            
            % check the consistency of TAU values
            if sum(strcmp(f2,'TAU')) % if there is a TAU field, then check
                try
                    tau = arrayfun(@(s)s.paramList.TAU,this,'UniformOutput',0);
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
                val2 = getfield(this(2),fname);
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
            if length(this)>2
                new = merge([new, this(3:end)]);
            end            
        end %merge
        
        % replace the field values with the new ones
        function new = replace(this)
            for numobj = 2:length(this)
                f2 = fieldnames(this(numobj).paramList);
                for ind = 1:length(f2)
                    if isfield(this(1).paramList,f2{ind})
                        this(1).paramList.(f2{ind}) = [];
                    end
                end
            end
            new = merge(this);
        end %replace
                
        function x = struct2cell(this)
            x = struct2cell(this.paramList);
        end %struct2cell

        % GETDISPAXIS(SELF) get the magnetic fields
        % The input can not be an array of object, instead call GETDISPAXIS
        % with the following syntax:
        % brlx = arrayfun(@(x) getDispAxis(x), self, 'UniformOutput', 0);
        function BRLX = getDispAxis(this)
            % check input
            if length(this) > 1
                error('GetDispAxis:InputSize',['It seems that the input is'...
                    ' an array of object. Use the following syntax instead: '...
                    'arrayfun(@(x) getDispAxis(x), self, ''UniformOutput'', 0);'])
            else
                BRLX = this.paramList.BRLX(:);
            end
        end %getDispAxis
        
    end
end