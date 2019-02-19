classdef EventMessage < event.EventData
   properties
      txt
   end
   
   methods
      function event = EventMessage(varargin)
         % check input, must be non empty and have always field/val
         % couple
         if nargin == 0 || mod(nargin,2)
             % default value
             return
         end
                           
         % fill the structure
         for ind = 1:2:nargin
             event.(varargin{ind}) = varargin{ind+1};
         end
      end %EventMessage
   end
end


