classdef MonoexpAbs < Zone2Disp
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
    properties
        functionName@char = 'Monoexponential magnitude';      % character string, name of the model, as appearing in the figure legend
        labelY@char = 'R_1 (s^{-1})';                   % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution field (MHz)';          % string, labels the X-axis data in graphs
        legendTag@cell = {'dispersion T1'};
    end
    
    methods
        % this is where you should put the algorithm that processes the raw
        % data. Multi-component algorithms can store several results along
        % a single dimension (z and dz are column arrays).
        function [z,dz,paramFun] = process(self,x,y,zone,index) %#ok<*INUSD,*INUSL>
            T1MX = zone.parameter.paramList.T1MX(index);
            
            % Exponential fit
            fitModel = @(c, x)sqrt(((c(1)-c(2))*exp(-x*c(3))+c(2)).^2 + ...
                                 2*((c(1)-c(2))*exp(-x*c(3))+c(2)).*abs(c(4)) +...
                                 2*c(4).^2); %exponential model with Gaussian noise
            
            opts = statset('nlinfit');
            opts.Robust = 'on';
            opts.Display = 'off';
            opts.MaxFunEvals = 1e8;
            opts.MaxIter = 3e4;
            
            startPoint = [y(1),-y(end),1/T1MX,y(1)/10]; 
%             if isfield(zone.parameter.paramList,'coeff')
%                 if ~isempty(zone.parameter.paramList.coeff)
%                     startPoint = zone.parameter.paramList.coeff(index,:);
%                 end
%             end
            try
                [coeff,residuals,~,cov,MSE] = nlinfit(x,abs(y),fitModel,startPoint,opts); %non-linear least squares fit
            catch ME
                disp(ME.message)
                coeff = startPoint;
                residuals = zeros(size(y));
                cov = zeros(length(startPoint),length(startPoint));
                MSE = 0;
            end
                
            %% Goodness of fit
            sst = sum((y-mean(y)).^2); %sum of square total
            sse = sum(residuals.^2); %sum of square error
            nData = length(y); 
            nCoeff = length(coeff); 

            gof.rsquare =  1 - sse/sst; 
            gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
            gof.RMSE = sqrt(MSE); %to normalize for comparison
            %% Error model computation (95% of the confidence interval)
            ci = nlparci(coeff,residuals,'covar',cov);
            coeffError = coeff' - ci(:,1);
            %% Dispersion data
            z = coeff(3); %get the relaxation rate
            dz = coeffError(3); %get the model error on the relaxation rate
            %% Model structure
            paramFun.modelEquation = '(M_0-M_inf)*exp(-t*R_1)+M_inf';
            paramFun.modelHandle = fitModel;
            paramFun.parameterName = {'M_0','M_inf','R_1'};
            paramFun.coeff = coeff;
            paramFun.coeffError = coeffError;
            paramFun.gof = gof;
            
        end
    end
        
    
end

