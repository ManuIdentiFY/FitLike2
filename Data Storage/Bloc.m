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
        function this = Bloc(varargin)
            % call superclass constructor
            this = this@DataUnit(varargin{:});
            % set xLabel and yLabel
            [this.xLabel] = deal('Time');
            [this.yLabel] = deal('Signal');
        end %Bloc
    end
    
    methods (Access = public)
        % get the inversion time (x-values for zone(s) axis)
        function x = getZoneAxis(this)
            x = arrayfun(@(x) getZoneAxis(x.parameter),this,'UniformOutput',0);
        end
        
        % define dimension indexing for data selection. If idxZone is a NaN
        % all the data are collected.
        function dim = getDim(this, idxZone)
            % check input
            if isnan(idxZone)
                dim = {1:size(this.y,1), 1:size(this.y,2), 1:size(this.y,3)};
            else
                dim = {1:size(this.y,1), 1:size(this.y,2), idxZone};
            end
        end %getDim
    end
    
end

