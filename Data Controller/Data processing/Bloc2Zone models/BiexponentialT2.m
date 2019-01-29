classdef BiexponentialT2 < Bloc2Zone & DataFit
    
   properties
        InputChildClass@char; 	% defined in DataUnit2DataUnit
        OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'Biexponential T2 decay';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Long T2','Short T2'};         % tag appearing in the legend of data derived from this object
   end
   
   properties
       modelName = 'Biexponential T2';          % character string, name of the model, as appearing in the figure legend
       modelEquation = 'abs(M0 + A1*exp(-t*R21) + A2*exp(-t*R22))';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
       variableName = {'t'};                                  % List of characters, name of the variables appearing in the equation
       parameterName = {'M0','A1','R21','A2','R22'};        % List of characters, name of the parameters appearing in the equation
       isFixed = [0 0 0 0 0];                               % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
       minValue = [-Inf -Inf -Inf -Inf -Inf];               % array of values, minimum values reachable for each parameter, respective to the order of parameterName
       maxValue = [Inf Inf Inf Inf Inf];               % array of values, maximum values reachable for each parameter, respective to the order of parameterName
       startPoint = [1 1 1 1 1];             % array of values, starting point for each parameter, respective to the order of parameterName
       valueToReturn = [0 0 1 0 1];          % set which fit parameters must be returned by the function
       visualisationFunction@cell = {};
   end
    
    methods
        function this = BiexponentialT2
            % call superclass constructor
            this = this@Bloc2Zone;
            this = this@DataFit;
        end
    end
    
    methods        
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)  
            ydata = abs(ydata);
            this.startPoint = [ydata(end),...
                               (ydata(1)-ydata(end))*2/3,...
                               3/xdata(end),...
                               (ydata(1)-ydata(end))/3,...
                               10/xdata(end)];
        end
       
    end
end
