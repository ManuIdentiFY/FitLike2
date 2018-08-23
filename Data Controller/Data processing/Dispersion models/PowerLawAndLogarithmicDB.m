classdef PowerLawAndLogarithmicDB < DispersionModel
    % Power law with logarithmic segment at the low-frequency end. Derived
    % for the modelling of free proteins dynamics
    % Note that the constant term has been removed from the original
    % equation since it may cause some problems when it cannot be
    % estimated. It can easily be added to the model by adding the model
    % 'ConstantTerm'.
    %
    % From:
    % Diakova G., Korb J.B., Bryant R.G. The magnetic field dependence
    % of water T1 in tissues. Magnetic Resonance in Medicine. 2012;68:272-277.
    % Link: http://onlinelibrary.wiley.com/doi/10.1002/mrm.23229/pdf
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
                 
    properties
        modelName     = 'Piecewise power law and logarithmic';
        modelEquation = ['A*(2*pi*f)^v + '...
                         'B*taud*(log(1 + 1/(taud*2*pi*f)^2) + '...
                         '      4*log(1 + 1/(2*taud*2*pi*f)^2))'];            
        variableName  = {'f'};            
        parameterName = {'A',   'v',   'B',   'taud'};
        minValue      = [0,      -2,    0,     1e-8]; 
        maxValue      = [Inf,    0,     Inf,   1e-4];
        startPoint    = [7e4,    -0.3,  3e10,  1e-06];
        isFixed       = [ 0       0      0      0];
    end
    
    methods
        function model = PowerLawAndLogarithmicDB
            % additional property used to visualise the individual components
            model.visualisationFunction = {'A*(2*pi*f)^v', ...
                                           'B*taud*(log(1 + 1/(taud*2*pi*f)^2) + 4*log(1 + 1/(2*taud*2*pi*f)^2))'};
        end
        
    end
end