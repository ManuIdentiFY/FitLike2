classdef DataUnit2DataUnit < handle & matlab.mixin.Copyable
    %
    % This class allows to format DataUnit for processing pipeline. Data
    % are formatted to fit with model requirements as well as making or 
    % modifying new Data Unit after processing step.
    %
    % see also BLOC2ZONE, ZONE2DISP, DATAUNIT, PROCESSDATAUNIT
    
    properties
        DataField = {'x','y','dy','mask'}; % define the field 
                                           % corresponding to data in DataUnit
        ForceDataCat@logical = false; %logical that forces data concatenation. 
                                      %Example: 
                                      % -false: Bloc() --> data_formated
                                      % is a BRLX x NBLK array of structure
                                      % where each field is 1xBS vector
                                      % -true: Bloc() --> data_formated
                                      % is a 1 x 1 array of structure
                                      % where each field is BS x NBLK x
                                      % BRLX matrix.
        ForceChildCreation@logical = false;  % force child creation when
                                            % parent DataUnit has children
                                            % with same class as the wanted
                                            % one for child creation.
        pipeline = []; % for future use, handle to the pipeline object
        InputData@DataUnit; % store the handle to the DataUnit object linked to the processing object
        OutputData@DataUnit; % store the handle to the data generated
    end
    
    properties (Access = private)
    end
    
    properties (Abstract)
        InputChildClass@char
        OutputChildClass@char %define the class of the child object
    end
    
    methods
        % Constructor
        function this = DataUnit2DataUnit()
            
        end %DataUnit2DataUnit
                
        % Format DataUnit data in an array of structure with the following
        % field: x, y, dy, mask (See DataUnit property).
        % Dimension of the array of structure depends on the input class:
        % - Bloc: data_formated is a NBLK x BRLX array of struct where each
        %         field is a BS x 1 vector
        % - Zone: data_formated is a BRLX x 1 array of struct where each
        %         field is a NBLK x 1 vector
        % - Dispersion: data_formated is a 1 x 1 array of struct where each
        %         field is a BRLX x 1 vector
        % 
        % If ForceDataCat property is set to true data_formated will be a
        % 1 x 1 structure where each field has the same size than the input
        % class:
        % Bloc: BS x NBLK x BRLX
        % Zone: NBLK x BRLX
        % Dispersion: BRLX x 1
        %
        function data_formated = getProcessData(this, DataUnit)
            % check input
            if ~isa(DataUnit,'DataUnit')
                data_formated = []; return
            end
            
            % get data dim
            dim = size(DataUnit.y);
            
            % cast dim in 3D
            if numel(dim) < 3; dim(3) = 1; end
                            
            % check if ForceDataCat is true
            if this.ForceDataCat
                % get data as is and prepare struct input
                for k = numel(this.DataField):-1:1
                    % field
                    varargin{2*k-1} = this.DataField{k}; 
                    % data
                    varargin{2*k} = DataUnit2DataUnit.checkSize(DataUnit.(this.DataField{k}), dim);
                end
                % create struct
                data_formated = struct(varargin{:});
            else
                % init to force appropriate orientation
                C = cell(numel(this.DataField), dim(2), dim(3));
                % loop over the field
                for k = 1:numel(this.DataField)
                    % get data
                    data = DataUnit2DataUnit.checkSize(DataUnit.(this.DataField{k}), dim);
                    % convert data to cell array
                    C(k,:,:) = mat2cell(data,...
                        dim(1),repelem(1,dim(2)),repelem(1,dim(3)));
                end
                % convert to array of struct
                data_formated = cell2struct(C, this.DataField, 1);
            end
        end %getProcessData    
        
        % Format processed data to make new DataUnit object. Input size
        % need to respect the format from getProcessData output:
        % - Bloc: data_formated is a NBLK x BRLX array of struct where each
        %         field is a (BS,1) x N vector
        % - Zone: data_formated is a BRLX x 1 array of struct where each
        %         field is a (NBLK,1) x N vector
        % - Dispersion: data_formated is a 1 x 1 array of struct where each
        %         field is a (BRLX,1) x N vector
        %
        % N is the number of object to create (Biexp: 2 object, Monoexp: 1
        % obj,...)
        % (BS,1): can take these two values. If Dispersion is filtered, it
        % will returned the same size object 1 x BRLX. On the other hand,
        % if Zone is fitted with Monoexp, each field will be 1 x 1 (T1).
        % 
        function DataUnit_child = makeProcessData(this, data_formated, DataUnit_parent)
            % check input
            if ~isa(DataUnit_parent,'DataUnit')
                DataUnit_child = []; return
            end
            
            % if no data, return parent object
            if isempty(data_formated); DataUnit_child = DataUnit_parent; return; end
            
            % get fieldnames and number of object
            fld = fieldnames(data_formated);
            n = size(data_formated(1,1).(fld{1}),2); %number of object to create
            
            % init
            data = cell(1,2*numel(fld)); data(1:2:end) = fld;
            % check if output data are singleton along first dimension. If
            % not, data were just modified and not converted into a new
            % class (filtering,...).
            if size(data_formated(1,1).(fld{1}),1) > 1
                % loop over the field
                for k = numel(fld):-1:1
