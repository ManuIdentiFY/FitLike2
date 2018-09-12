classdef Bloc < DataUnit
    %
    % BLOC is a container for "bloc" data from Stelar SPINMASTER
    %
    % Data (X,Y) must be organized as BS x NBLK x nBRLX
    % where BS: bloc size (number of acquired points)
    %     NBLK: number of bloc 
    %    nBRLX: number of magnetic fields
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
    
    properties 
        % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        function obj = Bloc(varargin)
            obj = obj@DataUnit(varargin{:});
%             % check input, must be non empty and have always field/val
%             % couple
%             if nargin == 0 || mod(nargin,2) 
%                 % default value
%                 return
%             end
% 
%             % check if array of struct
%             if ~iscell(varargin{2})
%                 % struct
%                 for ind = 1:2:nargin
%                     obj.(varargin{ind}) = varargin{ind+1};                       
%                 end   
%                 % add listeners
%                 addlistener(obj,{'dataset','sequence','filename','displayName'},...
%                     'PostSet',@(src, event) generateID(obj));
%                 % add bloc
%                 obj.displayName = 'bloc';
%             else
%                 % array of struct
%                 % check for cell sizes
%                 n = length(varargin{2});
%                 if ~all(cellfun(@length,varargin(2:2:end)) == n)
%                     error('Size input is not consistent for array of struct.')
%                 else
%                     % initialise explicitely the array of object (required
%                     % for heterogeneous array)
%                     % for loop required to create unique handle.
%                     for k = n:-1:1
%                         % initialisation required to create unique handle!
%                         obj(1,k) = Bloc();
%                         % fill arguments
%                         for ind = 1:2:nargin 
%                             [obj(k).(varargin{ind})] = varargin{ind+1}{k};                          
%                         end
%                         % add listeners
%                         addlistener(obj(k),{'dataset','sequence','filename','displayName'},...
%                             'PostSet',@(src, event) generateID(obj(k)));
%                         % add bloc
%                         obj(k).displayName = 'bloc';
%                     end
%                 end
%             end   
% 
%             % generate mask if missing
%             resetmask(obj);
            % generate fileID
            %generateID(obj);
            
            % add listeners
            if length(varargin)<2 
                addlistener(obj,{'dataset','sequence','filename','displayName'},...
                    'PostSet',@(src, event) generateID(obj));
            elseif ~iscell(varargin{2})
                addlistener(obj,{'dataset','sequence','filename','displayName'},...
                    'PostSet',@(src, event) generateID(obj));
            else
                for k = length(varargin{2}):-1:1
                    addlistener(obj(k),{'dataset','sequence','filename','displayName'},...
                        'PostSet',@(src, event) generateID(obj(k)));
                end
            end
        end %Bloc
        
        function x = getZoneAxis(self)
            x = arrayfun(@(x) getZoneAxis(x.parameter),self,'UniformOutput',0);
        end
    end
    
end

