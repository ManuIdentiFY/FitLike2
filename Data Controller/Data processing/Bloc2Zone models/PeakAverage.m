classdef PeakAverage < Bloc2Zone & ProcessDataUnit
    
    properties
        functionName@char = 'FFT peak magnitude';     % character string, name of the model, as appearing in the figure legend
        labelY@char = 'Average magnitude (A.U.)';       % string, labels the Y-axis data in graphs
        labelX@char = 'Evolution time (s)';             % string, labels the X-axis data in graphs
        legendTag@cell = {'AbsFFT'};         % tag appearing in the legend of data derived from this object
    end
    
    methods
        % Constructor
        function this = PeakAverage
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
        % Important: this implementation do not take in account the mask
        % since NaN values are not accepted by fft(). Custom implementation
        % of the fft() need to be done or interpolation step need to be
        % prior the fft call.
        % Define abstract method applyProcess(). See ProcessDataUnit.
        function [model, new_data] = applyProcess(this, data)
            % apply FFT on first dimension (BS)
            Y = fftshift(fft(data.y,[],1));
            [~,indPeak] = max(abs(Y),[],1); % get max for each bloc
            
            % Could be vectorized [Manu]
            for k = size(Y,3):-1:1
                for j = size(Y,2):-1:1
                    Yp = Y(indPeak(1,j,k)-20:indPeak(1,j,k)+20,j,k);
                    th = median(mod(angle(Yp),pi));
                    Y(:,j,k) = Y(:,j,k).*exp(-1i*th);
                    
                    Yp = Y(indPeak(1,j,k)-50:indPeak(1,j,k)+50,j,k);
                    new_data.z(j,k) = mean(imag(Yp)) + 1i*mean(imag(Yp));
                    new_data.dz(j,k) = 0;
                end
            end
            
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
%             Y = fftshift(fft(y));
%             [~,indPeak] = max(abs(Y));
%             th = median(mod(angle(Y(indPeak-20:indPeak+20)),pi));
%             Y = Y*exp(-1i*th);
%             z = mean(imag(Y(indPeak-50:indPeak+50))) + 1i*mean(imag(Y(indPeak-50:indPeak+50)));
%             dz = 0;
%             paramFun.test = index;
%         end
    end
end
