classdef ParamagneticSlowMotion < DispersionModel
    % attempt to make a naive model for paramagneticrelaxation. This is
    % more a proof-of-principle than a working model, to show how more
    % advanced modelling may be performed using static methods and nested
    % functions.
    % Model of paramagnetic relaxation with slow motion
    % From: Understanding Spin Dynamics, D. Kruk, Pan Stanford Publishing
    % 2016,  page 139
    % UNFINISHED! Beware, not working in the current state. 
    %
    % Lionel Broche, University of Aberdeen, 23/08/2018
    
    properties
        modelName = 'Paramagnetic contribution, slow motion'; 
        modelEquation = 'functionname(f,a,b,d,tau,N,w12,w23,w13,w34,w24)'; 
        variableName = {'f'}; 
        parameterName = {'a',  'b', 'd','tau','N','w12','w23','w13','w34','w24'}; 
        minValue      = [-Inf -Inf -Inf -Inf -Inf -Inf -Inf -Inf -Inf -Inf ];
        maxValue      = [ Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf  Inf ];
        startPoint    = [   1    1    1    1    1    1    1    1    1    1];
        isFixed       = [   0    0    0    0    0    1    1    1    1    1];
        visualisationFunction@cell = {};
    end
    
    methods
        function this = ParamagneticSlowMotion
            % call superclass constructor
            this = this@DDispersionModel;
        end
    end
    
    % The model for paramagnetic relaxation is quite complex, therefore a
    % dedicated function is required. This is then used in the model
    % equation, to keep things easy.
    methods (Static)
        
        function R1 = functionname(f,a,b,d,tau,N,w12,w23,w13,w34,w24)
            % TO DO: write and test the function...
            S = 1/2;
            mu0 = 4*pi*1e-7;
            gammaI = 42.577e6;
            gammaS = 28025e6;
            hb = 6.626e-34/2/pi;
            wI = 2*pi*f;
            RI   = 3/2*(1+(a^2-b^2))*Jtrans(wI);
            RII  = 6*(a*b)^2*Jtrans(w23);
            RIII = 7/2*a^2*(Jtrans(w13)+Jtrans(w24));
            RIV  = 7/2*b^2*(Jtrans(w12)+Jtrans(w34));
            R1 = 2/3*S*(S+1)*(mu0/(4*pi)*gammaI*gammaS*hb)*(RI + RII + RIII + RIV);
            
            % Density function for the translational motion
            function y = Jtrans(w)
                % y = 3/2*(1.2e-23/rhh^3).^2*[tau./(1+(2*pi*f*tau).^2) + 4*tau./(1+(4*pi*f*tau).^2)]; % rotational (approximation)
                u = linspace(-1000,1000,10000);  % very naive approach, needs much more improvement
                y = arrayfun(@(w)72/5*N/d^3*sum(u.^2./(81-9*u.^2+u.^6)*tau./(1+(w*tau).^2)),w);
            end
        end
        
    end
    
end