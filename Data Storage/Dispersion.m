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
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end

            % check if array of struct
            if ~iscell(varargin{2})
                % struct
                for ind = 1:2:nargin
                    try 
                        obj.(varargin{ind}) = varargin{ind+1};
                    catch ME
                        error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                    end                           
                end  
                % add listeners
                addlistener(obj,{'dataset','sequence','filename','displayName'},...
                    'PostSet',@(src, event) generateID(obj));
                % dispersion
                obj.displayName = 'dispersion'; 
            else
                % array of struct
                % check for cell sizes
                n = length(varargin{2});
                if ~all(cellfun(@length,varargin(2:2:end)) == n)
                    error('Size input is not consistent for array of struct.')
                else
                    % initialise explicitely the array of object (required
                    % for heterogeneous array)
                    % for loop required to create unique handle.
                    for k = n:-1:1
                        % initialisation required to create unique handle!
                        obj(1,k) = Dispersion();
                        % fill arguments
                        for ind = 1:2:nargin 
                            [obj(k).(varargin{ind})] = varargin{ind+1}{k};                          
                        end
                        % add listeners
                        addlistener(obj(k),{'dataset','sequence','filename','displayName'},...
                            'PostSet',@(src, event) generateID(obj(k)));
                        % add dispersion
                        obj(k).displayName = 'dispersion';
                    end
                end
            end   

            % generate mask if missing
            resetmask(obj);
            % generate fileID
            generateID(obj);                            
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