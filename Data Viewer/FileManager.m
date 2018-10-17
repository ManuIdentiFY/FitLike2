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
            % import tree package
            import uiextras.jTree.*
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;
                      
            % Make the figure
            this.gui.fig = figure('Name','File Manager','NumberTitle','off',...
                'MenuBar','none','ToolBar','none','Units','normalized',...
                'Position',[0.02 0.1 0.22 0.78],'Tag','fig','Visible','off');
            
            % Make the tree 
            this.gui.tree = TreeManager(FitLike, 'Parent',this.gui.fig,...
                'Editable',true, 'DndEnabled',true,...
                'MouseClickedCallback',@(s,e) this.FitLike.selectFile(s, e),...
                'Tag','tree','RootVisible',false);
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
end

