classdef PeakAverageAbsRephased < Bloc2Zone
    
    properties
        functionName@char = 'FFT peak magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Average magnitude'};         % tag appearing in the legend of data derived from this object
    end
        
    methods

        % this is where you should put the algorithm that processes the raw
        % data. Multi-component algorithms can store several results along
        % a single dimension (z and dz are column arrays).
        % NOTE: additional info from the process can be stored in the
        % structure paramFun
        function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL>
            Y = fftshift(abs(fft(y)));
            [~,indPeak] = max(Y);
            z = median(abs(Y(indPeak-50:indPeak+50)));
            
            % estimation of the phase (using the entire zone)
            if index(1)==1
                sigPh = median(angle(squeeze(bloc.y(4:10,:,index(2)))));
                [~,indexJump] = max(abs(diff(sigPh))); % find where the phase changes using the first 10 points or so
                ph = (1:size(bloc.y,2))<=indexJump;
                bloc.parameter.paramList.phasingArray(:,index(2)) = ph;
            else
                ph = bloc.parameter.paramList.phasingArray(:,index(2));
            end
            if ~ph(index(1))
                z = -z;
            end
            
            dz = 0;
            paramFun.test = index;
        end
    end
end
