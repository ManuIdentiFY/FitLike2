classdef ParamFit < ParamObj
    
    % class used to handle the fit parameters so that they are
    % automatically updated when multiple contributions are present in the
    % model
    
    properties
        
    end
    
    methods
        function self = ParamFit(varargin)
            self = self@ParamObj;
        end
        
    end
    
end