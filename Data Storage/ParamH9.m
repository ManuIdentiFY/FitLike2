classdef ParamH9 < ParamObj
    
    % reads the parameters obtained from an EVO console from MR solutions,
    % processed by the Aberdeen FFC-MRI scanner H9.
    % Lionel Broche, 19/10/18
    properties
              
    end
    
    methods
        function this = ParamH9(varargin)
            this@ParamObj(varargin{:});
        end
            
        function x = getZoneAxis(this)
            x = this.paramList.Tevo';
        end
        
    end
    
end