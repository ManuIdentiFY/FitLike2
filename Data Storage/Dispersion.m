classdef Dispersion < DataUnit
    %
    % DISPERSION is a container for "dispersion" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DATAUNIT, DISPERSIONMODEL
    
    properties
%         model = [];  % DispersionModel object that sums up all the contributions from the sub-model list
%         subModel = [] % cell array of DispersionModel object
        % See DataUnit for other properties
    end
    
    methods (Access = public)  
        % Constructor
        % Dispersion can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Dispersion(varargin)
            obj = obj@DataUnit(varargin{:});                    
        end %Dispersion
    end
    
    methods       
       
        % Average several Dispersion object data (X, Y) and create a new
        % Dispersion object
        % TODO: This should be a disp2disp object 
        function self = average(self)
            
        end %average
        
        
        % assign a processing function to the data object (over rides the
        % metaclass function to add initial parameter estimation when
        % loading the processing object)
        function self = assignProcessingFunction(self,processObj)
            % assign the process object to each dataset
            self = arrayfun(@(s)setfield(s,'processingMethod',processObj),self,'UniformOutput',0); %#ok<*SFLD>
            self = [self{:}];
            % then evaluate the initial parameters if a method is provided
            self = arrayfun(@(s)evaluateStartPoint(s.processingMethod,s.x,s.y),self,'UniformOutput',0); %#ok<*SFLD>
            self = [self{:}];
        end
        
        % TODO: Export data from Dispersion object in text file.
        function export(obj,method)
            
        end %export
        
        % plotting function - needs to be improved
        function loglog(obj,varargin)
            clf
            for ind = 1:length(obj)
                [x,ord] = sort(obj(ind).x);
                y = obj(ind).y(ord);
                loglog(x,y,varargin{:})
                hold on
                if isempty(obj(ind).processingMethod)
                    continue
                end
                for indfit = 1:length(obj(ind).processingMethod)
                    if isempty(obj(ind).processingMethod(indfit).model.bestValue)
                        continue
                    else
                        loglog(x,evaluate(obj(ind).processingMethod(indfit).model,x),varargin{:})
                    end
                end
            end
            hold off
        end
    end
    
end