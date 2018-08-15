classdef BiexponentialT1 < Zone2Disp
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
    
    methods
        function self = BiexponentialT1
            self@Zone2Disp;
            
            self.functionName = 'Biexponential fit';      % character string, name of the model, as appearing in the figure legend
            self.labelY = 'R_1 (s^{-1})';                   % string, labels the Y-axis data in graphs
            self.labelX = 'Evolution field (MHz)';          % string, labels the X-axis data in graphs
        end
    end

    methods
        % this is where you should put the algorithm that processes the raw
        % data. Multi-component algorithms can store several results along
        % a single dimension (z and dz are column arrays).
        function [z,dz,paramFun] = process(self,x,y,paramObj,index) %#ok<*INUSD,*INUSL>
            
            % Exponential fit
            fitModel = @(c, x) abs(c(1)*exp(-x*c(2)) + c(3)*exp(-x*c(4)) + c(5)); %exponential model

            opts = statset('nlinfit');
            opts.Robust = 'on';
            y = abs(y);
            startPoint = [y(end),(y(1)-y(end))*2/3, 3/x(end), (y(1)-y(end))/3, 10/x(end)]; 
            try
                [coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit
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
            z = [coeff(2) coeff(4)]; %get the relaxation rate
            dz = [coeffError(2) coeffError(4)]; %get the model error on the relaxation rate
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
