classdef ModelFreeApproach < DispersionModel
    % Lorentzian model for freely-moving molecules with Gaussian diffusion
    % profiles.
    % From: Understanding Spin Dynamics, D. Kruk, Pan Stanford Publishing
    % 2016,  page 20
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
    
    properties
        modelName     = 'ModelFreeApproach';        
        modelEquation = ['A + Cs*[taus./(1+(2*pi*f*taus).^2) + 4*taus./(1+(4*pi*f*taus).^2)] +'...
                        'Ci*[taui./(1+(2*pi*f*taui).^2) + 4*taui./(1+(4*pi*f*taui).^2)] +'...
                        'Cf*[tauf./(1+(2*pi*f*tauf).^2) + 4*tauf./(1+(4*pi*f*tauf).^2)]'];    
        variableName  = {'f'};     
        parameterName = {'Cs', 'taus',   'Ci',   'taui',     'Cf',   'tauf',  'A'};  
        minValue      = [1e5,    1e-6,    1e6,     1e-7,      1e7,     1e-8,    0]; 
        maxValue      = [1e6,    1e-5,    1e7,     1e-6,      1e8,     1e-7,    Inf]; 
        startPoint    = [5e5,    5e-5,    5e6,     5e-6,      5e7,     5e-7,    0.5];  
        isFixed       = [0,         0,      0,        0,        0,        0,    0];  
        visualisationFunction@cell = {'Cs*[taus./(1+(2*pi*f*taus).^2) + 4*taus./(1+(4*pi*f*taus).^2)]', ...
            'Ci*[taui./(1+(2*pi*f*taui).^2) + 4*taui./(1+(4*pi*f*taui).^2)]',...
            'Cf*[tauf./(1+(2*pi*f*tauf).^2) + 4*tauf./(1+(4*pi*f*tauf).^2)]',...
            'A'};
    end

    methods
        function model = ModelFreeApproach
            model@DispersionModel;
            % additional property used to visualise the individual components

        end
        
        % function that allows estimating the start point.
        % 1. the correlation time are uniformally sampled (log sampling) over
        % the x-values range
        % 2. the weights are set using the following rule: C(1)*tau(1) = 1,
        % C(2)*tau(2) = 1,... avoiding large scale differences between the
        % parameters
        function self = evaluateStartPoint(self,x,~)
            % number of lorentzian and range of data
            N = 3; %can be customed if more components
            r = [min(x) max(x)];
            
            % sample uniformaly the frequency space (log scaling)
            step = round(range(log10(r))/(N+1));
            
            % respect the relation: C = 1/tau            
            for k = 1:N
                C0 = 10^(log10(r(1)) + step);
                self.startPoint(2*k-1:2*k) = [C0, 1/C0];
            end
        end
    end
    
end

