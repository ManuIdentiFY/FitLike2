classdef Disp2Exp < ProcessDataUnit
    
    properties
        functionHandle % function handle that points to the processing function. 
                       % By default, it is the 'process' function within this object 
                       % but this may be modified by the user to use a custom-made 
                       % processing function.
        componentList  % cell array containing the list of models that have been
                       % added up to make this object. Empty if it is an
                       % original model.
                       
    end
    
    methods
        
        function self = Disp2Exp(varargin)
            self@ProcessDataUnit;
            self.functionHandle = @self.process;
        end
        
        function exp = makeExp(self,disp)
            
        end
        
        % add two Disp2Exp objects to make another one. This allows adding
        % fitting functions together.
        function newself = add(self,other)
            newself = Disp2Exp;
            newself.componentList = {self,other};
        end
        
        
        % function that applies the processing function to one disp only.
        % This is where the custom processing function is being called.
        function [y,dy,params] = applyProcessFunction(self,disp)
            
        end
        
        function [z,dz,params] = process(self,x,y,paramObj,index)
            
        end
        
        
    end
    
end