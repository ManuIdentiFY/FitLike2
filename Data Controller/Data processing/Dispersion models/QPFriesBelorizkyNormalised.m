classdef QPFriesBelorizkyNormalised < DispersionModel
    % model for 14N quadrupolar peaks in biological tissues
    %
    % Derived from: 
    % Fries P.H., Belorizky E. Simple expressions of the nuclear relaxation
    % rate enhancement due to quadrupole nuclei in slowly tumbling molecules. J. Chem. Phys. 2015;143(4).
    % Link: http://aip.scitation.org/doi/full/10.1063/1.4926827
    %
    % This version of the model factorises the tau value into the
    % amplitude term Aqp in order to avoid error propagation from
    % tau, which is usually poorly defined. As a result, Aqp
    % relates directly to the amplitude of the peaks, which is more
    % intuitive.
    % Lionel Broche, University of Aberdeen, 23/08/18
    
    properties            
        modelName     = 'QPFriesBelorizkyNormalised';
        modelEquation = ['A_qp*[(1/3 + (sind(theta)*cosd(phi))^2) * (1/(1+((2*pi*f)-(2*pi*f_q)*(3+eta))^2*tau^2) + 1/(1+((2*pi*f)+(2*pi*f_q)*(3+eta))^2*tau^2)) + ' ...
            '(1/3 + (sind(theta)*sind(phi))^2) * (1/(1+((2*pi*f)-(2*pi*f_q)*(3-eta))^2*tau^2) + 1/(1+((2*pi*f)+(2*pi*f_q)*(3-eta))^2*tau^2)) + ' ...
            '(1/3 + cos(theta)^2) *              (1/(1+((2*pi*f)-(2*pi*f_q)*2*eta)^2*tau^2)   + 1/(1+((2*pi*f)+(2*pi*f_q)*2*eta)^2*tau^2))   ]'];
        variableName  =  {'f'};
        parameterName = {'A_qp',  'tau',  'f_q',     'eta', 'theta', 'phi'};
        isFixed       = [0        0      0        0          0          0];
        minValue      = [0,      0.4e-6,    0.6e6,     0.35,      0,      -90];
        maxValue      = [Inf,    2e-6,    0.9e6,     0.55,        90,        90];
        startPoint    = [1,      0.5e-6,    0.81e6,   0.49,       90,      25.6];
        visualisationFunction@cell = {};
    end
    
    methods
         function this = QPFriesBelorizkyNormalised
             % call superclass constructor
             this = this@DispersionModel;
         end
    end
end

