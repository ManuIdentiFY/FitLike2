classdef PowerLawTwoSegments < DispersionModel
    % Phenomenological model using power laws with two segments. This may
    % be used to model the dispersion of certain polymers or may be used as
    % a kind of linear approximation in the log-log space.
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    % adapted for FitLike2, 16/08/2018
    
    properties
        modelName = '2-segments power law';                             % character string, name of the model, as appearing in the figure legend. You may use spaces here.
        modelEquation =[ '(dl*f.^vlow)*(f<f_trans1) + '...
                           '((dl*f_trans1^(vlow-vhigh))*f^vhigh)*(f>f_trans1)'];  % character string, equation that relates the Larmor frequency (MHz) to the parameters to R1 (s^{-1})
        variableName = {'f'};                                           % Characters, name of the variables appearing in the equation (frequency)
        parameterName = {'dl',  'vlow',  'vhigh', 'f_trans1'};               % List of characters, name of the parameters appearing in the equation
        minValue =      [0,      -2,    -2,      1e3];                  % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue =      [100,      0,     0,     10e6];                  % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint =    [18,    -0.05, -0.32,    0.5e6];                % array of values, starting point for each parameter, respective to the order of parameterName 
        isFixed =       [0        0       0       0 ];
        visualisationFunction@cell = {'dl*f.^vlow', ...
                                           '(dl*f_trans1^(vlow-vhigh))*f^vhigh'};
    end
    
     methods
         function this = PowerLawTwoSegments
             % call superclass constructor
             this = this@DispersionModel;
         end
    end

end
