classdef ParamagneticSlowMotion < DispersionModel
    % Model of paramagnetic relaxation with slow motion
    % From: Understanding Spin Dynamics, D. Kruk, Pan Stanford Publishing
    % 2016,  page 139
    % UNFINISHED! Beware...
    %
    % Lionel Broche, University of Aberdeen, 23/08/2018
            
    properties
        modelName = 'Paramagnetic contribution, slow motion'; 
        modelEquation = 'functionname(f,tau_R,tau_V,D_S,E_S,D_T)'; 
        variableName = {}; 
        parameterName = {}; 
        minValue = [];
        maxValue = [];
        startPoint = [];
        isFixed = [];
    end
    
    % The model for paramagnetic relaxation is quite complex, therefore a
    % dedicated function is required. This is then used in the model
    % equation, to keep things easy.
    methods (Static)
        
        function R1 = functionname(f,a,b,w12,w23,w13,w34,w24,tau)
            % TO DO: write and test the function...
            wI = 2*pi*f;
            RI   = 3/2*(1+(a^2-b^2))*Jtrans(wI);
            RII  = 6*(a*b)^2*Jtrans(w23);
            RIII = 7/2*a^2*(Jtrans(w13)+Jtrans(w24));
            RIV  = 7/2*b^2*(Jtrans(w12)+Jtrans(w34));
            R1 = 2/3*S*(S+1)*(mu0/(4*pi)*gammaI*gammaS*hb)*(RI + RII + RIII + RIV);
            
            % Density function for the translational motion
            function y = Jtrans(w)
                % y = 3/2*(1.2e-23/rhh^3).^2*[tau./(1+(2*pi*f*tau).^2) + 4*tau./(1+(4*pi*f*tau).^2)]; % rotational (approximation)
                y = 72/5*1/d^3*N*sum(u.^2./(81+9*u.^2-2*u.^4+u.^6)*(u.^2*tau)./(u.^4+(w*tau).^2));  % not working yet, needs careful indexing to deal with w
            end
        end
        
    end
    
end