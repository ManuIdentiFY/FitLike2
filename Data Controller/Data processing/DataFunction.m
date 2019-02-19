classdef DataFunction < DataModel
    %DATAFUNCTION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract)
        modelFunction;    % function_handle type, but cannot declare this type here (it causes problemes with derived classes)
        errorFunction;
    end
    
    methods
        function this = DataFunction()
            %DATAFUNCTION Construct an instance of this class
            %   Detailed explanation goes here
            this@DataModel;
        end
        
        function [z,dz,paramFun] = process(this,x,y,dataObj,index) %#ok<*INUSD,*INUSL>
            z = this.modelFunction(x,y,dataObj.mask);
            dz = this.errorFunction(x,y,dataObj.mask);
            paramFun.test = index;
        end
        
        function n = numberOfInputs(this)
            n = nargin(this.modelFunction);
        end
            
        function n = numberOfOutputs(this)
            n = nargout(this.modelFunction);
        end
        
    end
end

