classdef DispersionLsqCurveFit < Disp2Exp
    
    properties
        functionName@char = 'Least square fit';  % character string, name of the model, as appearing in the figure legend
        labelY@char = 'fit result';              % string, labels the Y-axis data in graphs
        labelX@char = 'Experimental parameter';  % string, labels the X-axis data in graphs
        legendTag@cell = {'Data tag'};             % cell of strings, contain the legend associated with the data processed
    end
    
    methods
        
        function self = process(self,dispersion,index)
            % apply the model to the object in the log space
            fhlog = makeLogFunction(self);
            
            % prepare the fit parameter structure
            fitpar.fh = self.model.modelHandle;
            fitpar.var = self.model.variableName;
            fitpar.low = self.model.minValue;
            fitpar.high = self.model.maxValue;
            fitpar.start = self.model.startPoint;
            fitpar.fixed = self.model.isFixed;
            opts = optimset('lsqcurvefit');
%             opts.Robust = 'on'; 
            opts.MaxFunEvals = 1e4;
            opts.TypicalX = self.model.startPoint;
            opts.Display = 'off';
            
            % perform the fit
            x = dispersion.x(dispersion.mask);
            y = dispersion.y(dispersion.mask);
            [coeff,resnorm,residuals,exitflag,output,lambda,jacobian] = lsqcurvefit(fhlog,...
                                                                                    self.model.startPoint,...
                                                                                    x,log10(y),...
                                                                                    self.model.minValue,...
                                                                                    self.model.maxValue,...
                                                                                    opts);
            
            % Goodness of fit
            sst = sum((y-mean(y)).^2); %sum of square total
            sse = sum(residuals.^2); %sum of square error
            nData = length(y); 
            nCoeff = length(coeff); 

            gof.rsquare =  1 - sse/sst; 
            gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
            gof.RMSE = sqrt(resnorm); %to normalize for comparison
            % Error model computation (95% of the confidence interval)
            try
                ci = nlparci(coeff,residuals,'jacobian',jacobian);
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