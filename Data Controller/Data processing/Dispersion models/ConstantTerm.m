classdef ConstantTerm < DataUnit2DataUnit & DataFit
    % This model adds a constant contribution to model fast motion such as
    % free water in fast rotation. 
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
    
    properties 
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end              
    
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
            this = this@DataUnit2DataUnit;
            this = this@DataFit;
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