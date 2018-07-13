classdef ParamV1 < ParamObj
    
    properties
          % See ParamObj properties 
    end
    
    methods
        % parameter can be a structure or a cell array of structure. If a
        % cell array of structure is detected then PARAMV1 creates an array
        % of ParamV1 object.
        function self = ParamV1(parameter)
            % check input
            if nargin == 0
                return
            end
            
            % check if array of struct
            if ~iscell(parameter)
                % struct
                self.paramList = parameter;                           
            else
                % array of struct            
                [self(1:length(parameter)).paramList] = deal(parameter{:});                      
            end   
        end %ParamV1
            
        % GETZONEAXIS(SELF) generates the inversion time values based on
        % the parameters in paramList. 
        % The input can not be an array of object, instead call GETZONEAXIS
        % with the following syntax:
        % invtime = arrayfun(@(x) getZoneAxis(x), self, 'UniformOutput', 0);
        function invtime = getZoneAxis(self)
            % check input
            if length(self) > 1
                error('GetZoneAxis:InputSize',['It seems that the input is'...
                    ' an array of object. Use the following syntax instead: '...
                    'arrayfun(@(x) getZoneAxis(x), self, ''UniformOutput'', 0);'])
            end
            % get parameters
            BGRD = self.paramList.BGRD;
            T1MX = self.paramList.T1MX; %#ok<NASGU>
            NBLK = self.paramList.NBLK;
            % depending on the format generate the inversion time values           
            switch BGRD
                case 'LIST'
                    blst = regexp(parameters.BLST,'[;:]','split'); %split the field BLST
                    Ti = eval(blst{1}); %time start vector
                    Te = eval(blst{2}); %time end vector   
                    if strcmp(blst{3},'LOG')
                       invtime = logspace(log10(Ti),log10(Te),NBLK); %create all the time vectors
                    else %'LIN'
                       invtime = linspace(Ti,Te,NBLK); %create all the time vectors
                    end                
                case 'LOG'
                    Ti = eval(parameters.BINI);
                    Te = eval(parameters.BEND);
                    invtime = logspace(log10(Ti),log10(Te),NBLK); %create all the time vectors
                case 'LIN'
                    Ti = eval(parameters.BINI);
                    Te = eval(parameters.BEND);
                    invtime = linspace(Ti,Te,NBLK); %create all the time vectors
                otherwise
                    error('getZoneAxis:MissingParameters',['BGRD parameter'...
                        'seems absent from the parameter structure'])
            end %switch
        end
        
        % GETDISPAXIS(SELF) get the magnetic fields
        % The input can not be an array of object, instead call GETDISPAXIS
        % with the following syntax:
        % brlx = arrayfun(@(x) getDispAxis(x), self, 'UniformOutput', 0);
        function BRLX = getDispAxis(self)
            % check input
            if length(self) > 1
                error('GetDispAxis:InputSize',['It seems that the input is'...
                    ' an array of object. Use the following syntax instead: '...
                    'arrayfun(@(x) getDispAxis(x), self, ''UniformOutput'', 0);'])
            else
                BRLX = self.paramList.BRLX;
            end
        end
%         function x = getZoneAxis(self)
%             T1MAX = self.paramList.T1MX;
%             % extract the info from the TAU field
%             ind = strfind(self.paramList.TAU,':');
%             algo = self.paramList.TAU(2:ind(1)-1);
%             xstart = self.paramList.TAU(ind(1)+1:ind(2)-1);
%             xend = self.paramList.TAU(ind(2)+1:ind(3)-1);
%             npts = str2double(self.paramList.TAU(ind(3)+1:end-1));
%             % make the array
%             x = zeros(npts,length(T1MAX));
%             switch algo
%                 case 'lin'
%                     for ind = 1:length(T1MAX)
%                         xstartnum = eval(replace(xstart,'T1MAX',num2str(T1MAX(ind))));
%                         xendnum = eval(replace(xend,'T1MAX',num2str(T1MAX(ind))));
%                         x(:,ind) = linspace(xstartnum,xendnum,npts);
%                     end
%                 case 'log'
%                     for ind = 1:length(T1MAX)
%                         xstartnum = eval(strrep(xstart,'T1MAX',num2str(T1MAX(ind))));
%                         xendnum = eval(strrep(xend,'T1MAX',num2str(T1MAX(ind))));
%                         x(:,ind) = logspace(log10(xstartnum),log10(xendnum),npts);
%                     end
%                 otherwise
%                     error(['Type of acquisition not known (' algo ').'])
%             end
%             % make sure the dimensions are consistent (tau, nT2, BRLX)
%             x = reshape(x,size(x,1),1,size(x,2));
%         end
%         
%         function x = getDispAxis(self)
%             x = self.paramList.BRLX;
%         end
        
    end
    
end