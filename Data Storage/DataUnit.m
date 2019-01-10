classdef DataUnit < handle & matlab.mixin.Heterogeneous
    %
    % Abstract class that define container for all the Stelar SPINMASTER
    % relaxometer data (bloc, zone, dispersion).
    % DataUnit and its subclasses handle structure as well as array of
    % structure.
    % Notice that attributes for properties are defined directly avoiding
    % the need for further checking.
    %
    % SEE ALSO BLOC, ZONE, DISPERSION
    
    % file data
    properties (Access = public)
        x@double = [];          % main measure X (time, Bevo,...)
        xLabel@char = '';       % name of the  variable X ('time','Bevo',...)
        y@double = [];          % main measure Y ('R1','fid',...)
        dy@double = [];         % error bars on Y
        yLabel@char = '';       % name of the variable Y ('R1','fid',...)
        mask@logical = true(0);           % mask the X and Y arrays
        subUnitList@DataUnit;          % stores DataUnits of the same type to merge data sets while keeping unmerge capabilities
    end   
    
    % file parameters
    properties (Access = public)
        parameter@ParamObj = ParamObj();       % list of parameters associated with the data
    end
    
    % file processing
    properties (Access = public)
        processingMethod@ProcessDataUnit; % stores the processing objects that are associated with the data unit
    end
    
    % file properties
    properties (Access = public)
        legendTag@char = '';
        label@char = '';        % label of the file ('control','tumour',...)
        displayName@char = '';         % char array to place in the legend associated with the data
        filename@char = '';            % name of the file ('file1.sdf')
        sequence@char = '';            % name of the sequence ('IRCPMG')
        dataset@char = 'myDataset';    % name of the dataset('ISMRM2018')
        fileID@char;                % generate unique ID 
    end
    
    % other properties
    properties (Hidden = true)
        parent@DataUnit;            % parent of the object
        children@DataUnit;          % children of the object
    end
    
    events
        FileDeletion
        FileHasChanged
        DataHasChanged
    end
    
    methods 
        % Constructor: obj = DataUnit('field1',val1,'field2','val2',...)
        % DataUnit can build structure or array of structure depending on
        % the input:
        % x = num2cell(ones(10,1)); % array of cell
        % obj = DataUnit('x',x); % array of structure
        % obj = DataUnit('x',[x{:}]) % structure
        function this = DataUnit(varargin)
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
                    this.(varargin{ind}) = varargin{ind+1};                         
                end 
                % parent explicitely the object if needed
                if ~isempty(this.parent)
                    link(this.parent, this);
                    this.fileID = this.parent.fileID;
                else
                    % add ID
                    this.fileID = char(java.util.UUID.randomUUID);
                end
            else
                % array of struct
                % check for cell sizes
                n = length(varargin{2});
                if ~all(cellfun(@length,varargin(2:2:end)) == n)
                    error('Size input is not consistent for array of struct.')
                else
                    fh = str2func(class(this));
                    % initialise explicitely the array of object (required
                    % for heterogeneous array)
                    % for loop required to create unique handle.
                    for k = n:-1:1
                        % initialisation required to create unique handle
                        this(1,k) = fh();
                        % fill arguments
                        for ind = 1:2:nargin 
                            [this(k).(varargin{ind})] = varargin{ind+1}{k};                          
                        end
                        % parent explicitely the object if needed
                        if ~isempty(this(k).parent)
                            link(this(k).parent, this(k));
                            this(k).fileID = this(k).parent.fileID;
                        else
                            % add ID
                            this(k).fileID = char(java.util.UUID.randomUUID);
                        end
                    end
                end
            end   
            % set displayName
            setDisplayName(this);
            % generate mask if missing
            resetmask(this);
        end %DataUnit    
        
        % Destructor
        function delete(this)
            delete(this.parent);
            this.children(:) = [];
            this.parent(:) = [];
            notify(this, 'FileDeletion');
        end
    end
    
    methods (Access = public)
        % assign a processing function to the data object
        function self = assignProcessingFunction(self,processObj)
            self = arrayfun(@(s)setfield(s,'processingMethod',processObj),self,'UniformOutput',0); %#ok<*SFLD>
            self = [self{:}];
        end

        % link parent and children units
        function [parentObj,childrenObj] = link(parentObj,childrenObj)
            for indp = 1:length(parentObj)
                for indc = 1:length(childrenObj)
                    % check that the children objects are not already listed in the
                    % parent object
                    if ~sum(isequal(childrenObj(indc).parent,parentObj(indp)))
                        childrenObj(indc).parent(end+1) = parentObj(indp);
                    end
                    % check that the children objects are not already listed in the
                    % parent object
                    if ~sum(isequal(parentObj(indp).children,childrenObj(indc)))
                        parentObj(indp).children(end+1) = childrenObj(indc);
                    end
                end
            end         
        end
        
        % wrapper function to start the processing of the data unit
        function [newDataUnit,self] = processData(self)
            if sum(arrayfun(@(s)isempty(s.processingMethod),self))
                error('One or more data object are not assigned to a processing function.')
            end
            newDataUnit = arrayfun(@(o)processData(o.processingMethod,o),self,'UniformOutput',0);
            newDataUnit = [newDataUnit{:}];
        end        
        
        % collect the display names from all the parents in order to get
        % the entire history of the processing chain, for precise legends
        function legendStr = collectLegend(self)
            legendStr = self.legendTag;
            if ~isempty(self.parent)
                legendStr = [legendStr ', ' collectLegend(self.parent)];
            end
        end
        
        % make a copy of an object
        function other = copy(self)
            fh = str2func(class(self));
            other = fh();
            fld = fields(self);
            for ind = 1:length(fld)
                other.(fld{ind}) = self.(fld{ind});
            end
        end

        % merging function, merges a list of the same data object type
        function mergedUnit = merge(selfList)
            % check that object are homonegeous
            fh = str2func(class(selfList));
            if strcmp(fh, 'DataUnit')
                mergedUnit = [];
                return
            else
                % call constructor with the first merged filename (avoid
                % returning null object)
                mergedUnit = fh('filename',[selfList(1).filename,' (merged)'],...
                                'sequence',selfList(1).sequence,'dataset',...
                                selfList(1).dataset, 'displayName',...
                                selfList(1).displayName,'legendTag',...
                                selfList(1).legendTag,'xLabel',...
                                selfList(1).xLabel,'yLabel',...
                                selfList(1).yLabel);
                mergedUnit.subUnitList = selfList;
            end
        end

        % reverse operation 
        function dataList = unMerge(self)
            dataList = self.subUnitList;
            delete(self.subUnitList);
        end

        % removal from the parent object list for clean deletion
        function unlink(self)
            if length(self)>1
                arrayfun(@(o)unlink(o),self,'UniformOutput',0)
            else
                for i = 1:length([self.parent])
                    ind = arrayfun(@(o)isequal(o,self),self.parent(i).children);
                    self.parent(i).children(ind) = [];
                end
                for i = 1:length([self.children])
                    ind = arrayfun(@(o)isequal(o,self),self.children(i).parent);
                    self.children(i).parent(ind) = [];
                end
            end
        end
    end % methods
    
    methods (Access = public, Sealed = true)                
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
        
        % update an existing data set with new properties
        function self = updateProperties(self,varargin)
            fieldName = varargin(1:2:end);
            value = varargin(2:2:end);
            selfcell = mat2cell(self(:)',1,ones(1,length(self)));
            for nf = 1:length(fieldName)
                if ~iscell(value{nf})
                    value{nf} = repmat(value(nf),1,length(self));
                elseif length(value{nf}) == 1
                    value{nf} = repmat(value{nf},1,length(self));
                end
                selfcell = cellfun(@(obj,value) setfield(obj,fieldName{nf},value),selfcell,value{nf},'UniformOutput',0);
            end
            self = [selfcell{:}];
        end
        
        % set displayName following this rule:
        % [class(obj) obj.legendTag (obj.parent.legendTag,
        % obj.parent.parent.legendTag, ...)]
        function obj = setDisplayName(obj)
            % loop if multiple file
            for k = 1:numel(obj)
                % check if existing displayName
                if ~isempty(obj(k).displayName)
                    continue
                end
                % init
                if isempty(obj(k).legendTag)
                    obj(k).displayName = class(obj(k));
                else
                    obj(k).displayName = [class(obj(k)),' ',obj(k).legendTag];
                end
                % loop over the parent to get additional information
                if ~isempty(obj(k).parent)
                    if ~isempty(obj(k).parent.legendTag)
                        parentTag = collectLegend(obj(k).parent);
                        obj(k).displayName = [obj(k).displayName,' (',...
                                                parentTag(1:end-2),')'];
                    end
                end     
            end
        end %setDisplayName
        
        
        %%% ------------------- PLOT ------------------- %%%
        % Note: This part will be moved to an external object soon.
        % [M.Petit]
        % plot data function
        function h = plotData(obj, idxZone, plotID, axe, color, style, mrk, mrksize)
            % get data
            [xp,yp,~,maskp] = getData(obj, idxZone);
            % get legend
            leg = getLegend(obj, idxZone, 'Data', 0);
            % plot
            h = errorbar(xp(maskp),...
                    yp(maskp),...
                    [],...
                    'DisplayName', leg,...
                    'Color',color,...
                    'LineStyle',style,...
                    'Marker',mrk,...
                    'MarkerSize',mrksize,...
                    'MarkerFaceColor','auto',...
                    'Tag',plotID,...
                    'parent', axe); 
         end %plotData
         
         % Add error to an existing errorbar. 
         function h = addError(obj, idxZone, h)
             % get data
             [~,~,dyp, maskp] = getData(obj, idxZone);
             % plot
             set(h, 'YNegativeDelta',-dyp(maskp), 'YPositiveDelta',dyp(maskp));
         end %addError
         
         % Plot Masked data
         function h = plotMaskedData(obj, idxZone, plotID, axe, color, mrk, mrksize)
             % get data
             [xp,yp,~,maskp] = getData(obj, idxZone);
             % check if data to plot
             if ~isempty(yp(~maskp))
                 % plot
                 h = scatter(axe,...
                     xp(~maskp),...
                     yp(~maskp),...
                     'MarkerEdgeColor', color,...
                     'Marker', mrk,...
                     'SizeData',mrksize,...
                     'MarkerFaceColor','auto',...
                     'Tag', plotID);
                 % remove this plot from legend
                 set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
             end
         end %plotMaskedData
         
         % Plot Fit
         % varargin: color, style, marker
         function h = plotFit(obj, idxZone, plotID, axe, color, style, mrk)
             % get data
             [xfit, yfit] = getFit(obj, idxZone, []);
             % check if possible to plot fit
             if ~isempty(yfit)
                 % get legend
                 leg = getLegend(obj, idxZone, 'Fit', 0);
                 % plot
                 h = plot(axe, xfit, yfit,...
                     'DisplayName', leg,...
                     'Color', color,...
                     'LineStyle', style,...
                     'Marker', mrk,...
                     'Tag', plotID);
             end
         end %plotFit
         
         % Plot Residual
         function h = plotResidual(obj, idxZone, plotID, axe, color, style, mrk, mrksize)
              % get data
              [xr,yr,~,maskr] = getData(obj, idxZone);
              [~, yfit] = getFit(obj, idxZone, xr(maskr));
             % check if possible to plot fit
             if ~isempty(yfit) && ~isempty(yr)
                 h = plot(axe, xr(maskr), yr(maskr) - yfit,...
                     'LineStyle',style,...
                     'Color',color,...
                     'Marker',mrk,...
                     'MarkerFaceColor',color,...
                     'MarkerSize', mrksize,...
                     'Tag',plotID);
             end
         end %plotResidual
        %%% -------------------------------------------- %%%
    end %methods
    
    % The methods described below are used to enable the merge capabilities
    % of the DataUnit object. They work by re-directing any quiry for the
    % x, y, dy and mask fields towards the list of sub-objects. Any
    % modification in here must take care to avoid recursive calls and to
    % limit the processing time, as these fields are used extensively
    % during processing.
    % LB 20/08/2018
    methods
        % check that new objects added to the list are of the same type as
        % the main object
        function self = set.subUnitList(self,objArray) %#ok<*MCSV,*MCHC,*MCHV2>
            test = arrayfun(@(o)isa(o,class(self)),objArray);
            if ~prod(test) % all the objects must have the correct type
                error('Merged objects must be of the same type as the object container.')
            end
            self.subUnitList = objArray;
        end
        
        % function that gathers the data from the sub-units and place them
        % in the correct field. Always concatenate over the last
        % significant dimension (dispersions)
        function value = gatherSubData(self,fieldName)
            sze = size(self.subUnitList(1).(fieldName));
            n = ndims(self.subUnitList(1).(fieldName));
            if (n == 2) && (sze(2)==1)
                n = 1;
            end                
            value = cat(n,self.subUnitList.(fieldName));
%             self.(fieldName) = value;
        end
        
        % function that spreads the data from the contained object to the
        % sub-units
        function self = distributeSubData(self,fieldName,value)
            % list the number of element needed in each sub-object
            lengthList = arrayfun(@(o)length(o.(fieldName)),self.subUnitList);
            endList = cumsum(lengthList);
            startList = [1 endList(1:end-1)+1];
            s = arrayfun(@(o,s,e)setfield(o,fieldName,value(s:e)),self.subUnitList,startList,endList,'UniformOutput',0); 
            self.subUnitList = [s{:}];
        end
        
        % functions used to make sure that merged objects behave
        % consistently with their own object type. (see Matlab help on
        % 'Modify Property Values with Access Methods')
        function self = set.x(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'x',value);
            end
            self.x = value;
        end
        
        function x = get.x(self)
            if ~isempty(self.subUnitList)
                x = gatherSubData(self,'x');
            else
                x = self.x;
            end
        end
        
        function self = set.y(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'y',value);
            end
            self.y = value;
        end
        
        function y = get.y(self)
            if ~isempty(self.subUnitList)
                y = gatherSubData(self,'y');
            else
                y = self.y;
            end
        end
        
        function self = set.dy(self,value)
            if ~isempty(self.subUnitList)
                % distribute the values to the sub-units
                self = distributeSubData(self,'dy',value);
            end
            self.dy = value;
        end
        
        function dy = get.dy(self)
            if ~isempty(self.subUnitList)
                dy = gatherSubData(self,'dy');
            else
                dy = self.dy;
            end
        end
        
        function self = set.mask(self,value)
            if ~isempty(self.subUnitList) %#ok<*MCSUP>
                % distribute the values to the sub-units
                self = distributeSubData(self,'mask',value);
            end
            self.mask = value;
        end
        
        function mask = get.mask(self)            
            if ~isempty(self.subUnitList)
                mask = gatherSubData(self,'mask');
            else
                mask = self.mask;
            end
        end
        
        function param = get.parameter(self)
            if ~isempty(self.subUnitList)
                param = merge([self.subUnitList.parameter]);
            else
                param = self.parameter;
            end
        end
        
        function self = set.parameter(self,value)
            if ~isempty(self.subUnitList)
                % TO DO
                warning('Assignement of parameters not yet implemented for merged objects. See DataUnit.m, function set.parameter.')
                self.subUnitList(1).parameter = value;
            else
                self.parameter = value;
            end
        end
    end
     
end

