classdef Rorsschach < DataUnit2DataUnit & DataFit
    
    %H.E. Rorsschach - 1986
    % Vasileios Zampetoulas, University of Aberdeen, 2016
    % Adapted for FitLike2 by LB, 23/08/18
              
    properties 
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end
    
    properties
        modelName = 'Rorsschach';
        modelEquation = ['(M_ratio/(1 + M_ratio))*R_s + (M_ratio/(1 + M_ratio))*Var*((-2*atand(1-sqrt(2)*sqrt((w*tau_corrmax)))'...
        '+2*atand(1 + sqrt(2)*sqrt((w*tau_corrmax)))- log(1 - sqrt(2)*sqrt((w*tau_corrmax))'...
        '+ (w*tau_corrmax)) +log(1 + sqrt(2)*sqrt((w*tau_corrmax))+(w*tau_corrmax)))/(2*sqrt(2))'...
        '-(-2*atand(1 - sqrt(2)*sqrt((w*tau_corrmin))) + 2*atand(1 + sqrt(2)*sqrt((w*tau_corrmin)))'...
        '-log(1 - sqrt(2)*sqrt((w*tau_corrmin)) + (w*tau_corrmin))'...
        '+ log(1 + sqrt(2)*sqrt((w*tau_corrmin)) + (w*tau_corrmin)))/(2*sqrt(2)))'];
        variableName = {'f'}; 
        parameterName = {'M_ratio', 'R_s',  'tau_corrmax', 'tau_corrmin',  'Var'};
        minValue = [    0,        0,         0,              0,          0];     
        maxValue = [   Inf,       1,        Inf,             0.1,       Inf];
        startPoint = [   10,       0.4,     7e-6,            7e-10,     10];
        isFixed = [0 0 0 0 0];
        visualisationFunction@cell = {};
    end
    
    methods
         function this = Rorsschach
             % call superclass constructor
             this = this@DataUnit2DataUnit;
             this = this@DataFit;
         end
    end
end