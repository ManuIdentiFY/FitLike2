classdef BiexponentialT2 < Bloc2Zone & DataFit
    
   properties
        functionName@char = 'Biexponential T2 decay';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Long T2','Short T2'};         % tag appearing in the legend of data derived from this object
   end
   
   properties
       modelName = 'Biexponential T2';          % character string, name of the model, as appearing in the figure legend
       modelEquation = 'abs(M0 + A1*exp(-t*R21) + A2*exp(-t*R22))';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
       variableName = {'t'};                                  % List of characters, name of the variables appearing in the equation
       parameterName = {'M0','A1','R21','A2','R22'};        % List of characters, name of the parameters appearing in the equation
       isFixed = [0 0 0 0 0];                               % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
       minValue = [-Inf -Inf -Inf -Inf -Inf];               % array of values, minimum values reachable for each parameter, respective to the order of parameterName
       maxValue = [Inf Inf Inf Inf Inf];               % array of values, maximum values reachable for each parameter, respective to the order of parameterName
       startPoint = [1 1 1 1 1];             % array of values, starting point for each parameter, respective to the order of parameterName
   end
    
    methods
        function this = BiexponentialT2
            % call superclass constructor
            this = this@Bloc2Zone;
            this = this@DataFit;
        end
    end
    
    methods
        % dummy function. Can be improved by adding new property DataIndex
        % or something similar [Manu]
        function data = formatFitData(this)
            % collect result from fit
            data.y =  [this.bestValue(3), this.bestValue(5)];
            data.dy = [this.errorBar(3),  this.errorBar(5)];
        end %formatFitData
        
        % fill in the starting point of the model
        function this = evaluateStartPoint(this, xdata, ydata)  
            ydata = abs(ydata);
            this.startPoint = [ydata(end),...
                               (ydata(1)-ydata(end))*2/3,...
                               3/xdata(end),...
                               (ydata(1)-ydata(end))/3,...
                               10/xdata(end)];
        end
        
% 
%         % this is where you should put the algorithm that processes the raw
%         % data. Multi-component algorithms can store several results along
%         % a single dimension (z and dz are column arrays).
%         % NOTE: additional info from the process can be stored in the
%         % structure paramFun
%         function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL>
%             
%             % Exponential fit
%             fitModel = @(c, x) abs(c(1) + c(2)*exp(-x*c(3)) + c(4)*exp(-x*c(5))); %exponential model
% 
%             opts = statset('nlinfit');
%             opts.Robust = 'on';
%             y = abs(y);
% 
%             startPoint = [y(end),(y(1)-y(end))*2/3, 3/x(end), (y(1)-y(end))/3, 10/x(end)];
%             
%             % nlinfit is sensitive to NaN and errors
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
%             % Goodness of fit
%             sst = sum((y-mean(y)).^2); %sum of square total
%             sse = sum(residuals.^2); %sum of square error
%             nData = length(y); 
%             nCoeff = length(coeff); 
%             gof.rsquare =  1 - sse/sst; 
%             gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
%             gof.RMSE = sqrt(MSE); %to normalize for comparison
%             
%             % Error model computation (95% of the confidence interval)
%             ci = nlparci(coeff,residuals,'covar',cov);
%             coeffError = coeff' - ci(:,1);
%             
%             % Dispersion data
%             z = [coeff(3) coeff(5)]; %get the relaxation rate
%             dz = [coeffError(3) coeffError(5)]; %get the model error on the relaxation rate
%             
%             % Model structure
%             paramFun.modelEquation = functions(fitModel);
%             paramFun.modelHandle = fitModel;
%             paramFun.parameterName = {'M_inf','/DeltaM0_1','R_2^1', '/DeltaM0_2','R_2^2'};
%             paramFun.coeff = coeff;
%             paramFun.coeffError = coeffError;
%             paramFun.gof = gof;
%         end
    end
end
