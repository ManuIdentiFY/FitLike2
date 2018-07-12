classdef ParamV1 < ParamObj
    
    properties
          % See ParamObj properties 
    end
    
    methods
        % parameter can be a structure or a cell array of structure. If a
        % cell array of structure is detected then PARAMV1 creates an array
        % of ParamV1 object.
        function self = ParamV1(parameter)
            % check input
            if nargin == 0
                return
            end
            
            % check if array of struct
            if ~iscell(parameter)
                % struct
                self.paramList = parameter;                           
            else
                % array of struct            
                [self(1:length(parameter)).paramList] = deal(parameter{:});                      
            end   
        end %ParamV1
            
        function x = getZoneAxis(self)
        
        end
        
        function x = getDispAxis(self)
        
        end
        
    end
    
end