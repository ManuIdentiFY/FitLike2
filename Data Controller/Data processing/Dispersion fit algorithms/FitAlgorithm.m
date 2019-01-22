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
    
    methods
        function this = set.options(this, val)
            % call check function
            val = checkOptions(this, val);
            
            % set value
            this.options = val;
        end
    end
    
    methods (Access = protected)
        % dummy function that can be redefined in subclasses
        function val = checkOptions(this,val)            
        end %checkOptions
    end
end

