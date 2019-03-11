classdef DispersionModel < DataUnit2DataUnit & DataFit
    % Default model class used to make the sum of other models
    
    properties 
        InputChildClass@char; 	% defined in DataUnit2DataUnit
        OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end 
    
    properties
        valueToReturn = []; % no value to returned after dispersion fit (no childObj created)
    end
    
    methods
        function this = DispersionModel
            % call superclass constructor
            this = this@DataUnit2DataUnit;
            this = this@DataFit;
            % redefine input/output class
            this.InputChildClass  = 'Dispersion';
            this.OutputChildClass = 'Experiment';
        end
        
        % list the name of input parameters
        function list = listInputNames(this)
             eq= func2str(this.modelHandle);
             indp = strfind(eq,')');
             indv = strfind(eq,',');
             indv = indv(indv<indp(1));
             list = arrayfun(@(indstart,indend) eq(indstart:indend),[3 indv+1],[indv-1,indp(1)-1],'UniformOutput',0);             
        end
    end
end