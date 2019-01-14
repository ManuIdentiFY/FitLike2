classdef FitLikeView < handle
    %
    % View for the FitLike menu
    %
    
    properties
        gui % GUI (Menu FitLike)
        FitLike % Presenter
    end
    
    properties
        color = get(groot,'defaultAxesColorOrder'); %list of available color for label
        file_icon = fullfile(matlabroot,'toolbox','matlab','icons','HDF_filenew.gif');
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
            % open folder
            set(this.gui.OpenFolder, 'callback', ...
                @(src, event) this.FitLike.opendir());
            % Remove funcion
            set(this.gui.Remove, 'callback', ...
                @(src, event) this.FitLike.remove());
            % Export function
            set(this.gui.Export_Dispersion, 'callback', ...
                @(src, event) this.FitLike.export(src))
            % Save function
            set(this.gui.Save, 'callback',...
                @(src, event) this.FitLike.save());
            % Close function
            set(this.gui.menu,  'closerequestfcn', ...
                @(src,event) this.FitLike.closeWindowPressed());          
            set(this.gui.Quit, 'callback', ...
                @(src, event) this.FitLike.closeWindowPressed()); 
            %% Edit Menu
            % Add label function
            set(this.gui.addLabel, 'callback', ...
                @(src, event) this.FitLike.addLabel(src)); 
            % Remove label function
            set(this.gui.removeLabel, 'callback', ...
                @(src, event) this.FitLike.removeLabel(src)); 
            % Move function
            
            % Copy function
            
            % Sort function
            
            % Merge function
%             set(this.gui.Merge, 'callback', ...
%                 @(src, event) this.FitLike.merge());
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
            set(this.gui.ModelManager, 'callback',...
                @(src,event) this.FitLike.showWindow(src));            
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
        end %deleteWindow
    end
    
    methods (Access = public)
        % Add label items to the label list
        function [this, icon] = addLabelItem(this, new_label)
            % check the length of the list
            hLabel = this.gui.LabelList.Children;
            n = numel(hLabel);
            
            % check if we reach the icon list limit
            if n > size(this.color,1) + 1
                icon = []; 
                return; 
            elseif n == 2
                idx = 1;
            else
                % get the existing icons
                icon_list = vertcat(hLabel(1:end-2).UserData);
                % get the first missing icon
                [~,idx] = setdiff(this.color, icon_list, 'rows', 'stable');
            end
            
            % get the icon
            icon = [pwd,'\Data Viewer\icons\',num2str(idx(1)),'.gif'];
            % add the icon
            uimenu( this.gui.LabelList,...
                'Label', new_label,'UserData',this.color(idx(1),:),...
                'Callback',@(src,event) this.FitLike.addLabel(src));
            drawnow;
            
            % add java icon - close and open menu to prevent errors
            % See http://undocumentedmatlab.com/blog/customizing-menu-items-part-2/#dynamic           
            jMenuLabel = findjobj(this.gui.LabelList);
            
            jMenuLabel.doClick(); pause(0.005); % open the File menu
            jMenuLabel.doClick(); pause(0.005); % close the menu           
            
            jLabel = jMenuLabel.getMenuComponent(n);
            jLabel.setIcon(javax.swing.ImageIcon(icon));
        end %addLabelItem  
        
        % Remove label
        function this = removeLabel(this, label)
            % find the corresponding item
            hLabel = this.gui.LabelList.Children;
 
            % delete the item
            tf = strcmp({hLabel(1:end-2).Label}, label);
            delete(hLabel(tf));
        end %removeLabel
        
        % This function can create a colored version of the new_file icon.
        % Icons are stored in Data Viewer/icons (.gif format).
        function colorIcon(this, color, icon_name)
            % get the new_file icon
            [X, map]=imread(this.file_icon); 
            % store the background pixels
            tf = X == X(1,1);
            
            % convert the icon in grayscale image
            im = ind2rgb(X,map);
            im = rgb2gray(im);
            
            % multiply the grayscale image by the wanted color
            im_color = zeros([size(im), 3]);
            for i = size(im,1):-1:1
                for j = size(im,2):-1:1
                    im_color(i,j,:) = im(i,j).*color;
                end
            end
            
            % remove the background pixels
            [X,map] = rgb2ind(im_color, 64);
            map(end+1,:) = [1 1 1];
            X(tf) = size(map,1);
            
            % store the new icon
            warning off
            imwrite(X, map, icon_name);
            warning on
        end %colorIcon
    end
    
end

