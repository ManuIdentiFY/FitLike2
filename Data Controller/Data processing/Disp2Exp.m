classdef Disp2Exp < ProcessDataUnit
    
    % this class performs the fit over the dispersion data. Several
    % contributions can be added together by using an array of object, each
    % one containing a different component.
    % Performing the fit is done using the function applyProcessFunction,
    % then the result can be used to generate an Experiment object if
    % required (using makeExp).
    
    properties
%         functionHandle % function handle that points to the processing function. 
                       % By default, it is the 'process' function within this object 
                       % but this may be modified by the user to use a custom-made 
                       % processing function.
        modelName = '';        % character string, name of the model, as appearing in the figure legend
        modelEquation = '';    % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        modelHandle;           % function handle that refers to the equation, or to any other function defined by the user
        variableName = {};     % List of characters, name of the variables appearing in the equation
        parameterName = {};    % List of characters, name of the parameters appearing in the equation
        isFixed = [];          % List of array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit. 
        minValue = [];         % array of values, minimum values reachable for each parameter, respective to the order of parameterName
        maxValue = [];         % array of values, maximum values reachable for each parameter, respective to the order of parameterName
        startPoint = [];       % array of values, starting point for each parameter, respective to the order of parameterName 
        bestValue = [];        % array of values, estimated value found from the fit.
        errorBar = [];         % 2 x n array of values, provide the 95% confidence interval on the estimated fit values (lower and upper errors)
        fitobj = [];           % fitting object created after the model is used for fitting.
                       
    end
    
    methods
        
        function self = Disp2Exp(varargin)
            self@ProcessDataUnit;
        end
                
        function self = makeFunctionHandle(self)
            % build the string expression
            str = '@(';
            for i = 1:length(self.variableName)
                str = [str, self.variableName{i} ]; %#ok<AGROW>
            end
            
            for i = 1:length(self.parameterName)
                str = [str ',' self.parameterName{i}]; %#ok<AGROW>
            end
            str = [str ') ' self.modelEquation];
            % make the function handle with all variables and parameters:
            self.modelHandle = str2func(str);
            % check for element-wise operators
            % TO DO (find ^ without preceding dots, replace by .^, same for others such as / or *)
        end        
        
        % provide a function handle that is the sum of all the function
        % handles in the array of objects
        function [fh,varName,parName,lowVal,highVal,startVal,fixedVal] = addModels(self)
            
            varName = self(1).variableName;
            % check that the number of vars is the same for all the
            % models
            varsize = arrayfun(@(x) size(x.variableName),self,'UniformOutput',0);
            if ~isequal(varsize{:})
                error('The models selected do not have the same number of input variables.')
            end
            
            % collect all the parameters
            parName = {};
            str = '@(';
            for i = 1:length(varName)
                str = [str, varName{i} ];
            end
            for indc = 1:length(self)
                contribName = ['cont' num2str(indc) '_'];
                for i = 1:length(self(indc).parameterName)
                    parName{end+1} = [contribName self(indc).parameterName{i}];
                    str = [str ',' parName{end}]; %#ok<*AGROW>
                end
            end
            str = [str ') self(1).modelHandle(' varName{1}];
            for i = 2:length(varName)
                str = [str ',' varName{i}];
            end
            for i = 1:length(self(1).parameterName)
                str = [str ',cont1_' self(1).parameterName{i}];
            end
            str = [str ')'];

            for indc = 2:length(self)
                contribName = ['cont' num2str(indc) '_'];
                str = [str ' + self(' num2str(indc) ').modelHandle(' varName{1}];
                for i = 2:length(varName)
                    str = [str ',' varName{i}];
                end
                for i = 1:length(self(indc).parameterName)
                    str = [str ',' contribName self(indc).parameterName{i}];
                end
                str = [str ')'];
            end

            % make the function handle with all variables and parameters:
            fh = eval(str);  % cannot use str2func because of indexing. Grrrr....
            lowVal,highVal,startVal,fixedVal
        end
        
        % sets a function handle into the log space
        % fhlog = log10(fh)
        function fhlog = makeLogFunction(self,fh)
            par = functions(fh);
            ind = strfind(par.function,')');
            inputList = par.function(3:ind(1)-1);
            fhlog = eval(['@(' inputList ') log10(fh(' inputList '))']); % str2func won't work here...
        end
        
        % TO DO
        function exp = makeExp(self,disp)
            % generate the x-axis for the experiments (needs user input)
            
            % perform the fits (if needs be)
            
            % make the Exp object
            
        end
        
        % function that applies the processing function over the different
        % dispersion objects
        function [y,dy,params] = applyProcessFunction(self,disp)
            % Add the models together
            if length(self)>1
                [fh,var,par,low,high,start,fixed] = addModels(self);
                
            else
                fh = self.modelHandle;
                var = self.variableName;
                par = self.parameterName;
                low = self.minValue;
                high = self.maxValue;
                start = self.startPoint;
                fixed = self.isFixed;
            end
            
            % apply the model to the object in the log space
            
            
            % Gather the result and store it in the corresponding
            % contribution
            
        end
        
        function [z,dz,params] = process(self,x,y,paramObj,index)
            
            
            
            fhlog = makeLogFunction(self,fh);
            
            
            T1MX = paramObj.T1MX(index);
            
            LIMIT_RELAX = [0.02 1.7]; % in s, Corresponds to the hardware limit 
            % Exponential fit
            fitModel = @(c, x)((c(1)-c(2))*exp(-x*c(3))+c(2)); %exponential model

            opts = statset('nlinfit');
            opts.Robust = 'on';

            startPoint = [y(1),y(end),1/T1MX]; 
            [coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit


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
            paramFun.coeffError =
        end
        
        
    end
    
end