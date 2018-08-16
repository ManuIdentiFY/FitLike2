classdef PowerLawTwoSegment < DispersionModel
    % Class template for models of NMRD profiles. To use it:
    % - Replace 'ModelName' by the name of the model you wish to implement
    % (type control+f and replace). Do not use space or special characters.
    % - Save the file using the same model name.
    % - Adapt the values of the properties to your needs.
    % that is it.
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    % adapted for FitLike2, 16/08/2018
properties
    modelName = '2-segments power law';                             % character string, name of the model, as appearing in the figure legend. You may use spaces here.
    modelEquation =[ '(dl*f.^v1)*(f<f_trans1) + '...
                       '((dl*f_trans1^(v1-v2))*f^v2)*(f>f_trans1)'];  % character string, equation that relates the Larmor frequency (MHz) to the parameters to R1 (s^{-1})
    variableName = {'f'};                                           % Characters, name of the variables appearing in the equation (frequency)
    parameterName = {'dl',  'v1',  'v2', 'f_trans1'};               % List of characters, name of the parameters appearing in the equation
    minValue =      [0,      -2,    -2,      1e3];                  % array of values, minimum values reachable for each parameter, respective to the order of parameterName
    maxValue =      [100,      0,     0,     1e7];                  % array of values, maximum values reachable for each parameter, respective to the order of parameterName
    startPoint =    [18,    -0.05, -0.32,    2.5e6];                % array of values, starting point for each parameter, respective to the order of parameterName 
    isFixed =       [0        0       0       0 ];
end
    
 methods
    function model = PowerLawTwoSegment

    end

    function self = evaluateStartPoint(self,x,y)

    end
end

end
