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
        
    end
    
end