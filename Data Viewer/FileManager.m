classdef FileManager < handle
    %
    % View for FileManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    % Icons properties
    properties
        DatasetIcon = fullfile(matlabroot,'toolbox','matlab','icons','foldericon.gif');
        SequenceIcon = fullfile(matlabroot,'toolbox','matlab','icons','greencircleicon.gif');
        FileIcon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_filenew.gif');
        RelaxObjIcon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_object02.gif');
    end
    
    methods (Access = public)
        % Constructor
        function this = FileManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            this.gui.fig = figure('Name','File Manager','NumberTitle','off',...
                'MenuBar','none','ToolBar','none','Units','normalized',...
                'Position',[0 0.1 0.24 0.75],'Tag','fig');
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
          
        end %FileManager
        
        % Destructor
        function deleteWindow(this)
            %remove the closerequestfcn from the figure, this prevents an
            %infitie loop with the following delete command
            set(this.gui.fig,  'closerequestfcn', '');
            %delete the figure
            delete(this.gui.fig);
            %clear out the pointer to the figure - prevents memory leaks
            this.gui = [];
        end  %deleteWindow   
    end
    
    methods (Access = public)
        % Add new data to the table
        function this = addData(this, dataset, sequence, filename, displayName)
            % check input type
            if ischar(dataset) && ischar(sequence) && ischar(filename)
                % convert to cell
                dataset = {dataset};
                sequence = {sequence};
                filename = {filename};
                displayName = {displayName};
            elseif iscell(dataset) && iscell(sequence) && iscell(filename)
                % check if size is consistent
                if ~isequal(length(dataset),length(sequence)) ||...
                        ~isequal(length(dataset),length(filename))
                    error('FileManager:addData','Input size is not consistent')
                end
            else
                error('FileManager:addData','Input type is not consistent')
            end
            
            % import tree package
            import uiextras.jTree.*
            
            % create fileID
            fileID = strcat(dataset, sequence, filename,...
                repmat({'@'},1,numel(dataset)), displayName);
            
            % check if checkbox tree exists
            if isempty(this.gui.fig.Children)
                % create checkbox tree
                this.gui.tree = CheckboxTree('Parent',this.gui.fig,...
                  'Editable',true, 'DndEnabled',true,...
                  'NodeDraggedCallback', @(s,e) FileManager.DragDrop_Callback(s,e),...
                  'NodeDroppedCallback', @(s,e) FileManager.DragDrop_Callback(s,e),...
                  'Tag','tree');
                
                % + change root name and set icon
                this.gui.tree.Root.Name = dataset{1};
                this.gui.tree.Root.UserData = 'dataset';
                setIcon(this.gui.tree.Root, this.DatasetIcon);  
                % + sequence
                hSequence = CheckboxTreeNode('Parent',this.gui.tree.Root,...
                                             'Name', sequence{1},...
                                             'UserData','sequence',...
                                             'Value', fileID(1));
                setIcon(hSequence, this.SequenceIcon);  
                % + filename
                hFile = CheckboxTreeNode('Parent',hSequence,...
                                             'Name', filename{1},...
                                             'UserData','file',...
                                             'Value', fileID(1));
                setIcon(hFile, this.FileIcon); 
                % + relaxobj
                hRelaxObj = CheckboxTreeNode('Parent',hFile,...
                                   'Name', displayName{1},...
                                   'UserData','relaxObj',...
                                   'Value', fileID(1));
                setIcon(hRelaxObj, this.RelaxObjIcon);
                
                if length(dataset) > 1
                    idx = 2;
                else
                    return
                end
            else
                idx = 1;
            end
                               
            
            % loop over the input
            for k = idx:length(dataset)
                % dataset level: check existence
                tf = strcmp(get(this.gui.tree.Root,'Name'), dataset{k});
                if all(tf == 0)
                    % create new checkbox tree
                    hDataset = CheckboxTreeNode('Root',this.gui.tree,...
                                                 'Name', dataset{k},...
                                                 'UserData', 'dataset',...
                                                 'Value', fileID(k));
                    setIcon(hDataset, this.DatasetIcon);
                    % + sequence
                    hSequence = CheckboxTreeNode('Parent',hDataset,...
                                                 'Name', sequence{k},...
                                                 'UserData', 'sequence',...
                                                 'Value', fileID(k));
                    setIcon(hSequence, this.SequenceIcon);                         
                    % + filename
                    hFile = CheckboxTreeNode('Parent',hSequence,...
                                                 'Name', filename{k},...
                                                 'UserData', 'file',...
                                                 'Value', fileID(k));
                    setIcon(hFile, this.FileIcon); 
                    % + relaxobj
                    hRelaxObj = CheckboxTreeNode('Parent',hFile,...
                                       'Name', displayName{k},...
                                       'UserData', 'relaxObj',...
                                       'Value', fileID(k));
                    setIcon(hRelaxObj, this.RelaxObjIcon);
                else
                    % get handle to the dataset and add fileID
                    hDataset = this.gui.tree.Root(tf);
                    hDataset.Value = [hDataset.Value fileID(k)];
                    % + sequence
                    hSequence = FileManager.checkNodeExistence(hDataset, sequence{k}, this.SequenceIcon, 'sequence', fileID(k));
                    % + filename
                    hFile = FileManager.checkNodeExistence(hSequence, filename{k}, this.FileIcon, 'file', fileID(k));
                    % + relaxobj
                    FileManager.checkNodeExistence(hFile, displayName{k}, this.RelaxObjIcon, 'relaxObj', fileID(k));
                end
            end
        end %addData
        
        % Remove data from the table
        function this = removeData(this)
               % just delete the selected nodes and their children
               delete(this.gui.tree.CheckedNodes);
        end %removeData
        
        % Get the fileID list of the selected nodes
        function fileID = getIDofSelectedNodes(this)
            % get the list of the selected nodes
            hSelected = this.gui.tree.CheckedNodes;           
            % get fileID by checking the value of the checked node
            fileID = [hSelected.Value];
        end %getIDofSelectedNodes
    end
    
    methods (Access = public, Static = true)
        % this function determines if the dragged target is valid or not.
        % All target are valid except relaxObj.
        function DropOk = DragDrop_Callback(~, event)
            % Is this the drag or drop part?
            DoDrop = ~(nargout); % The drag callback expects an output, drop does not

            % get source and target
            src = event.Source;
            target = event.Target;
            
            % Check if the source & target are valid:
            % *User can drag files or sequences
            % *Files can be dropped in sequences or files
            % *Sequences can be dropped in sequences or dataset
            if strcmp(src.UserData,'file') &&...
                  (strcmp(target.UserData,'sequence') || strcmp(target.UserData,'file')) ||...
                      strcmp(src.UserData,'sequence') &&...
                  (strcmp(target.UserData,'dataset') || strcmp(target.UserData,'sequence'))
                % valid target and source
                DropOk = true;
            else
                % invalid target or source
                DropOk = false;
            end

            % If drop is allowed
            if DoDrop && strcmpi(event.DropAction,'move')
                % depending on the source and target reorganize
                % children/parent 
                if src.Parent == target.Parent
                    % find the step between the source and target
                    Children = [Dst.Parent.Children];
                    MatchDst = find(Children == Dst);
                    step = find(target.Parent.Children == target) -...
                        find(src.Parent.Children == src);
                    % TO DO
                    
                else
                    
                end
                % get the handle of the children & parent
                hParent = src.Parent;
                hChildren = hParent.Children(hParent.Children == src);
                % Re-parent
                set(hChildren,'Parent',target);
                % update source ID
                hChildren.Value = strrep(hChildren.Value, hParent.Name, hChildren.Parent.Name);
                hChildren.Parent.Value = [hChildren.Parent.Value hChildren.Value];
                % delete old parent if no more children
                if isempty(hParent.Children)
                    delete(hParent)
                end
                % call FitLike to update RelaxData
                % TO DO
            end
        end %DragNodeCallback
        
        % Check node existence and create it if needed. This function looks
        % in the parent handle node the children's name and check if the
        % wanted name exists or not. If is exists checkNodeExistence return
        % the corresponding children handle. If it does not,
        % checkNodeExistence create a new Children in hParent with the
        % wanted name and return the new children handle.
        % this function also take an icon, a type and an identifier fileID (a 1x1
        % cell array of string) that will be add to the field value
        function hChildren = checkNodeExistence(hParent, nodeName, icon, type, fileID)
            % import tree package
            import uiextras.jTree.*
            % check if children
            if isempty(hParent.Children)
                hChildren = CheckboxTreeNode('Parent', hParent,...
                                             'Name', nodeName,...
                                             'UserData', type,...
                                             'Value', fileID);
                setIcon(hChildren,icon);                         
            else
                % check if the wanted name corresponds to a children in the
                % parent container
                tf = strcmp(get(hParent.Children,'Name'),nodeName);
                % if true, get the handle. If false, create new node
                if all(tf == 0)
                    hChildren = CheckboxTreeNode('Parent',hParent,...
                                                 'Name',nodeName,...
                                                 'UserData', type,...
                                                 'Value',fileID);
                    setIcon(hChildren,icon);  
                else
                    hChildren = hParent.Children(tf);
                    hChildren.Value = [hChildren.Value fileID];
                end
            end
        end %checkNodeExistence
    end   
end

