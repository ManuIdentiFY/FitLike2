classdef DataModel < matlab.mixin.Heterogeneous
    %MODEL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
    end
    
    methods
        function obj = DataModel(inputArg1,inputArg2)
            %MODEL Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
               
        
    end
end

