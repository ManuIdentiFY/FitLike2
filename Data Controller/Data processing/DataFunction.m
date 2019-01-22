classdef DataFunction < DataModel
    %DATAFUNCTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        modelFunction;    % function_handle type, but cannot declare this type here (it causes problemes with derived classes)
    end
    
    methods
        function this = DataFunction()
            %DATAFUNCTION Construct an instance of this class
            %   Detailed explanation goes here
            this@DataModel;
        end
        
        function [z,dz,paramFun] = process(this,x,y,dataObj,index) %#ok<*INUSD,*INUSL>
            out = this.modelFunction(x,y,dataObj.mask);
            z = out(1);
            dz = out(2);
            paramFun.test = index;
        end
        
    end
end
