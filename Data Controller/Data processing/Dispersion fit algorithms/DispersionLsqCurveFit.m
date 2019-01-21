classdef DispersionLsqCurveFit < Disp2Exp
    
    properties
        functionName@char = 'Least square fit';  % character string, name of the model, as appearing in the figure legend
        labelY@char = 'fit result';              % string, labels the Y-axis data in graphs
        labelX@char = 'Experimental parameter';  % string, labels the X-axis data in graphs
        legendTag@cell = {'Data tag'};             % cell of strings, contain the legend associated with the data processed
    end
    
    methods
        % Constructor
        function this = DispersionLsqCurveFit(varargin)
            this@Disp2Exp(varargin{:});
        end
    end
    
    methods 
        function this = process(this, dispersion, index)
            % apply the model to the object in the log space
            fhlog = makeLogFunction(this);
            
            % prepare the fit parameter structure
%             fitpar.fixed = this.model.isFixed;
%             fitpar.fh = this.model.modelHandle;
%             fitpar.var = this.model.variableName;
%             fitpar.low = this.model.minValue;
%             fitpar.high = this.model.maxValue;
%             fitpar.start = this.model.startPoint;

            % set the optimisation options
            opts = optimoptions('lsqcurvefit',...
                'TypicalX',this.model.startPoint(~this.model.isFixed),...
                'Display','off',...
                'MaxFunEvals',1e4);
            
%             opts.Robust = 'on'; 
%             opts.MaxFunEvals = 1e4;
%             opts.TypicalX = this.model.startPoint(~this.model.isFixed);
%             opts.Display = 'off';
            
            % get data
            x = dispersion.x(dispersion.mask);
            y = dispersion.y(dispersion.mask);
            
            % deal with fixed parameters and initialise the coefficients
            fhnonfixed = this.setFixedParameter(fhlog,...
                            this.model.isFixed, this.model.startPoint);
            coeff = this.model.startPoint;

            % perform the fit
            try
                [coeff(~this.model.isFixed),resnorm,residuals,~,~,~,jacobian(:,~this.model.isFixed)] = ...
                                                                           lsqcurvefit(fhnonfixed ,...
                                                                           this.model.startPoint(~this.model.isFixed),...
                                                                           x,log10(y),...
                                                                           this.model.minValue(~this.model.isFixed),...
                                                                           this.model.maxValue(~this.model.isFixed),...
                                                                           opts);
            catch ME
                disp(ME)
                coeff = this.model.startPoint;
                resnorm = Inf;
                residuals = Inf;
                jacobian = zeros(length(y),length(this.model.startPoint));
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