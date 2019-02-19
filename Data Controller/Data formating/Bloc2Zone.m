classdef Bloc2Zone < DataUnit2DataUnit
    
    properties

    end
   
    methods
        function this = Bloc2Zone
            % call superclass constructor
            this@DataUnit2DataUnit;
            % redefine the input/output class object
            this.InputChildClass  = 'Bloc';
            this.OutputChildClass = 'Zone';
        end

    end

        
end



