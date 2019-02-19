classdef Zone2Disp < DataUnit2DataUnit
        
    properties
    end
  
    methods
        % Constructor
        function this = Zone2Disp
            % call superclass constructor
            this@DataUnit2DataUnit;
            % redefine the input/output class object
            this.InputChildClass  = 'Zone';
            this.OutputChildClass = 'Dispersion';
        end
                
    end

end



