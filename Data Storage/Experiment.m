classdef Experiment < DataUnit
    % this class describes the results of a series of measurements of
    % dispersion curves. It may contain data such as dispersion slopes,
    % quadrupolar peaks amplitude, etc... across a variety of samples. This
    % class is what needs to be created to facilitate data export for
    % further statistical analyses.
    
    properties
        
    end
    
    methods
        function obj = Experiment(varargin)
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
        end
        
        
        function plot(self)
            
        end
        
        % Data export
        
        
        % Basic stats
        
    end
    
end