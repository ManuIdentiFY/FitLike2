function [relaxRate,relaxRateError,model] = monoexp(x,y,T1MAX)
%MONOEXP Compute the 1-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constant of the equation y = f(x) with its error as well as the model used.
%   Input: x: time specified as a vector [single|double|integer]
%          y: y-values specified as a vector [single|double|integer]
%          T1MAX: Stelar parameter specified as a scalar [single|double|integer]

%   Output: relaxRate: relaxation rate specified as a scalar 
%           relaxRateError: relaxation rate error specified as a scalar
%           model: structure containing the model i/o information

%   The structure 'model' contains 6 fields:
%       name: 'monoexp'
%       modelEquation: '(M0-Minf)*exp(-t*R1)+Minf'
%       parameterName: {'M0','Minf','R1'}
%       coeff: vector of coefficients estimated from the model
%       coeffError: vector of error estimated from the model (define as 95% of the
%           confidence interval)
%       gof: structure containing the rsquare, adjrsquare and the root
%           mean square error of the fit
%% Parameter
LIMIT_RELAX = [0.02 1.7]; % in s
% Corresponds to the hardware limit 
%% Exponential fit
fitModel = @(c, x)((c(1)-c(2))*exp(-x*c(3))+c(2)); %exponential model


% y = y(x>LIMIT_RELAX(1) & x<LIMIT_RELAX(2));
% x = x(x>LIMIT_RELAX(1) & x<LIMIT_RELAX(2));
%     
% figure()
% plot(x,y)


opts = statset('nlinfit');
opts.Robust = 'on';

startPoint = [y(1),y(end),1/T1MAX]; 
[coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit

% try
%     disp('OK')
% +gof
%     sst = sum((y-mean(y)).^2); %sum of square total
%     sse = sum(residuals.^2); %sum of square error
%     rsquare =  1 - sse/sst; 
%     if rsquare < 0.7
%         idx = find(sign(diff(y)) ~= sign(diff(y(1:2))),1,'first'); %find the idx in the case of IR
%         y(idx:end) = -y(idx:end);
%         startPoint = [y(1),y(end),1/T1MAX]; 
%         [coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit
%         sst = sum((y-mean(y)).^2); %sum of square total
%         sse = sum(residuals.^2); %sum of square error
%         rsquare2 =  1 - sse/sst;  
%         if rsquare2 < rsquare
%             disp('PROBLEMMMM')
%         end
%     end
%     
% catch
%     disp('BOF')
%     idx = find(sign(diff(y)) ~= sign(diff(y(1:2))),1,'first'); %find the idx in the case of IR
%     y(idx:end) = -y(idx:end);
%     startPoint = [y(1),y(end),1/T1MAX]; 
%     [coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint,opts); %non-linear least squares fit
% end


% +plot
% figure()
% plot(x,y)
% hold on
% plot(linspace(x(1),x(end),100),fitModel(coeff,linspace(x(1),x(end),100)));
% hold off

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
relaxRate = coeff(3); %get the relaxation rate
relaxRateError = coeffError(3); %get the model error on the relaxation rate
%% Model structure
model.name = 'monoexp';
model.modelEquation = '(M_0-M_inf)*exp(-t*R_1)+M_inf';
model.parameterName = {'M_0','M_inf','R_1'};
model.coeff = coeff;
model.coeffError = coeffError;
model.gof = gof;
end



