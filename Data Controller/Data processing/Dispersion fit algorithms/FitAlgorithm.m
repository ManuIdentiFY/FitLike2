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
        
        
        % dummy function. Can be improved by adding new property DataIndex
        % or something similar [Manu]
        function data = formatFitData(this,selectionArray)
            % collect result from fit
            data.y =  this.bestValue(selectionArray);
            data.dy = this.errorBar(selectionArray);
        end %formatFitData
        
    end
    
    methods (Abstract)
        applyFit(this)
    end       
end

