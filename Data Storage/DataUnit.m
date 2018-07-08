classdef DataUnit < handle
    %
    % Abstract class that define container for all the Stelar SPINMASTER
    % relaxometer data (bloc, zone, dispersion).
    % DataUnit and its subclasses handle structure as well as array of
    % structure.
    % Notice that attributes for properties are defined directly avoiding
    % the need for further checking.
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, RELAXOBJ
    
    properties (Access = public)
        x@double = [];          % main measure X (time, Bevo,...)
        xLabel@char = '';       % name of the  variable X ('time','Bevo',...)
        y@double = [];          % main measure Y ('R1','fid',...)
        dy@double = [];         % error bars on Y
        yLabel@char = '';       % name of the variable Y ('R1','fid',...)
        mask@logical;           % mask the X and Y arrays
        parameter@ParamObj;       % list of parameters associated with the data
    end   
    
    methods 
        % Constructor: obj = DataUnit('field1',val1,'field2','val2',...)
        % DataUnit can build structure or array of structure depending on
        % the input:
        % x = num2cell(ones(10,1)); % array of cell
        % obj = DataUnit('x',x); % array of structure
        % obj = DataUnit('x',[x{:}]) % structure
        function obj = DataUnit(varargin)
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
                if ~all(cellfun(@length,varargin(2:2:end)) == length(varargin{2}))
                    error('Size input is not consistent for array of struct.')
                else
                    for ind = 1:2:nargin                  
                        try 
                            [obj(1:length(varargin{ind+1})).(varargin{ind})] = deal(varargin{ind+1}{:});
                        catch ME
                            error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                        end                           
                    end
                end
            end      
            resetmask(obj);
        end %DataUnit
        
        function x = getZoneAxis(obj)
            if size(obj) == 1
                x = getZoneAxis(obj.parameter);
            else
                x = arrayfun(@(x) getZoneAxis(x.parameter),obj,'Uniform',0);
            end
        end
                
        function x = getDispAxis(obj)
            if size(obj) == 1
                x = getDispAxis(obj.parameter);
            else
                x = arrayfun(@(x) getDispAxis(x.parameter),obj,'Uniform',0);
            end
        end
        
        % Data formating: resetmask
        % Fill or adapt the mask to the "y" field 
        function obj = resetmask(obj)
            % check if input is array of struct or just struct
            if length(obj) > 1 
                % array of struct
                idx = ~arrayfun(@(x) isequal(size(x.mask),size(x.y)), obj);
                % reset mask
                new_mask = arrayfun(@(x) true(size(x.y)),obj(idx),'UniformOutput',0);
                % set new mask
                [obj(idx).mask] = new_mask{:};
            else
                % struct
                if ~isequal(size(obj.mask),size(obj.y))
                    % reset mask
                    obj.mask = true(size(obj.y));
                end
            end
        end %resetmask
        
    end %method
    
     methods (Abstract)       
         % Data processing: method to process the data
%          obj = process(obj,varargin); %process
         
         % Data visualisation: method to plot the data
         h = plot(obj, idx); %plot
         
     end %method
end

