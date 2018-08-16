classdef DefaultDispersionModel < DispersionModel
    % Default model class used to make the sum of other models
    
    properties
        modelName = 'Sum of models';        
        modelEquation = 'x';    
        variableName = {'x'};     
        parameterName = {'param'};  
        minValue =       [-Inf];  
        maxValue =       [Inf];  
        startPoint =     [1];  
        isFixed =        [0];
    end
    
    methods
        function model = DefaultDispersionModel
            model@DispersionModel;
            % generate the function handle (do not remove)
%             model = makeFunctionHandle(model);
        end
    end
end