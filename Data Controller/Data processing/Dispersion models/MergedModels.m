classdef MergedModels < DispersionModel
    %  Class used to merge dispersion models

    properties
        
        modelName     = 'Merged models';  % character string, name of the model as appearing in the figure legend or elsewhere. You may use spaces here.
        modelEquation = '';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        variableName  = {'f'};          % List of characters, name of the variables appearing in the equation (usually the frequency). Only one-D support for now, but it may change in the future...
        parameterName = {'param'};     % List of characters, name of the parameters appearing in the equation in any order, but the order defined here is the same as for the boundary arrays below
        minValue      = []      % array of values, minimum boundary for each parameter, respective to the order of parameterName
        maxValue      = []      % array of values, maximum boundary for each parameter, respective to the order of parameterName
        startPoint    = [];      % array of values, starting point for each parameter, respective to the order of parameterName 
        isFixed       = [];      % array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
                    
        visualisationFunction@cell = {};
    end

    methods
        % Here replace ModelTemplate by your classname
        function this = MergedModels(varargin)
            % call superclass constructor
            this = this@DispersionModel;
            for i = 1:2:numel(varargin)
                this.(varargin{i}) = varargin{i+1};
            end
            this = merge(this);
        end
    end
    
    methods
        
        % merge sub-models into one model
        function this = merge(this)
            
        end
        
        function this = evaluateStartPoint(this,xdata,ydata)

        end
        
    end

end % end of the class (do not delete)