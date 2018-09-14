classdef Zone < DataUnit
    %
    % ZONE is a container for "zone" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
       
    properties 
        % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        % Zone can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Zone(varargin)
            obj = obj@DataUnit(varargin{:});
        end %Zone
        
        function x = getDispAxis(self)
            x = arrayfun(@(x) getDispAxis(x.parameter),self,'UniformOutput',0);
        end
        
        % merge two datasets together
        function selfMerged = merge(self)
            n = ndims(self(1).x); % always concatenate over the last dimension (evolution fields), the others should have the same number of inputs
            selfMerged = copy(self(1));
            selfMerged.x = cat(n,self(1).x, self(2).x);
            selfMerged.y = cat(n,self(1).y, self(2).y);
            selfMerged.dy = cat(n,self(1).dy, self(2).dy);
            selfMerged.mask = cat(n,self(1).mask, self(2).mask);
            selfMerged.parameter = merge(self(1).parameter,self(2).parameter);
            if length(self) > 2
                selfMerged = merge([selfMerged self(3:end)]);
            end
        end
        
                
        % evaluate the fit function if present, for display purposes
        function y = evaluate(self,zoneIndex,x)
            model = self.parameter.paramList.modelHandle{zoneIndex};
            y = model(self.parameter.paramList.coeff(zoneIndex,:), x);
        end
    end % methods
    
end