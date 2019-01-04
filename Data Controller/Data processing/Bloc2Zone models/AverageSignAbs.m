classdef AverageSignAbs < Bloc2Zone
    
    properties
        functionName@char = 'Average of signed magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Abs'};         % tag appearing in the legend of data derived from this object
    end
        
    methods

        % this is where you should put the algorithm that processes the raw
        % data. Multi-component algorithms can store several results along
        % a single dimension (z and dz are column arrays).
        % NOTE: additional info from the process can be stored in the
        % structure paramFun
        function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL
            s = mean(real(y));
            z = s.*mean(abs(y));
            dz = std(abs(y));
            paramFun.test = index;
        end
    end
end


