classdef FitLikeView < handle
    %
    % View for the FitLike menu
    %
    
    properties
        gui % GUI (Menu FitLike)
        FitLike % Presenter
    end
    
    methods
        % Constructor
        function this = FitLikeView(FitLike)
            %%--------------------------BUILDER--------------------------%%
            % Store a reference to the presenter
            this.FitLike = FitLike;                     
            % Make the figure
            gui = buildFitLikeView();
            this.gui = guihandles(gui);           
            %%-------------------------CALLBACK--------------------------%%
            %% File Menu
            % Open function
            set(this.gui.Open, 'callback', ...
                @(src, event) this.FitLike.open());
            % Remove funcion
            set(this.gui.Remove, 'callback', ...
                @(src, event) this.FitLike.remove());
            % Export function
            
            % Save function
            
            % Close function
            set(this.gui.menu,  'closerequestfcn', ...
                @(src,event) this.FitLike.closeWindowPressed());          
            set(this.gui.Quit, 'callback', ...
                @(src, event) this.FitLike.closeWindowPressed()); 
            %% Edit Menu
            % Move function
            
            % Copy function
            
            % Sort function
            
            % Merge function
            
            % Mask function
            
            %% View Menu
            % Axis function
            
            % Plot function
            
            % CreateFig function
            set(this.gui.Create_Fig, 'callback', ...
                @(src, event) this.FitLike.createFig());
            %% Tool Menu
            % Filter function
            
            % Mean function
            
            % Normalise
            
            % BoxPlot
            
            %% Display Menu
            % Hide/Show function: FileManager
            set(this.gui.FileManager, 'callback',...
                @(src,event) this.FitLike.showWindow(src));  
            % Hide/Show function: DisplayManager         
            set(this.gui.DisplayManager, 'callback',...
                @(src,event) this.FitLike.showWindow(src));           
            % Hide/Show function: ProcessingManager
            set(this.gui.ProcessingManager, 'callback',...
                @(src,event) this.FitLike.showWindow(src));  
            % Hide/Show function: ModelManager
            
            % Hide/Show function: AcquisitionManager
            
            %% Help Menu
            % Documentation function

        end
        
        % Destructor
        function deleteWindow(this)
            %remove the closerequestfcn from the figure, this prevents an
            %infitie loop with the following delete command
            set(this.gui.menu,  'closerequestfcn', '');
            %delete the figure
            delete(this.gui.menu);
            %clear out the pointer to the figure - prevents memory leaks
            this.gui = [];
        end
    end
    
end

