classdef ProcessDataUnit < matlab.mixin.Heterogeneous
% this class defines the structure and general attibute of all the objects
% that are used to process the data units. It aims at facilitating
% operations on the processing functions, to streamline the creation of
% new models and to make it easier to make new models for begginers.
%
% L Broche, University of Aberdeen, 6/7/18

    properties
        functionName@char       % character string, name of the model, as appearing in the figure legend
        labelY@char             % string, labels the Y-axis data in graphs
        labelX@char             % string, labels the X-axis data in graphs
        legendTag@cell          % cell of strings, contain the legend associated with the data processed
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
        
%         function [newData, dataObj] = processData(self,dataObj)
%             newData = dataObj;
%         end
                
    end
    
%     methods (Abstract)
%         
%         [newData, dataObj] = processData(self,dataObj)
%         
%     end
    
end