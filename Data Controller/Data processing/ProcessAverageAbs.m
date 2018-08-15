classdef ProcessAverageAbs < Bloc2Zone
        
    methods
        function self = ProcessAverageAbs
            self@Bloc2Zone;   
            
            self.functionName = 'Average of magnitude';     % character string, name of the model, as appearing in the figure legend
            self.labelY = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
            self.labelX = 'Evolution time (s)';             % string, labels the X-axis data in graphs
            self.legendTag = {'Average magnitude'};           % tag appearing in the legend of data derived from this object
        end

        % this is where you should put the algorithm that processes the raw
        % data. Multi-component algorithms can store several results along
        % a single dimension (z and dz are column arrays).
        % NOTE: additional info from the process can be stored in the
        % structure paramFun
        function [z,dz,paramFun] = process(self,x,y,paramObj,index) %#ok<*INUSD,*INUSL>
            z = mean(abs(y));
            dz = 0;
            paramFun.test = index;
        end
    end
end