%                     % loop over the object
%                     for i = 1:n
%                         val = arrayfun(@(x) x.(fld{k})(:,i), data_formated, 'Uniform', 0);
%                         val = [val{:}];
%                         % reshape
%                         val = reshape(val,[size(val,1), size(data_formated)]);
%                         % convert into cell array
%                         data{2*k} = [data{2*k}, val];
%                         data{2*k-1} = fld{k};
%                     end
%                     % other way: faster
                    val2 = vertcat(data_formated.(fld{k}));
                    val2 = reshape(val2,[size(data_formated(1,1).(fld{1}),1), size(data_formated), n]);
                    % convert into cell array
                    data{2*k} = mat2cell(val2,[1 1 repelem(1,n)]);
                    %                     
% check if identical
%                     if isequal(val2, DataUnit_parent.(fld{k}))
%                         disp('Ok!')
%                     end
                end
            else
                % loop over the field
                for k = numel(fld):-1:1
                    % get data and reshape
                    val = vertcat(data_formated.(fld{k}));
                    val = reshape(val,[size(data_formated), n]);
                    % convert into cell array
                    data{2*k} = mat2cell(val,[1 1 repelem(1,n)]);
                end
                    
            end
            
            % get the output class
            fh = str2func(this.OutputChildClass);
            
            if isempty(DataUnit_parent.children)
                % create child DataUnit
                DataUnit_child = fh('parent',repmat({DataUnit_parent},1,n), data{:});
            else
                % check the class of parent's children class and if the
                % same and flag is false update the parent's children
                % object. Else delete children.
                if strcmp(this.OutputChildClass, class(DataUnit_parent.children)) &&...
                        ~this.ForceChildCreation
                   % count children and create/delete/update in function
                   DataUnit_child = Data_parent.children;
                   nChild = numel(DataUnit_child);
                   if nChild < n
                       % loop over the field
                       for k = 1:fld
                           % get data and fill children
                           val = data{2*k}(1:nChild);
                           [DataUnit_child.(fld{k})] = val{:};
                           % remove used data
                           data{2*k}(1:nChild) = [];
                       end
                       % add new data
                       DataUnit_child = fh('parent',...
                           repmat({DataUnit_parent},1,n-nChild), data{:});
                   elseif nChild > n
                       % remove some children
                       for k = 1:(nChild - n)
                           delete(DataUnit_child(1));
                           DataUnit_child(1) = []; %clear
                       end
                       % update data
                       for k = 1:fld
                           [DataUnit_child.(fld{k})] = data{2*k}{:};
                       end
                   else
                       % update data
                       for k = 1:fld
                           [DataUnit_child.(fld{k})] = data{2*k}{:};
                       end    
                   end
                else
                   % delete all the children of parent
                   while ~isempty(DataUnit_parent.children)
                       delete(DataUnit_parent(1).children)
                       DataUnit_parent(1).children = []; %clear
                   end
                   % create child DataUnit
                   DataUnit_child = fh('parent',repmat({DataUnit_parent},1,n), data{:});
                end
            end
        end %makeProcessData
        
        function this = addInputData(this,dataUnit)
            if length(this)>1
                this = arrayfun(@(t) addInputData(t,dataUnit),this);
            else
                % check input type
                if ~isequal(class(dataUnit),this.InputChildClass)
                    error(['Wrong data input type , is ' class(dataToProcess) ' when expecting ' this.InputChildClass '.'])
                else
                    if isempty(this.InputData)
                        this.InputData = dataUnit;
                    elseif ~prod(arrayfun(@(d) isequal(d,dataUnit),this.InputData)) % check that the data is not already contained
                        this.InputData(end+1) = dataUnit;
                    end
                end
            end
        end
        
        function dataList = checkInputData(this)
            dataList = this.InputData;
        end
        
        function dataList = checkOutputData(this)
            dataList = this.OutputData;
        end
        
        function removeInputData(this,dataUnit)
            for i = 1:length(dataUnit)
                index = arrayfun(@(d) isequal(d,dataUnit(i)),this.InputData);
                this.InputData(index) = [];
            end
        end
        
        
        % standard naming convention for the processing function
        % Inputs: 
        %   this: array of processing objects
        %   dataToProcess: single DataUnit element
        function [this,dataProcessed,dataToProcess] = processData(this)
            % distribute the algorithms defined in the process object (which
            % inherits from DataUnit2DataUnit and DataModel)
            [z,b] = arrayfun(@(s)applyProcessFunction(s,this.InputData,this.OutputData),this,'UniformOutput',0);
            % parse outputs
            dataProcessed = [z{:}];
            dataToProcess = [b{:}];
            % check output type
            if ~isequal(class(dataProcessed),this.OutputChildClass)
                error(['Wrong data input type , is ' class(dataToProcess) ' when expecting ' this.OutputChildClass '.'])
            end
        end
                
