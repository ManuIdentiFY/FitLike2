classdef Disp2Disp < DataUnit2DataUnit
    % Bloc2Bloc can be used to generate filters of merging operation on
    % bloc objects before they are processed in the pipeline.
    % LB 01/02/19
    
    properties
        InputChildClass@char  = 'Dispersion';
        OutputChildClass@char = 'Dispersion';
    end
   
    methods
        function this = Disp2Disp
            % call superclass constructor
            this@DataUnit2DataUnit;
            % redefine the input/output class object
            this.InputChildClass  = 'Dispersion';
            this.OutputChildClass = 'Dispersion';
        end

    end

        
end



