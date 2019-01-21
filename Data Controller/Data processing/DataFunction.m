classdef DataFunction < DataModel
    %DATAFUNCTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = DataFunction(inputArg1,inputArg2)
            %DATAFUNCTION Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
    end
end

