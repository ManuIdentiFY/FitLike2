classdef TreeEventData < event.EventData
   properties
      Action
      Parent
      Data
   end
   
   methods
      function data = TreeEventData(varargin)
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

