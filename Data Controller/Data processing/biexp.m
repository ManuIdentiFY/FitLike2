function [relaxRate,relaxRateError,model] = biexp(x,y,T1MX)
%BIEXP Compute the 2-exponential decay model. The function is based on a
%non-linear regression using iterative least-squares estimation and returned the
%time constants of the equation y = f(x) with their errors as well as the model used.
%   Input: -x: time specified as a vector [single|double|integer]
%          -y: y-values specified as a vector [single|double|integer]
%          -T1MAX: Stelar parameter specified as a scalar [single|double|integer]

%   Output: -relaxRate: relaxation rates specified as a scalar 
%           -relaxRateError: relaxation rate errors specified as a scalar
%           -model: structure containing the model i/o information

%   The structure 'model' contains 6 fields:
%       - name: 'biexp'
%       - modelEquation: 'a1*exp(-t*R1)+ a2*exp(-t*R2)+b'
%       - parameterName: {'a1','R1','a2','R2','b'}
%       - coeff: vector of coefficients estimated from the model
%       - coeffError: vector of error estimated from the model (define as 95% of the
%       confidence interval)
%       - gof: structure containing the rsquare, adjrsquare and the root
%       mean square error of the fit

%% Exponential fit
fitModel = @(c, x)(c(1)*exp(-x*c(2))+c(3)*exp(-x*c(4))+c(5)); %bi-exponential model
startPoint = [(y(1)-y(end))*3/4, 0.2/T1MX,(y(1)-y(end))/4, 1.2/T1MX, y(end)]; 

[coeff,residuals,~,cov,MSE] = nlinfit(x,y,fitModel,startPoint); %non-linear least squares fit
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
relaxRate = [coeff(2); coeff(4)]; %get the relaxation rates
relaxRateError = [coeffError(2); coeffError(4)]; %get the model errors on the relaxation rates
%% Model structure
model.name = 'biexp';
model.modelEquation = 'a1*exp(-t*R1)+ a2*exp(-t*R2)+b';
model.parameterName = {'a1','R1','a2','R2','b'};
model.coeff = coeff;
model.coeffError = coeffError;
model.gof = gof;
end


