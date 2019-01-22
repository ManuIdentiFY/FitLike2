classdef LsqCurveFit < FitAlgorithm
    
    properties
        name = 'lsqcurvefit';
        weightMethod = 'none' % one of the following weight method:
                              % - 'none'
                              % - 'data': use the data error w = 1./(dy.^2)
                              % - {'andrews','bisquare','cauchy','fair',...
                              %    'huber','logistic','ols','talwar','welsch'}
    end

    methods
        % Constructor
        function this = LsqCurveFit
            % call superclass constructor
            this@FitAlgorithm
            % create default options
            this.options = optimoptions(@lsqcurvefit);
            % add default weight options
            this.options.Weight = this.weightMethod;
        end
    end
    
    methods 
        function [coeff, error, gof] = applyFit(this, fun, xdata, ydata, dydata, x0, lb, ub)
            % try/catch structure
            try
                % check the weight options
                switch this.options.Weight
                    case 'none'
                        % apply fit 
                        [coeff,resnorm,residuals,~,~,~,jacobian] = lsqcurvefit(fun,...
                            x0, xdata, ydata, lb, ub, this.options);
                    case 'data'
                        % apply fit with 1./(dydata.^2) weight
                        [coeff,resnorm,residuals,~,~,~,jacobian] = lsqnonlin(@wfun,...
                            x0, ub, lb, this.options, xdata, ydata, 1./(dydata.^2)); 
                    otherwise
                        % apply robust fit
                        [coeff,resnorm,residuals,~,~,~,jacobian] = robustlsqcurvefit(fun,...
                            x0, xdata, ydata,lb, ub,...
                            this.options.Weight, this.options);
                end           
            catch
                coeff = x0;
                error = nan(size(x0));
                gof = struct('sse',[],'rsquare',[],'adjrsquare',[],'RMSE',[]);
                return
            end
            
            % get gof and error
            gof = getGOF(coeff, ydata, residual, resnorm);

            ci = nlparci(coeff,residuals,'jacobian',jacobian);
            error = coeff' - ci(:,1);
            
            %%% ----------------- Weight calculation ------------------ %%%
            function err = wfun(coeff, xdata, ydata, weight)
                % get error
                err = weight.*(fun(coeff, xdata) - ydata);
            end
        end
        
        % Calculate the goodness of fit: rsquare, adjrsquare, RMSE, SSE
        function gof = getGOF(coeff, ydata, residual, resnorm)
            % calculate the sum of square total and error
            sst = sum((ydata-mean(ydata)).^2); %sum of square total
            sse = sum(residual.^2); %sum of square error
            nData = length(ydata); 
            nCoeff = length(coeff); 
            % build the output struct with rsquare, adjrsquare and RMSE
            gof.sse = sse;
            gof.rsquare =  1 - sse/sst; 
            gof.adjrsquare = 1 - ((nData-1)/(nData - nCoeff))*(sse/sst); 
            gof.RMSE = sqrt(resnorm);
        end %getGOF        
    end
    
    % Set methods
    methods
        % Possible weight method:
        % - 'none'
        % - 'data': use the data error w = 1./(dy.^2)
        % - {'andrews','bisquare','cauchy','fair',...
        %    'huber','logistic','ols','talwar','welsch'} from robustfit
        function this = set.weightMethod(this, val)
            % check the input
            if any(strcmp({'none','data','andrews','bisquare','cauchy','fair',...
                    'huber','logistic','ols','talwar','welsch'}, val))
                % update the field and the associated option struct
                this.weightMethod = val;
                this.options.Weight = val;
            else
                error('WeightMethod: Unknown weight method')
            end
        end %weightMethod
    end   
end