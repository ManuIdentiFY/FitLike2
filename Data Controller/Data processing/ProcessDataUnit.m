classdef ProcessDataUnit < matlab.mixin.Heterogeneous% < handle
% this class defines the structure and general attibute of all the objects
% that are used to process the data units. It aims at facilitating
% operations on the processing functions, to streamline the creation of
% new models and to make it easier to make new models for begginers.
%
% L Broche, University of Aberdeen, 6/7/18

    properties (Abstract)
        functionName@char       % character string, name of the model, as appearing in the figure legend
        labelY@char             % string, labels the Y-axis data in graphs
        labelX@char             % string, labels the X-axis data in graphs
        legendTag@cell          % cell of strings, contain the legend associated with the data processed
    end
    
    properties
        parameter@struct        % structure containing parameters associated with the process (weighted, robust fit, log,...)
    end
    
    methods
        function self = ProcessDataUnit(varargin)
            % parsing the inputs, using the typical format ('param1',
            % value1, 'param2', value2,...)
            for i = 1:2:length(varargin)
                if isprop(model,varargin{i})
                    model = setfield(model,varargin{i},varargin{i+1}); %#ok<SFLD>
                end
            end
            % make some simple checks
            if ~selfCheck(self)
                error('Inconsistent inputs, object not created.')
            end
        end
        
        % test function to verify the object integrity (TO DO)
        function out = selfCheck(self)
            out = 1;
        end
    
        % main process function
        function [childObj, parentObj] = processData(this, parentObj)
            
            % get data
            data = getProcessData(this, parentObj);
            
            % apply process
            [model, new_data] = arrayfun(@(d) applyProcess(this, d), data, 'Uniform', 0);
            
            % format output
            new_data = formatData(this, new_data);
            this = formatModel(this, model);
                        
            % assign process in parentObj (to test, Manu)
            parentObj.processingMethod = this;
            
            % gather data and create childObj
            childObj = makeProcessData(this, new_data, parentObj);     
            
            % add other data (xLabel, yLabel,...)
            childObj = addOtherProp(this, childObj);
        end %processData
        
        % format output data from process: cell array to array of structure
        % This function could also be used to modify this in order to
        % gather all fit data for instance [Manu]
        function this = formatModel(this, model)
            
        end %formatData
        
        % compare two process to determine if they are the same. This
        % function only check the necessary fields:
        % *class of the processObj (AverageAbs, Monoexp, Constant,...)
        % *property parameters (if parameters are the same, the results
        % will be the same)
        function tf = isequal(this, processObj)
            % dummy check
            if ~isa(processObj, 'ProcessDataUnit')
                tf = 0; return
            end
            % compare the class of the input and their parameters
            if ~strcmp(class(this), class(processObj)) ||...
                    ~isequal(this.parameter, processObj.parameter)
                tf = 0;
            else
                tf = 1;
            end
        end %isequal
        
        % add other properties (xLabel, yLabel, legendTag
        function childObj = addOtherProp(this, childObj)
            % add xLabel and yLabel
            [childObj.xLabel] = deal(this.labelX);
            [childObj.yLabel] = deal(this.labelY);
            
            % add legendTag
            [childObj.legendTag] = this.legendTag{:};
        end %addOtherProp
    end
    
    methods (Abstract)
        applyProcess(this, data, parentObj)
    end
    
    % set/get methods
%     methods
%         function this = set.parameter(this, val)
%             oldProp = this.parameter;
%             this.parameter = val;
%             this = update(this, val);
%         end %set.parameters
%     end
end