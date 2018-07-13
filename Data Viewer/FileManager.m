classdef FileManager < handle
    %
    % View for FileManager in FitLike
    %
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    methods (Access = public)
        % Constructor
        function this = FileManager(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            gui = buildFileManager();
            this.gui = guihandles(gui);
            
            %%-------------------------CALLBACK--------------------------%%
            % Replace the close function by setting the visibility to off
            set(this.gui.fig,  'closerequestfcn', ...
                @(src, event) this.FitLike.hideWindowPressed(src));  
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.table, 'CellEditCallback',...
                @(src, event) this.FitLike.selectFile(src, event));             
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
        function this = addData(this, dataset, sequence, filename)
            % check input type
            if ischar(dataset) && ischar(sequence) && ischar(filename)
                % add new row
                this.gui.table.Data = [this.gui.table.Data;...
                    [{false},dataset,sequence,filename]];
            elseif iscell(dataset) && iscell(sequence) && iscell(filename)
                % check if size is consistent
                if isequal(length(dataset),length(sequence)) &&...
                        isequal(length(dataset),length(filename))
                    % create selection column
                    selection = false(size(dataset));
                    % add new row
                    this.gui.table.Data = [this.gui.table.Data;...
                        [num2cell(selection)',dataset',sequence',filename']];
                else
                    error('FileManager:addData','Input size is not consistent')
                end
            else
                error('FileManager:addData','Input type is not consistent')
            end
        end %addData
        
        % Remove data from the table
        function this = removeData(this, isDelete)
            this.gui.table.Data(isDelete,:) = [];
        end %removeData
    end
    
end

