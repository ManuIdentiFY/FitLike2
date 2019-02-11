classdef AverageSignAbs < Bloc2Zone & ProcessDataUnit
    
    properties
        InputChildClass@char; 	% defined in DataUnit2DataUnit
        OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'Average of signed magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'SignAbs'};         % tag appearing in the legend of data derived from this object
        
    end
        
    methods
        % Constructor
        function this = AverageSignAbs
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
        function [model, new_data] = applyProcess(this, data, ~)
            % get data size
            [~, NBLK, BRLX] = size(data.y);
            % get absolute y-values and replace unwanted values by nan (masked).
            y = data.y;
            y((y == data.mask)) = nan;
            
            % apply absolute average on the first dimension and avoid nan
            % values. Reshape to get NBLK x BRLX matrix
            s = sign(mean(real(y),1,'omitnan')); % get sign of real part
            
            new_data.y = reshape(s.*mean(abs(y),1,'omitnan'),[NBLK, BRLX]);
            new_data.dy = reshape(std(abs(y),[],1,'omitnan'),[NBLK, BRLX]);
            
            
            % dummy
            model = [];
        end %applyProcess
        
    end
end


