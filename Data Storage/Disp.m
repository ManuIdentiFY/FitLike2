classdef Disp < DataUnit
    %
    % ZONE is a container for "zone" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
       
    properties (Access = public)
            method = []% method use to get zone data from bloc parent
            parent = []% allow to define a "bloc" parent
            % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        % Zone can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Disp(varargin)
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            
            % check if array of struct
            if ~iscell(varargin{2})
                % struct
                for ind = 1:2:nargin
                    try 
                        obj.(varargin{ind}) = varargin{ind+1};
                    catch ME
                        error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                    end                           
                end   
            else
                % array of struct
                % check for cell sizes
                if ~all(cellfun(@length,varargin(2:2:end)) == length(varargin{2}))
                    error('Size input is not consistent for array of struct.')
                else
                    for ind = 1:2:nargin                  
                        try 
                            [obj(1:length(varargin{ind+1})).(varargin{ind})] = deal(varargin{ind+1}{:});
                        catch ME
                            error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                        end                           
                    end
                end
            end      
            obj = resetmask(obj);
        end %Zone
        
        % Data processing: process that allows to obtain "dispersion" data.
        % In this case Disp container is created and the zone container is
        % stored in "parent" field of dispersion.
        function obj = process(obj,varargin)
            
        end %process
        
        % Data visualisation: plot()
        function h = plot(obj, idx)
           errorbar(squeeze(obj.x),squeeze(obj.y),squeeze(obj.dy))  % MUST BE CHANGED
           
        end %plot
    end
    
end