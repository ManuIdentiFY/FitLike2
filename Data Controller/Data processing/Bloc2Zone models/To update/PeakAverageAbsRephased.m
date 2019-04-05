classdef PeakAverageAbsRephased < Bloc2Zone & ProcessDataUnit
    
    properties
        InputChildClass@char; 	% defined in DataUnit2DataUnit
        OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'Average FFT peak magnitude rephased';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'AbsFFT AverageRephased'};         % tag appearing in the legend of data derived from this object
    end
       
    methods
        % Constructor
        function this = PeakAverageAbsRephased
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
        end % PeakAverageAbsRephased
    end
    
    methods
        % TO DO
        % Define abstract method applyProcess(). See ProcessDataUnit.
        function [model, new_data] = applyProcess(this, data)

            % dummy
            model = [];
        end %applyProcess
        
%         
%         % this is where you should put the algorithm that processes the raw
%         % data. Multi-component algorithms can store several results along
%         % a single dimension (z and dz are column arrays).
%         % NOTE: additional info from the process can be stored in the
%         % structure paramFun
%         function [z,dz,paramFun] = process(self,x,y,bloc,index) %#ok<*INUSD,*INUSL>
%             Y = fftshift(abs(fft(y)));
%             [~,indPeak] = max(Y);
%             z = median(abs(Y(indPeak-50:indPeak+50)));
%             
%             % estimation of the phase (using the entire zone)
%             if index(1)==1
%                 sigPh = median(angle(squeeze(bloc.y(4:10,:,index(2)))));
%                 [~,indexJump] = max(abs(diff(sigPh))); % find where the phase changes using the first 10 points or so
%                 ph = (1:size(bloc.y,2))<=indexJump;
%                 bloc.parameter.paramList.phasingArray(:,index(2)) = ph;
%             else
%                 ph = bloc.parameter.paramList.phasingArray(:,index(2));
%             end
%             if ~ph(index(1))
%                 z = -z;
%             end
%             
%             dz = 0;
%             paramFun.test = index;
%         end
    end
end