%         % function that applies one processing function to one bloc only.
%         % This is where the custom processing function is being called.
%         function [zone,bloc] = applyProcessFunction(this,bloc,zone)            
%             
%             sze = size(bloc.y);
%             if length(sze)<3
%                 sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
%             end
%             % prepare the cell arrays, making sure the dimensions are
%             % consistent
%             cellx = squeeze(num2cell(bloc.x,1));
%             celly = squeeze(num2cell(bloc.y,1));
%             % make sure the data is sorted
%             [cellx,ord] = cellfun(@(c)sort(c),cellx,'UniformOutput',0);
%             celly = cellfun(@(c,o)c(o),celly,ord,'UniformOutput',0);
%             % cast to cell array for cellfun
% %             cellindex = repmat(num2cell(1:bloc.parameter.paramList.NBLK)',1,size(bloc.y,3));
%             if isempty(bloc.y)
%                 z = [];
%                 dz = [];
%                 paramFun = {};
%             else
%                 
%                 for i = 1:getRelaxProp(bloc, 'NBLK')                
%                     for j = 1:size(bloc.y,3)
%                         cellindex{i,j} = [i,j]; %#ok<AGROW>
%                     end
%                 end
%                 if ~isequal(size(cellindex),size(cellx))
%                     cellx = cellx';
%                     celly = celly';
%                 end
%                 % make sure that each acquisition is referenced from the time
%                 % of acquisition within the data bloc
%                 cellx = cellfun(@(x)x-x(1),cellx,'UniformOutput',0);
%                 % process the cell array to get the zone data
%                 [z, dz, paramFun] = cellfun(@(x,y,i) process(this,x,y,bloc,i),cellx,celly,cellindex,'Uniform',0);
%                 szeout = size(z{1,1});
%                 [szeout,ind] = max(szeout); 
%                 if ind == 2 % check that the result of the process is a column array
%                     z = reshape(cell2mat(z),sze(2),szeout,sze(3));
%                     dz = reshape(cell2mat(dz),sze(2),szeout,sze(3));
%                 else
%                     z = reshape(cell2mat(z),szeout,sze(2),sze(3));
%                     z = permute(z,[2 1 3]);
%                     dz = reshape(cell2mat(dz),szeout,sze(2),sze(3));
%                     dz = permute(dz,[2 1 3]);
%                 end
%             
%             end
%             
%             % generate one zone object for each component provided by the
%             % processing algorithm
%             warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved') % avoid spamming the terminal when the data is not multiexponential
%             cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
%             celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
%             cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
%             celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
%             x = getZoneAxis(bloc); % raw x-axis (needs to be repmat to fit the dimension of y)
%             x = repmat(x,size(cellz)); % make sure that all cell arrays are consistent
% %             params = repmat({params},size(cellz));
%             labelX = repmat({this.labelX},size(cellz));
%             labelY = repmat({this.labelY},size(cellz));
%             if numel(this.legendTag) ~= numel(labelX)
%                 legendTag = repmat(this.legendTag,size(cellz));
%             else
%                 legendTag = this.legendTag;
%             end
%             
%             % generate the children objects if they are not yet created
%             if isempty(this.OutputData)
%                 this.OutputData = Zone('parent',repmat({bloc},size(celldz)),...
%                                        'x',x,'xLabel',labelX,...
%                                        'y',cellz,'dy',celldz,'yLabel',labelY,...
%                                        'legendTag',legendTag,...
%                                        'relaxObj',bloc.relaxObj);
%             else % if a child object is there, just update it
%                 this.OutputData = arrayfun(@(z,lx,cz,cdz,ly,l) updateProperties(z,...
%                                             'xLabel',lx,...
%                                             'y',cz,'dy',cdz,'yLabel',ly,...
%                                             'legendTag',l),...
%                                             this.OutputData,labelX,cellz,celldz,labelY,legendTag);
%             end
%             zone = this.OutputData;
%             bloc = this.InputData;
%         end

        
    end
    
    methods (Static)        
        % Check if a matrix corresponds to a given size. If false, complete
        % the matrix with NaN to get the final matrix
        function data_checked = checkSize(data, dim)
            % check size
            s = size(data);
            
            % cast size in 3D
            if numel(s) < 3; s(3) = 1; end
            
            % check size and complete with NaN if required
            if isequal(s, dim)
                data_checked = data;
                return
            elseif isempty(data)
                data_checked = nan(dim);
            else
                data_checked = nan(dim);
                data_checked(1:s(1),1:s(2),1:s(3)) = data;
            end
        end %checkSize   
    end
    
    
%     methods (Abstract)
%         
%         % test the compatibility between the processing object and the
%         % input data
%         function out = testDataFormat(self)
%         end
%     end
    
end

