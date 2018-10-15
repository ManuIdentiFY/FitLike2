classdef PeakAverageAbs < Bloc2Zone
    
    properties
        functionName@char = 'Average FFT peak magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'AbsFFT Average'};         % tag appearing in the legend of data derived from this object
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
            z = mean(Y(indPeak-50:indPeak+50));
            dz = 0;
            paramFun.test = index;
        end
    end
end
