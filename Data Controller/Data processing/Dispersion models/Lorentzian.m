classdef Lorentzian < DispersionModel
    % Lorentzian model for freely-moving molecules with Gaussian diffusion
    % profiles.
    % From: Understanding Spin Dynamics, D. Kruk, Pan Stanford Publishing
    % 2016,  page 20
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017 (modified 23/08/18)
    
    properties
        modelName     = 'Lorentzian profile';        
        modelEquation = '3/2*(1.2e-23/rhh^3).^2*[tau./(1+(2*pi*f*tau).^2) + 4*tau./(1+(4*pi*f*tau).^2)]';    
        variableName  = {'f'};     
        parameterName = {'rhh',   'tau'};  
        minValue      = [0,       1e-9];  
        maxValue      = [Inf,     1e-3];  
        startPoint    = [3e-10,   1e-6];  
        isFixed       = [0           0];
    end
    
    methods
        function model = Lorentzian
            model@DispersionModel;
            % generate the function handle (do not remove)
%             model = makeFunctionHandle(model);
        end
        
        % function that allows estimating the start point.
        function self = evaluateStartPoint(self,x,y)
            % make sure the data is sorted
            [x,ord] = sort(x);
            y = y(ord);
            % estimate tau from the half-peak value
            if length(y)>10
                yLowFreq = 10^median(log10(y(1:10)));
            else
                yLowFreq = y(1);
            end
            [~,indm] = min(abs(y-yLowFreq/2));
            tau = 1/x(indm);
            % then rhh is estimated from the low-frequency limit
            rhh = (1.2e-23)^(1/3)/(yLowFreq/(5*tau)*2/3)^(1/6);
            self.startPoint = [rhh,tau];
        end
    end
end