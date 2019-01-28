classdef Monoexp < Zone2Disp & DataFit
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
    properties
        functionName@char = 'Monoexponential fit';      % character string, name of the model, as appearing in the figure legend
        labelY@char = 'R_1 (s^{-1})';                   % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution field (MHz)';          % string, labels the X-axis data in graphs
        legendTag@cell = {'T1'};
    end
       
    properties
       modelName = 'Monoexponential T1';          % character string, name of the model, as appearing in the figure legend
       modelEquation = '(M0-Minf)*exp(-x*R1)+Minf';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
       variableName = {'t'};                                  % List of characters, name of the variables appearing in the equation
       parameterName = {'M0','Minf','R1'};        % List of characters, name of the parameters appearing in the equation
       isFixed = [0 0 0];                               % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
       minValue = [-Inf -Inf -Inf];               % array of values, minimum values reachable for each parameter, respective to the order of parameterName
       maxValue = [Inf Inf Inf];               % array of values, maximum values reachable for each parameter, respective to the order of parameterName
       startPoint = [1 1 1];             % array of values, starting point for each parameter, respective to the order of parameterName
       valueToReturn = [0 0 1 0];
       visualisationFunction@cell = {};
   end
%         numberOfOutputs = 1;	% defined in DataModel
%         numberOfInputs  = 1;	% defined in DataModel

    methods
        function this = Monoexp
            % call superclass constructor
            this = this@Zone2Disp;
            this = this@DataFit;
        end
    end
    
    methods
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)
            ydata = abs(ydata);
            this.startPoint = [ydata(1), -ydata(end), 1/xdata(end)];
        end
    end %evaluateStartPoint
%     
%     methods
%         % this is where you should put the algorithm that processes the raw
%         % data. Multi-component algorithms can store several results along
%         % a single dimension (z and dz are column arrays).
%         function [z,dz,paramFun] = process(self,x,y,zone,index) %#ok<*INUSD,*INUSL>
%             T1MX = zone.parameter.paramList.T1MX(index);
%             
%             % Exponential fit
%             fitModel = @(c, x)((c(1)-c(2))*exp(-x*c(3))+c(2)); %exponential model
%             
%             opts = statset('nlinfit');
%             opts.Robust = 'on';
%             opts.Display = 'off';
% 
%             startPoint = [y(1),y(end),1/T1MX]; 
%             try
%                 [coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit
%             catch ME
%                 disp(ME.message)
%                 coeff = startPoint;
%                 residuals = zeros(size(y));
%                 cov = zeros(length(startPoint),length(startPoint));
%                 MSE = 0;
%             end
%                 
%             %% Goodness of fit
%             sst = sum((y-mean(y)).^2); %sum of square total
%             sse = sum(residuals.^2); %sum of square error
%             nData = length(y); 
%             nCoeff = length(coeff); 
% 
%             gof.rsquare =  1 - sse/sst; 
%             gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
%             gof.RMSE = sqrt(MSE); %to normalize for comparison
%             %% Error model computation (95% of the confidence interval)
%             ci = nlparci(coeff,residuals,'covar',cov);
%             coeffError = coeff' - ci(:,1);
%             %% Dispersion data
%             z = coeff(3); %get the relaxation rate
%             dz = coeffError(3); %get the model error on the relaxation rate
%             %% Model structure
%             paramFun.modelEquation = '(M_0-M_inf)*exp(-t*R_1)+M_inf';
%             paramFun.modelHandle = fitModel;
%             paramFun.parameterName = {'M_0','M_inf','R_1'};
%             paramFun.coeff = coeff;
%             paramFun.coeffError = coeffError;
%             paramFun.gof = gof;
%         end
%     end
        
    
end

