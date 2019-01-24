classdef AverageAbs < Bloc2Zone & ProcessDataUnit
    
    properties
        functionName@char = 'Average of magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Abs'};         % tag appearing in the legend of data derived from this object

%         modelFunction = @(x,y,mask) mean(abs(y)) ;          % value provided to the Zone
%         errorFunction = @(x,y,mask) std(abs(y));        % estimation of the error


    end
        
    methods
        % Constructor
        function this = AverageAbs()
            % call both superclass constructor
            this = this@Bloc2Zone;
            this = this@ProcessDataUnit;
            % set the ForceDataCat flag to true. Allow to get all the 3D
            % bloc matrix.
            % Warning: output data should be formated as:
            % new_data.x = NBLK x BRLX matrix
            % new_data.y = NBLK x BRLX matrix
            % ...
            %
            this.ForceDataCat = true;
        end % AverageAbs
    end
    
    methods
        % Define abstract method applyProcess(). See ProcessDataUnit.
        function [this, new_data] = applyProcess(this, data)
            % get data size
            [~, NBLK, BRLX] = size(data.y);
            % get absolute y-values and replace unwanted values by nan (masked).
            y = abs(data.y);
            y((y == data.mask)) = nan;
            
            % apply absolute average on the first dimension and avoid nan
            % values. Reshape to get NBLK x BRLX matrix
            new_data.y = reshape(mean(y,1,'omitnan'),[NBLK, BRLX]);
            new_data.dy = reshape(std(y,[],1,'omitnan'),[NBLK, BRLX]);          
        end %applyProcess
% 
%         % this is where you should put the algorithm that processes the raw
%         % data. Multi-component algorithms can store several results along
%         % a single dimension (z and dz are column arrays).
%         % NOTE: additional info from the process can be stored in the
%         % structure paramFun
%         function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL>
%             z = mean(abs(y));
%             dz = std(abs(y));
%             paramFun.test = index;
%         end
    end
end
