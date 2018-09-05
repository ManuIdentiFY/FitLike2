classdef Zone < DataUnit
    %
    % ZONE is a container for "zone" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
       
    properties 
        % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        % Zone can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Zone(varargin)
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
                % zone
                obj.displayName = 'zone';
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
                        obj(1,k) = Zone();
                        % fill arguments
                        for ind = 1:2:nargin 
                            [obj(k).(varargin{ind})] = varargin{ind+1}{k};                          
                        end
                        % add zone
                        obj(k).displayName = 'zone';
                    end
                end
            end   

            % generate mask if missing
            resetmask(obj);
            % generate fileID
            generateID(obj);
        end %Zone
        
        function x = getDispAxis(self)
            x = arrayfun(@(x) getDispAxis(x.parameter),self,'UniformOutput',0);
        end
        
        % merge two datasets together
        function selfMerged = merge(self)
            n = ndims(self(1).x); % always concatenate over the last dimension (evolution fields), the others should have the same number of inputs
            selfMerged = copy(self(1));
            selfMerged.x = cat(n,self(1).x, self(2).x);
            selfMerged.y = cat(n,self(1).y, self(2).y);
            selfMerged.dy = cat(n,self(1).dy, self(2).dy);
            selfMerged.mask = cat(n,self(1).mask, self(2).mask);
            selfMerged.parameter = merge(self(1).parameter,self(2).parameter);
            if length(self) > 2
                selfMerged = merge([selfMerged self(3:end)]);
            end
        end
    end % methods
    
end