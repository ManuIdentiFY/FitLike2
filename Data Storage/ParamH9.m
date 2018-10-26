classdef ParamH9 < ParamObj
    
    % reads the parameters obtained from an EVO console from MR solutions,
    % processed by the Aberdeen FFC-MRI scanner H9.
    % Lionel Broche, 19/10/18
    properties
        
        
    end
    
    methods
        function self = ParamH9(varargin)
            self@ParamObj(varargin{:});
        end
            
        function x = getZoneAxis(self)
            x = self.paramList.Tevo';
        end
        
    end
    
end