classdef Zone2Zone < DataUnit2DataUnit
    % Bloc2Bloc can be used to generate filters of merging operation on
    % bloc objects before they are processed in the pipeline.
    % LB 01/02/19
    
    properties
        InputChildClass@char  = 'Zone';
        OutputChildClass@char = 'Zone';
    end
   
    methods
        function this = Zone2Zone
            % call superclass constructor
            this@DataUnit2DataUnit;
            % redefine the input/output class object
            this.InputChildClass  = 'Zone';
            this.OutputChildClass = 'Zone';
        end

    end

        
end



