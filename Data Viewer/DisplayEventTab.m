classdef DisplayEventTab < event.EventData
    %
    % Allow to define event for display manager tab
    %
    
    properties
        Data
    end
    
    methods
        function data = DisplayEventTab(varargin)
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            
            % struct
            for ind = 1:2:nargin
                data.(varargin{ind}) = varargin{ind+1};                         
            end 
         end
    end
    
end

