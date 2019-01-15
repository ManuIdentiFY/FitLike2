classdef DispersionLsqCurveFit < Disp2Exp
    
    properties
        functionName@char = 'Least square fit';  % character string, name of the model, as appearing in the figure legend
        labelY@char = 'fit result';              % string, labels the Y-axis data in graphs
        labelX@char = 'Experimental parameter';  % string, labels the X-axis data in graphs
        legendTag@cell = {'Data tag'};             % cell of strings, contain the legend associated with the data processed
    end
    
    methods
        
        function this = DispersionLsqCurveFit(varargin)
            this@Disp2Exp(varargin{:});
        end
        
        function this = process(this, dispersion, index)
            % apply the model to the object in the log space
            fhlog = makeLogFunction(this);
            
            % prepare the fit parameter structure
            fitpar.fixed = this.model.isFixed;
            fitpar.fh = this.model.modelHandle;
            fitpar.var = this.model.variableName;
            fitpar.low = this.model.minValue;
            fitpar.high = this.model.maxValue;
            fitpar.start = this.model.startPoint;
            opts = optimset('lsqcurvefit');
%             opts.Robust = 'on'; 
            opts.MaxFunEvals = 1e4;
            opts.TypicalX = this.model.startPoint(~fitpar.fixed);
            opts.Display = 'off';
            
            % deal with fixed coefficients
            x = dispersion.x(dispersion.mask);
            y = dispersion.y(dispersion.mask);
            fhnonfixed = this.setFixedParameter(fhlog,fitpar.fixed,this.model.startPoint);
            coeff = fitpar.start;
            jacobian = zeros(length(y),length(this.model.startPoint));
            
            % perform the fit
            try
                [coeff(~fitpar.fixed),resnorm,residuals,~,~,~,jacobian(:,~fitpar.fixed)] = ...
                                                                           lsqcurvefit(fhnonfixed ,...
                                                                           this.model.startPoint(~fitpar.fixed),...
                                                                           x,log10(y),...
                                                                           this.model.minValue(~fitpar.fixed),...
                                                                           this.model.maxValue(~fitpar.fixed),...
                                                                           opts);
            catch ME
                disp(ME)
                coeff = this.model.startPoint;
                resnorm = Inf;
                residuals = Inf;
                jacobian = zeros(length(this.model.startPoint));
            end

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
            this.model.bestValue = coeff; %get the relaxation rate
            this.model.errorBar = coeffError;
            this.model.gof = gof;
%             self.errorBar = coeffError; %get the model error on the relaxation rate
%             % Gather the result and store it in the corresponding submodel
            this = updateSubModel(this);
        end
        
        
    end
    
end