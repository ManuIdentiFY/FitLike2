classdef Lorentzian < Disp2Exp 
    % Lorentzian model for freely-moving molecules.
    % from:
    % Understanding Spin Dynamics, page 20
    % D. Kruk, Pan Stanford Publishing 2016
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    
    methods
        function model = Lorentzian
                      
            model.modelName = 'Lorentzian profile';        
            model.modelEquation = '3/2*(1.2e-23/rhh^3).^2*[tau./(1+(2*pi*f*tau).^2) + 4*tau./(1+(2*2*pi*f*tau).^2)]';    
            model.variableName = {'f'};     
            model.parameterName = {'rhh',   'tau'};  
            model.minValue =       [0,       1e-9,   ];  
            model.maxValue =       [Inf,     1e-3, ];  
            model.startPoint =     [3e6,     1e-6, ];   
            
            % generate the function handle (do not remove)
            model = makeFunctionHandle(model);
        end
    end
end