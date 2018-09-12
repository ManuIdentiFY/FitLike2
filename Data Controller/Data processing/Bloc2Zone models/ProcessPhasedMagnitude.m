classdef ProcessPhasedMagnitude < Bloc2Zone
    
    properties
        functionName@char = 'Average of rephased signal';
        labelY@char = 'Average signal (A.U.)'; 
        labelX@char = 'Evolution time (s)';  
        legendTag@cell = {'AbsRephased'}; 
    end
        
    methods
        function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL>
            % getting the phase of the signal
%             [~,ord] = sort(x);
%             y = y(ord);
            
            % re-phasing the entire signal would be equivalent to taking
            % the magnitude, and would generate a Rician noise. To avoid
            % this we filter the phase to remove the contribution of the
            % noise, supposing that phase variations from the signal have a
            % slow frequency
%             a = 1/10;
%             phi = filter(a, [1 a-1], phi);
            
            yzone = squeeze(bloc.y(:,:,index(2)));
            phi = unwrap(angle(yzone));
%             yzonem = mean(yzone,2);
%             mask = abs(yzonem)>(max(abs(yzonem))/2);
%             dphi = diff(phi(mask,:))./repmat(diff(x(mask)),1,size(yzone,2));
%             a = median(dphi);
%             b = median(phi(mask,:)-x(mask)*a);
%             b = b - b(1);
            b = phi(4,:);
            b = b - b(1);
            
            % Rician filtering
            
            
            if abs(b(index(1)))>pi/2
                z = mean(abs(y));
            else
                z = -mean(abs(y));
            end
            dz = 0;
            % need to initialise the parameter object to avoid problems
            paramFun.test = index;
        end
    end
end
