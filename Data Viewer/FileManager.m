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
            
            % Initialize FileManager with relaxObj
            selection = false(size(this.FitLike.RelaxObj.dataset));
            this.gui.table.Data = [num2cell(selection'),...
                                   [this.FitLike.RelaxObj.dataset]',...
                                   [this.FitLike.RelaxObj.sequence]',...
                                   [this.FitLike.RelaxObj.filename]'];
            
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
    
end

