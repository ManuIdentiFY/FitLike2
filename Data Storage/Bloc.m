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
        % See DataUnit for properties
    end
    
    methods (Access = public)
        % Constructor
        function obj = Bloc(varargin)
            % call DataUnit constructor
            obj = obj@DataUnit(varargin{:}); 
        end %Bloc
        
        % Data visualisation: plot()
        function h = plot(obj, idx)
            2;
        end %plot
    end
    
end

