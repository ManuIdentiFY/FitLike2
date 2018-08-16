classdef DispersionNlinfit < Disp2Exp
    
    properties
        
    end
    
    methods
        
        function self = process(self,dispersion,fitpar,index)
            % apply the model to the object in the log space
            fhlog = makeLogFunction(self);
            
            % prepare the fit parameter structure
            fitpar.fh = self.model.modelHandle;
            fitpar.var = self.model.variableName;
            fitpar.low = self.model.minValue;
            fitpar.high = self.model.maxValue;
            fitpar.start = self.model.startPoint;
            fitpar.fixed = self.model.isFixed;
            opts = statset('nlinfit');
            opts.Robust = 'on'; 
            opts.MaxFunEvals = 1e4;
            
            % perform the fit
            x = dispersion.x;
            y = dispersion.y;
            [coeff,residuals,~,cov,MSE] = nlinfit(x,log10(abs(squeeze(y))),fhlog,fitpar.start,opts); %non-linear least squares fit

            % Goodness of fit
            sst = sum((y-mean(y)).^2); %sum of square total
            sse = sum(residuals.^2); %sum of square error
            nData = length(y); 
            nCoeff = length(coeff); 

            gof.rsquare =  1 - sse/sst; 
            gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
            gof.RMSE = sqrt(MSE); %to normalize for comparison
            % Error model computation (95% of the confidence interval)
            try
                ci = nlparci(coeff,residuals,'covar',cov);
            catch ME
                disp(ME.message)
                ci = nan(size(coeff));
            end
            coeffError = coeff' - ci(:,1);
            % Dispersion data
            self.model.bestValue = coeff; %get the relaxation rate
            self.model.errorBar = coeffError;
            self.model.gof = gof;
%             self.errorBar = coeffError; %get the model error on the relaxation rate
%             % Gather the result and store it in the corresponding submodel
            self = updateSubModel(self);
        end
        
        
    end
    
end