classdef FitAlgorithm
    %
    % Superclass that regroups algorithm for curve fitting  
    %
    properties (Abstract)
        name
    end
    
    properties
        options % structure containing the fit options
    end
    
    methods
        % constructor
        function this = FitAlgorithm
            
        end %FitAlgorithm
    end
    
    methods (Abstract)
        applyFit(this)
    end       
end

