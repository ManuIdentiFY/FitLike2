classdef Bloc2Disp < DataUnit2DataUnit
    
    properties
        InputChildClass@char = 'Bloc';
        OutputChildClass@char = 'Disp';
    end
   
    methods
        function this = Bloc2Disp
            this@DataUnit2DataUnit;
        end

    end
end