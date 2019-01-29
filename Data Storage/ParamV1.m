classdef ParamV1 < ParamObj
    
    properties
          % See ParamObj properties 
    end
    
    methods
        % parameter can be a structure or a cell array of structure. If a
        % cell array of structure is detected then PARAMV1 creates an array
        % of ParamV1 object.
        function this = ParamV1(varargin)
            % call superclass constructor
            this@ParamObj(varargin{:});
            % change some fieldnames
            changeFieldName(this,'ZONE','BR')
        end %ParamV1
            
        % GETZONEAXIS(SELF) generates the inversion time values based on
        % the parameters in paramList. 
        % The input can not be an array of object, instead call GETZONEAXIS
        % with the following syntax:
        % invtime = arrayfun(@(x) getZoneAxis(x), self, 'UniformOutput', 0);
        function invtime = getZoneAxis(this)
            % check input
            if length(this) > 1
                error('GetZoneAxis:InputSize',['It seems that the input is'...
                    ' an array of object. Use the following syntax instead: '...
                    'arrayfun(@(x) getZoneAxis(x), self, ''UniformOutput'', 0);'])
            end
            % get parameters
            BGRD = this.paramList.BGRD;
            T1MX = this.paramList.T1MX; %#ok<NASGU>
            NBLK = this.paramList.NBLK;
            % depending on the format generate the inversion time values           
            switch BGRD
                case 'LIST'
                    blst = regexp(this.paramList.BLST,'[;:]','split'); %split the field BLST
                    Ti = eval(blst{1}); %time start vector
                    Te = eval(blst{2}); %time end vector   
                    [Ti,Te] = checkOutputSz(Ti, Te);
                    if strcmp(blst{3},'LOG')
                       invtime = arrayfun(@(ti,te)logspace(log10(ti),log10(te),NBLK),Ti,Te,'UniformOutput',0); %create all the time vectors
                    else %'LIN'
                       invtime = arrayfun(@(ti,te)linspace(ti,te,NBLK),Ti,Te,'UniformOutput',0); %create all the time vectors
                    end                
                case 'LOG'
                    Ti = eval(this.paramList.BINI);
                    Te = eval(this.paramList.BEND);
                    [Ti,Te] = checkOutputSz(Ti, Te);
                    invtime = arrayfun(@(ti,te)logspace(log10(ti),log10(te),NBLK),Ti,Te,'UniformOutput',0); %create all the time vectors
                case 'LIN'
                    Ti = eval(this.paramList.BINI);
                    Te = eval(this.paramList.BEND);
                    [Ti,Te] = checkOutputSz(Ti, Te);
                    invtime = arrayfun(@(ti,te)linspace(ti,te,NBLK),Ti,Te,'UniformOutput',0); %create all the time vectors
                otherwise
                    error('getZoneAxis:MissingParameters',['BGRD parameter'...
                        'seems absent from the parameter structure'])
            end %switch
            invtime = cell2mat(invtime')';
                                   
            function [Ti,Te] = checkOutputSz(Ti, Te)
                % check if one of the input is not the same size as the
                % other. Repeat element if needed
                ni = numel(Ti);
                ne = numel(Te);
                if ni ~= ne && ni == 1
                    Ti = repelem(Ti, ne);
                elseif ni ~= ne && ne == 1
                    Te = repelem(Te, ni);
                end
            end %checkOutputSz
        end %getZoneAxis
                
    end
    
end