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
        % quite ugly, but this works.
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
            str = '@(x,c) ';
%             for i = 1:length(varName)
%                 str = [str, varName{i} ];
%             end
%             for indc = 1:length(self)
%                 contribName = ['cont' num2str(indc) '_'];
%                 for i = 1:length(self(indc).parameterName)
%                     parName{end+1} = [contribName self(indc).parameterName{i}];
%                     str = [str ',' parName{end}]; %#ok<*AGROW>
%                 end
%             end
%             str = [str 'self(1).modelHandle(x'];
%             for i = 2:length(varName)
%                 str = [str ',' varName{i}];
%             end
%             for i = 1:length(self(1).parameterName)
%                 str = [str ',c(' num2str(i) ')'];
%             end
%             str = [str ')'];
            indpar = 0;
            for indc = 1:length(self)
%                 contribName = ['cont' num2str(indc) '_'];
                if indc > 1
                    str = [str ' + '];
                end
                str= [str 'self(' num2str(indc) ').modelHandle(x'];
%                 for i = 2:length(varName)
%                     str = [str ',' varName{i}];
%                 end
                for i = 1:length(self(indc).parameterName)
                    indpar = indpar+1;
                    str = [str ',c(' num2str(indpar) ')'];
                end
                str = [str ')'];
            end

            % make the function handle with all variables and parameters:
            fh = eval(str);  % cannot use str2func because of indexing. Grrrr....
            lowVal = [self.minValue];
            highVal = [self.maxValue];
            startVal = [self.startPoint];
            fixedVal = [self.isFixed];
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
            fitpar = struct;
            if length(self)>1
                [fitpar.fh,fitpar.var,fitpar.par,fitpar.low,fitpar.high,fitpar.start,fitpar.fixed] = addModels(self);
            else
                fitpar.fh = self.modelHandle;
                fitpar.var = self.variableName;
                fitpar.par = self.parameterName;
                fitpar.low = self.minValue;
                fitpar.high = self.maxValue;
                fitpar.start = self.startPoint;
                fitpar.fixed = self.isFixed;
            end
            
            % apply the model to the object in the log space
            dispindex = num2cell(1:length(disp),1);
            [y, dy, params] = cellfun(@(x,y,i) process(self,x,y,fitpar,i),{disp.x},{disp.y},dispindex,'Uniform',0);
                        
            % Gather the result and store it in the corresponding
            % contribution
            
            
        end
        
        % perform the fit from the sum of all contributions on one of the
        % Disp objects
        function [z,dz,params] = process(self,x,y,fitpar,index)
            
            
            
            fhlog = makeLogFunction(self,fitpar.fh);
            opts = statset('nlinfit');
            opts.Robust = 'on'; 
            [coeff,residuals,~,cov,MSE] = nlinfit(x,squeeze(y)',fhlog,fitpar.start,opts); %non-linear least squares fit


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