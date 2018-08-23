classdef PowerLawThreeSegments < DispersionModel
    % Phenomenological model using power laws with three segments. This may
    % be used to model the dispersion of certain polymers or may be used as
    % a kind of linear approximation in the log-log space.  
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017

    properties

        modelName     = 'Power law with three segments';
        modelEquation =['(d_l*f.^v_1)*(f<f_trans1)+'...
                        '((d_l*f_trans1^(v_1-v_2))*f^v_2)*(f>f_trans1)*(f<f_trans2)+'...
                        '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))*f^v_3)*(f>f_trans2)'];
        variableName  = {'f'};
        parameterName = {'d_l',  'v_1',  'v_2',   'v_3',    'f_trans1',   'f_trans2'};
        minValue      = [0,       -2,     -2,       -2,        2e-3,        4e-1];    
        maxValue      = [Inf,      0,      0,        0,         0.7,          10];  
        startPoint    = [18,   -0.14,  -0.28,    -0.51,         0.1,           2]; 
        isFixed       = [0         0       0         0            0            0];   
    end

     methods
        function model = PowerLawThreeSegments
            % additional property used to visualise the individual components
            model.visualisationFunction = {'(d_l*f.^v_1)', ...
                                           '((d_l*f_trans1^(v_1-v_2))*f^v_2)',...
                                           '(((d_l*f_trans1^(v_1-v_2))*f_trans2^(v_2-v_3))'};
        end 

        function self = evaluateStartPoint(self,x,y)

        end
    end
end


