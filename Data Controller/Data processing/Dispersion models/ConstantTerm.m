classdef ConstantTerm < DispersionModel
    % This model adds a constant contribution to model fast motion such as
    % free water in fast rotation. 
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)           
    
    properties
        modelName     = 'Constant term';       
        modelEquation = 'Rconstant + 0*f';  
        variableName  = {'f'}; 
        parameterName = {'Rconstant'}; 
        minValue      = 0;        
        maxValue      = Inf;     
        startPoint    = 0.3;  
        isFixed       = 0;
        visualisationFunction@cell = {};
    end
    
    methods
        function this = ConstantTerm
            % call superclass constructor
            this = this@DispersionModel;
        end
    end
    
    methods
        function this = evaluateStartPoint(this, xdata, ydata)
            [~,ord] = sort(xdata);
            ydata = ydata(ord);
            this.startPoint = ydata(end);
        end
    end
end