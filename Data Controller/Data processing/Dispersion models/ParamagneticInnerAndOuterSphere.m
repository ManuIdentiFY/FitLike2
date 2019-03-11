classdef ParamagneticInnerAndOuterSphere < DispersionModel
    % Model for paramagnetic species (SBM+ Hwang&Freed)
    % Coded by Lionel Broche, equation from Simona Baroni

    properties
        modelName     = 'Paramagnetic species, inner and outer spheres';  % character string, name of the model as appearing in the figure legend or elsewhere. You may use spaces here.
        modelEquation = 'ParamagneticInnerAndOuterSphere.model(f,s,delta,tv,tr,tm,r,n,a,D,acc)';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s.^{-1})
        variableName  = {'f'};          % List of characters, name of the variables appearing in the equation (usually the frequency). Only one-D support for now, but it may change in the future...
        parameterName = {'s','delta',  'tv',   'tr',   'tm',    'r',  'n',     'a',   'D', 'acc'};     % List of characters, name of the parameters appearing in the equation in any order, but the order defined here is the same as for the boundary arrays below
        minValue      = [0      0     1e-12   1e-12   1e-12   1e-10     0    1e-10      0     0]      % array of values, minimum boundary for each parameter, respective to the order of parameterName
        maxValue      = [10    10      1e-3    1e-3    1e-3  20e-10   Inf   20e-10    Inf   Inf ]      % array of values, maximum boundary for each parameter, respective to the order of parameterName
        startPoint    = [3.5    5    15e-12  53e-12  220e-9   3e-10     1    4e-10   2e-5     1];      % array of values, starting point for each parameter, respective to the order of parameterName 
        isFixed       = [1      0         0       0       0       0     0        0      0     0];      % array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
        % All parameters should be in IU (second, metre, etc)
        % s: spin number (half-integer)
        % delta: 
        % tv:
        % tr: rotational correlation time
        % tm: mean residence lifetime
        % r: 
        % n: number of metal-bound water molecules
        % a:
        % D: 
        % acc:
        visualisationFunction@cell = {};
    end

    methods
        function this = ParamagneticInnerAndOuterSphere
            % call superclass constructor
            this = this@DispersionModel;
        end
    end
    
    methods (Static)
       
        function R1 = model(freq,s, delta,tv,tr,tm,r,q,a,D,acc)
            wi=6.28e6.*freq;
            ws=658.21.*wi;
            T1e=((0.04.*(4.*s.^2+4.*s-3).*tv.*delta.*((1./(1+(ws.^2.*tv.^2)))+(4./(1+(4.*ws.^2.*tv.^2)))))).^(-1);
            T2e=((0.02.*(4.*s.^2+4.*s-3).*tv.*delta.*(3+(5./(1+(ws.^2.*tv.^2)))+(2./(1+(4.*ws.^2.*tv.^2)))))).^(-1);
            tc1=(T1e.^(-1)+tr.^(-1)+tm.^(-1)).^(-1);
            tc2=(T2e.^(-1)+tr.^(-1)+tm.^(-1)).^(-1); 
            te2=(T2e.^(-1)+tm.^(-1)).^(-1);
            cost1=2.4677894e-31.*s.*(s+1);
            cost2=(cost1./r.^6).*(2./15);
            R1dip=(cost2.*((7.*tc2./(1+ws.^2.*tc2.^2))+(3.*tc1./(1+wi.^2.*tc1.^2))));
            R1sc=((2./3).*(s.^2+s).*(6.28.*acc).^2.*(te2./(1+ws.^2.*te2.^2)));
            T1m=(R1dip+R1sc).^-1;
            C=1e-3;
            r1in=(q.*C./55.6)./(T1m+tm);
            tau=a.^2./D;
            roi=tau.*sqrt(wi.^2+(1./T1e).^2);
            fi=atan(wi.*T1e);
            ai=1+(1./4).*sqrt(roi).*cos(fi./2);
            bi=(1./4).*sqrt(roi).*sin(fi./2);
            ci=1+sqrt(roi).*cos(fi./2)+(4./9).*roi.*cos(fi)+(1./9).*roi.^(3./2).*cos((3./2).*fi);
            ei=sqrt(roi).*sin(fi./2)+(4./9).*roi.*sin(fi)+(1./9).*roi.^(3./2).*sin((3./2).*fi);
            ji=(ai.*ci+bi.*ei)./(ci.^2+ei.^2);
            ros=tau.*sqrt(ws.^2+(1./T1e).^2);
            fs=atan(ws.*T1e);
            as=1+(1./4).*sqrt(ros).*cos(fs./2);
            bs=(1./4).*sqrt(ros).*sin(fs./2);
            cs=1+sqrt(ros).*cos(fs./2)+(4./9).*ros.*cos(fs)+(1./9).*ros.^(3./2).*cos((3./2).*fs);
            es=sqrt(ros).*sin(fs./2)+(4./9).*ros.*sin(fs)+(1./9).*ros.^(3./2).*sin((3./2).*fs);
            js=(as.*cs+bs.*es)./(cs.^2+es.^2);
            cost3=3.6858264e-11.*s.*(s+1);
            r1os=cost3.*(C./(a.*D)).*((3.*ji)+(7.*js));
            R1=r1in+r1os;
            
        end 
    end
    
    % additional methods are available if one wants to fine-tune the model.
    % These are available in the section 'methods' but can be safely
    % deleted if unnecessary.
    methods
        function this = evaluateStartPoint(this,xdata,ydata)

        end
        
        % If you want to create an object with the fit result you can use
        % this function to decide which coefficients will become y-values
        % (idem for dy-values).
        function data = formatFitData(this, model)
            % Example:
            %data.y =  [model.bestValue(3), model.bestValue(5)];
            %data.dy = [model.errorBar(3),  model.errorBar(5)];
        end %formatFitData
    end

end % end of the class (do not delete)