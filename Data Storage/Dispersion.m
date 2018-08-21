classdef Dispersion < DataUnit
    %
    % DISPERSION is a container for "dispersion" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DATAUNIT, DISPERSIONMODEL
    
    properties
        displayName = 'dispersion';
        model = [];  % DispersionModel object that sums up all the contributions from the sub-model list
        subModel = [] % cell array of DispersionModel object
        filter = [] % cell array of Filter object
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
                    end
                end
            end   

            % generate mask if missing
            resetmask(obj);
            % generate fileID
            generateID(obj);                            
        end %Dispersion
    end
    
    methods (Access = public)        
%         % Merge several Dispersion object.
%         function selfMerged = merge(self)
%             selfMerged = copy(self(1));
%             selfMerged.x = [self(1).x(:); self(2).x(:)];
%             selfMerged.y = [self(1).y(:); self(2).y(:)];
%             selfMerged.dy = [self(1).dy(:); self(2).dy(:)];
%             selfMerged.mask = [self(1).mask(:); self(2).mask(:)];
%             selfMerged.parameter = merge(self(1).parameter,self(2).parameter);
%             if length(self) > 2
%                 selfMerged = merge([selfMerged self(3:end)]);
%             end
%         end
        
        % Average several Dispersion object data (X, Y) and create a new
        % Dispersion object
        function self = average(self)
            
        end %average
        
        % Export data from Dispersion object in text file.
        function export(obj,method)
            
        end %export
        
        % plotting function - needs to be improved
        function plot(obj,varargin)
            for ind1 = 1:size(obj.y,1)
                for ind2 = 1:size(obj.y,2)
                    loglog(obj.x,squeeze(obj.y(ind1,ind2,:)),varargin{:})
                    hold on
                end
            end
            hold off
        end
    end
    
end