classdef EventFile < event.EventData
   properties
      OldName
      NewName
   end
   
   methods
      function data = EventFile(OldName, NewName)
         data.OldName = OldName;
         data.NewName = NewName;
      end
   end
end

