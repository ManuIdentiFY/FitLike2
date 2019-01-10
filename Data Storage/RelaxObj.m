classdef RelaxObj < handle & matlab.mixin.Heterogeneous
    % This class manage Stelar data from the SPINMASTER relaxometer.
    %
    % See also DATAUNIT, BLOC, ZONE, DISPERSION
    
    % file properties
    properties (Access = public)
        label@char = '';        % label of the file ('control','tumour',...)
        filename@char = '';            % name of the file ('file1.sdf')
        sequence@char = '';            % name of the sequence ('IRCPMG')
        dataset@char = 'myDataset';    % name of the dataset('ISMRM2018')
    end
    
    properties (Hidden)
        fileID@char;   % generate unique ID 
        subRelaxObj@RelaxObj
    end
    
    % data properties
    properties (Access = public)
        data@DataUnit
        parameter@ParamObj = ParamObj();  
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
            % add fileID
            obj.fileID = char(java.util.UUID.randomUUID);
        end %RelaxObj         
        
        % Data formating: mergeFile()
        function obj = merge(obj_list)
            % check input
            if numel(obj_list) < 2
                return
            end
            % check if files are already merged
            switch isMerged(obj_list)
                case 0
                    % merge data and parameter
                    merged_data = merge([obj_list.data]);
                    merged_parameter = merge([obj_list.parameter]);
                    % create merged object from first object list
                    obj_list(1).data = merged_data;
                    obj_list(1).parameter = merged_parameter;
                    obj_list(1).subRelaxObj = obj_list;
                    obj = obj_list(1);
                case 1
                    % unmerge data and parameter
                    unmerged_data = merge([obj_list.data]);
                    unmerged_parameter = merge([obj_list.parameter]);
                    % create unmerged object
%                     obj_list(1).data = merged_data;
%                     obj_list(1).parameter = merged_parameter;
%                     obj = obj_list.subRelaxObj;
                otherwise
                    % mix of merged and unmerged files
                    return
            end
        end %mergeFile
    end
end

