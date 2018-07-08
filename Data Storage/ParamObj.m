classdef ParamObj
    
    properties
        paramList@struct;   % list of parameters
    end
    
    methods 
        
        function self = ParamObj(paramStruct)
            % varargin should be a parameter structure, which is copied
            % into the paramlist field.
            if nargin > 0
                % if the input is an array of struct, then make an
                % array of objects
                for i = 1:length(paramStruct)
                    self(i).paramList = paramStruct;
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
        
        
        function x = getfield(self,varargin)
            x = getfield(self.paramList,varargin{:});
        end
        
        function self = setfield(self,varargin)
            self.paramList = setfield(self.paramList,varargin{:});
        end
        
        function self = changeFieldName(self,old,new)
            self.paramList  = setfield(self.paramList ,new,getfield(self,old));
            self.paramList = rmfield(self.paramList,old);
        end
        
        function self = merge(self,other)
            f2 = fieldnames(other.paramList);
            for indfname = 1:length(f2)
                fname = f2(indfname);
                fname = fname{1};
                val2 = getfield(other,fname);
                if isfield(self.paramList,fname)
                    val1 = getfield(self.paramList,fname);
                    if isnumeric(val1) && isnumeric(val2) %#ok<*GFLD>
                        self.paramList = setfield(self.paramList,fname,[val1,val2]); %#ok<*SFLD>
                    elseif iscell(val1) && iscell(val2)
                        self.paramList = setfield(self.paramList,fname,[val1,val2{:}]);
                    else
                        self.paramList = setfield(self.paramList,fname,{val1,val2});
                    end
                else
                    self.paramList = setfield(self.paramList,fname,val2);
                end
            end            
        end
                
        function x = struct2cell(self)
            x = struct2cell(self.paramList);
        end
%         function x = getZoneAxis(self)
%         
%         end
%         
%         function x = getDispAxis(self)
%         
%         end
        
    end
end