classdef Zone2Disp < DataUnit2DataUnit
        
    properties
        InputChildClass@char = 'Zone';
        OutputChildClass@char = 'Dispersion';
    end
  
    methods
        % Constructor
        function this = Zone2Disp
            this@DataUnit2DataUnit;
        end
                
    end

end



