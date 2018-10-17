classdef ParamV2 < ParamObj
    
    properties
        
        
    end
    
    methods
        function self = ParamV2(varargin)
            self@ParamObj(varargin{:});
        end
            
        function x = getZoneAxis(self)
            T1MAX = self.paramList.T1MX;
            % extract the info from the TAU field
            ind = strfind(self.paramList.TAU,':');
            algo = self.paramList.TAU(2:ind(1)-1);
            xstart = self.paramList.TAU(ind(1)+1:ind(2)-1);
            xend = self.paramList.TAU(ind(2)+1:ind(3)-1);
            npts = str2double(self.paramList.TAU(ind(3)+1:end-1));
            % make the array
            x = zeros(npts,length(T1MAX));
            switch algo
                case 'lin'
                    for ind = 1:length(T1MAX)
                        xstartnum = eval(replace(xstart,'T1MAX',num2str(T1MAX(ind))));
                        xendnum = eval(replace(xend,'T1MAX',num2str(T1MAX(ind))));
                        x(:,ind) = linspace(xstartnum,xendnum,npts);
                    end
                case 'log'
                    for ind = 1:length(T1MAX)
                        xstartnum = eval(strrep(xstart,'T1MAX',num2str(T1MAX(ind))));
                        xendnum = eval(strrep(xend,'T1MAX',num2str(T1MAX(ind))));
                        x(:,ind) = logspace(log10(xstartnum),log10(xendnum),npts);
                    end
                otherwise
                    error(['Type of acquisition not known (' algo ').'])
            end
            % make sure the dimensions are consistent (tau, nT2, BRLX)
            x = reshape(x,size(x,1),size(x,2));
        end
        
        % find the parameters that have been used to select multiple values
        % for looped experimentation, when not using the profile wizard.
        function [parName,parValue] = findExtendedParameter(self)
            parName = {};
            parValue = {};
            parList = fieldnames(self.paramList);
            for i=1:length(parList)
                if isequal(self.paramList.(parList{i})(1),'[')
                    parName = [parName parList{i}];
                    parValue = [parValue self.paramList.(parList{i})];
                end
            end
        end
    end
    
end