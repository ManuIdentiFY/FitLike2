classdef PowerLawOneSegment < DispersionModel
    % Phenomenological model using power laws with two segments. This may
    % be used to model the dispersion of certain polymers or may be used as
    % a kind of linear approximation in the log-log space.
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    % adapted for FitLike2, 16/08/2018
    
    properties
        modelName = '1-segment power law';                             % character string, name of the model, as appearing in the figure legend. You may use spaces here.
        modelEquation ='(dl*f.^v)';  % character string, equation that relates the Larmor frequency (MHz) to the parameters to R1 (s^{-1})
        variableName = {'f'};                                           % Characters, name of the variables appearing in the equation (frequency)
        parameterName = {'dl',  'v'};               % List of characters, name of the parameters appearing in the equation
        minValue =      [0,      -2];                  % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue =      [1e4,      0];                  % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint =    [18,    -0.16];                % array of values, starting point for each parameter, respective to the order of parameterName
        isFixed =       [0        0];
        visualisationFunction@cell = {'dl*f.^v'};
    end
    
 methods
     function this = PowerLawOneSegment
         % call superclass constructor
         this = this@DispersionModel;
     end
end

end
