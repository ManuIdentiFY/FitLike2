classdef Bloc2Bloc < DataUnit2DataUnit
    % Bloc2Bloc can be used to generate filters of merging operation on
    % bloc objects before they are processed in the pipeline.
    % LB 01/02/19
    
    properties
        InputChildClass@char  = 'Bloc';
        OutputChildClass@char = 'Bloc';
    end
   
    methods
        function this = Bloc2Bloc
            % call superclass constructor
            this@DataUnit2DataUnit;
            % redefine the input/output class object
            this.InputChildClass  = 'Bloc';
            this.OutputChildClass = 'Bloc';
        end

    end

        
end



