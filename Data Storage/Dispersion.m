classdef Dispersion < DataUnit
    %
    % DISPERSION is a container for "dispersion" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
    
    properties
        parent = [] % allow to define a "zone" parent
        model = [] % allow to add dispersion models
        method = [] % method use to get dispersion data from zone parent
        mergeFlag@logical = false % flag for merged files
        averageFlag@logical = false %flag for averaged files
        % See DataUnit for other properties
    end
    
    methods
        % Constructor
        % Dispersion can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Dispersion(varargin)
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
            resetmask(obj);       
        end %Dispersion
        
        % Data processing: process that allows to apply model on data
        function obj = process(obj,varargin)           
        end %process
        
        % Data formating
        function obj = merge(obj,idx) 
        end %merge
        
        % Data processing
        function obj = average(obj,idx)
        end %average
        
        % Data processing
        function obj = normalise(obj,idx)
        end %normalise
        
        % Data processing
        function obj = sgolayy(obj,idx)
        end %sgolayy
        
        % Data processing
        function obj = smoothh(obj,idx)
        end %smoothh
        
        % Data exporting: export
        function export(obj,method)
        end %export
        
        % Data visualisation: plot()
        function h = plot(obj, idx)
            
        end %plot
    end
    
end