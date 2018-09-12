classdef Bloc < DataUnit
    %
    % BLOC is a container for "bloc" data from Stelar SPINMASTER
    %
    % Data (X,Y) must be organized as BS x NBLK x nBRLX
    % where BS: bloc size (number of acquired points)
    %     NBLK: number of bloc 
    %    nBRLX: number of magnetic fields
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
    
    properties 
        % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        function obj = Bloc(varargin)
            obj = obj@DataUnit(varargin{:});
        end %Bloc
        
        function x = getZoneAxis(self)
            x = arrayfun(@(x) getZoneAxis(x.parameter),self,'UniformOutput',0);
        end
    end
    
end

