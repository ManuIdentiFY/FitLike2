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
        
        % Data processing: process that allows to obtain "zone" y-data
        % In this case Zone container is created and the bloc container is
        % stored in "parent" field of zone.
        % PROCESS(OBJ, VARARGIN) need different inputs:
        % 'Method': structure containing the options for processing
        %          method.bound: [min max]
        %          method.phc0: {'first','all'}
        %          method.mode: {'real','abs'}
        % 'Parameters': structure of Stelar parameters 
        % 'Idx' (optional): index of the Bloc to process (if array of struct)
        function obj = process(obj,varargin)
            % check input size
            if size(obj.y,1) < 2 
                return
            end
            % call bloc2zone to get the y-data
            
            % if condition in function of the file version: possible
            % statement could be the obj.x size (if equal to the obj.y size
            % it is version 2) 
            % version 1: need Stelar parameters
            % version 2: just mean the time series (obj.x)
            
        end %process
        
        % Data visualisation: plot()
        function h = plot(obj, idx)
            
        end %plot
    end
    
end

