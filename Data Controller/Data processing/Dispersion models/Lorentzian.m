classdef Lorentzian < DataUnit2DataUnit & DataFit
    % Lorentzian model for freely-moving molecules with Gaussian diffusion
    % profiles.
    % From: Understanding Spin Dynamics, D. Kruk, Pan Stanford Publishing
    % 2016,  page 20
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
    
    properties 
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end 
    
    properties
        modelName     = 'Lorentzian profile';        
        modelEquation = '3/2*(1.2e-23/rhh^3).^2*[tau./(1+(2*pi*f*tau).^2) + 4*tau./(1+(4*pi*f*tau).^2)]';    
        variableName  = {'f'};     
        parameterName = {'rhh',   'tau'};  
        minValue      = [0,       1e-9];  
        maxValue      = [Inf,     1e-3];  
        startPoint    = [3e-10,   1e-6];  
        isFixed       = [0           0];
         visualisationFunction@cell = {};
    end
    
     methods
        function this = Lorentzian
            % call superclass constructor
            this = this@DataUnit2DataUnit;
            this = this@DataFit;
        end
    end
    
    methods
        % function that allows estimating the start point.
        function this = evaluateStartPoint(this, xdata, ydata)
            % make sure the data is sorted
            [xdata,ord] = sort(xdata);
            ydata = ydata(ord);
            % estimate tau from the half-peak value
            if length(ydata)>10
                yLowFreq = 10^median(log10(ydata(1:10)));
            else
                yLowFreq = ydata(1);
            end
            [~,indm] = min(abs(ydata-yLowFreq/2));
            tau = 1/xdata(indm);
            % then rhh is estimated from the low-frequency limit
            rhh = (1.2e-23)^(1/3)/(yLowFreq/(5*tau)*2/3)^(1/6);
            this.startPoint = [rhh,tau];
        end
    end
end