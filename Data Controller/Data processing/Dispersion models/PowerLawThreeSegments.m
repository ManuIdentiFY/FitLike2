classdef PowerLawThreeSegments < DataUnit2DataUnit & DataFit
    % Phenomenological model using power laws with three segments. This may
    % be used to model the dispersion of certain polymers or may be used as
    % a kind of linear approximation in the log-log space.  
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    
    properties 
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end
    
    properties
        modelName     = '3-segments power law';
        modelEquation =['(d_l*f.^v_1)*(f<f_trans1)+'...
                        '((d_l*f_trans1^(v_1-v_2))*f^v_2)*(f>f_trans1)*(f<f_trans2)+'...
                        '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))*f^v_3)*(f>f_trans2)'];
        variableName  = {'f'};
        parameterName = {'d_l',  'v_1',  'v_2',   'v_3',    'f_trans1',   'f_trans2'};
        minValue      = [0,       -2,     -2,       -2,         2e3,         4e5];    
        maxValue      = [Inf,      0,      0,        0,         7e5,        10e6];  
        startPoint    = [18,   -0.14,  -0.28,    -0.51,         1e5,         2e6]; 
        isFixed       = [0         0       0         0            0            0]; 
        visualisationFunction = {'(d_l*f.^v_1)', ...
            '((d_l*f_trans1^(v_1-v_2))*f^v_2)',...
            '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))'};
    end

     methods
         function this = PowerLawThreeSegments
             % call superclass constructor
             this = this@DataUnit2DataUnit;
             this = this@DataFit;
         end
    end
end


