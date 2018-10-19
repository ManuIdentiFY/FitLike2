classdef PowerLawFourSegments < DispersionModel
    % Phenomenological model using power laws with four segments. This is
    % not derived from physical models but is a kind of linear
    % approximation in the log-log space.
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
    
    properties
        modelName     = 'Power law with four segments';
        modelEquation =['(d_l*f^v_1)*(f<f_trans1) +' ...
                        '((d_l*f_trans1^(v_1-v_2))*f^v_2)*(f>f_trans1)*(f<f_trans2) +' ...
                        '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))*f^v_3)*(f>f_trans2)*(f<f_trans3) +' ...
                        '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3)*f_trans3^(v_3-v_4))*f^v_4)*(f>f_trans3)'];  
        variableName  = {'f'};                                                                   
        parameterName = {'d_l', 'v_1', 'v_2', 'v_3', 'v_4', 'f_trans1', 'f_trans2', 'f_trans3'};   
        minValue      = [0,      -2,    -2,    -2,    -2,        10,    0.01e6,      0.1e6];       
        maxValue      = [Inf,     0,     0,     0,     0,     1.1e4,    0.11e6,       10e6];       
        startPoint    = [5,    -0.5,  -0.2,  -0.2,  -0.2,       2e3,    0.02e6,        1e6];   
        isFixed       = [0        0      0      0      0         0           0           0];     
    end

    
     methods
        function model = PowerLawFourSegments
            % additional property used to visualise the individual components
            model.visualisationFunction = {'(d_l*f^v_1)', ...
                                           '((d_l*f_trans1^(v_1-v_2))*f^v_2)',...
                                           '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))*f^v_3)',...
                                           '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3)'};
        end 

        function self = evaluateStartPoint(self,x,y)

        end
    end
end

