classdef ProcessPhasedMagnitude < Bloc2Zone
    
    properties
        functionName@char = 'Average of rephased signal';
        labelY@char = 'Average signal (A.U.)'; 
        labelX@char = 'Evolution time (s)';  
        legendTag@cell = {'Average rephased'}; 
    end
        
    methods
        function [z,dz,paramFun] = process(self,x,y,paramObj,index) %#ok<*INUSD,*INUSL>
            % getting the phase of the signal
            [~,ord] = sort(x);
            y = y(ord);
            phi = angle(y);
            % re-phasing the entire signal would be equivalent to taking
            % the magnitude, and would generate a Rician noise. To avoid
            % this we filter the phase to remove the contribution of the
            % noise, supposing that phase variations from the signal have a
            % slow frequency
            a = 1/10;
            phi = filter(a, [1 a-1], phi);
            z = mean(real(y.*exp(-1i*phi)));
            dz = 0;
            % need to initialisethe parameter object to avoid problems
            paramFun.test = index;
        end
    end
end
