classdef RelaxObj < handle
    % This class manage Stelar data from the SPINMASTER relaxometer. It is
    % also the Model according to the MVP model.
    %
    % See also DATAUNIT, BLOC, ZONE, DISPERSION
    
    properties (SetAccess = public)
        filename % array of string of the filenames
        sequence % array of string of the sequences
        label % array of string of the labels
        data % array of DataUnit containing data
        parameters % array of cell containing parameter structures
        FitLike % store the Presenter in the Model (MVP)
    end
    
    methods
        % Constructor: RelaxObj()
        function obj = RelaxObj(varargin)           
            % check input, must be non empty and have always field/val
            % couple
            if nargin == 0 || mod(nargin,2) 
                % default value
                return
            end
            % fill the structure
            for ind = 1:2:nargin
                try 
                    obj.(varargin{ind}) = varargin{ind+1};
                catch ME
                    error(['Wrong argument ''' varargin{ind} ''' or invalid value/attribute associated.'])
                end                           
            end 
            % set the presenter
            obj.FitLike = FitLike;
        end %RelaxObj         
        
        % Data processing: processFile()
        function obj = processFile(obj,idx,method,model)
            % check input 
            if ~isa(obj,'RelaxObj')
                return
            end
            % apply getzone()

            % apply getdisp()
          
            % store the method and model in the DataUnit array
        end %processFile
        
        % Data formating: mergeFile()
        function obj = mergeFile(obj,idx)
            % check input
            if ~isa(obj,'RelaxObj') || length(idx) < 2
                return
            end
            % check if files already merged by looking at the parent
            % DataUnit size

            % merge the data
            
            % create new DataUnit

        end %mergeFile
        
        % Data formating: unmergeFile()
        function obj = unmergeFile(obj,idx)
        end %unmergeFile
        
        % Data processing: averageFile()
        function obj = averageFile(obj,idx)
        end %averageFile       
        
    end
end

