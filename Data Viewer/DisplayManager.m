classdef DisplayManager < handle
    %
    % View for DisplayManager in FitLike. This component manages a tab
    % system where data can be displayed. See the tab object (EmptyTab and
    % derived classes) for details.
    % DisplayManager can be used as a stand-alond component by simply
    % replacing the FitLike input by anything else (0,'1',true,...).
    %
    % See documentation&examples for details.
    %
    % M.Petit - 03/2019
    % manuel.petit@inserm.fr
    
    properties
        gui % GUI (View)
        FitLike % Presenter
    end
    
    % List of the wanted uitoggletool and uipushtool (TooltipString)
    properties
        ToggleToolList = {'Zoom Out','Zoom In','Pan'};
        PushToolList = [];
    end
    
    events
        PlotError
        SelectTab
    end
    
    methods (Access = public)
        % Constructor
        function this = DisplayManager(FitLike)
            %%--------------------------BUILDER--------------------------%%  
            % Build GUI        
            gui = buildDisplayManager(this,...
                this.ToggleToolList, this.PushToolList);
            this.gui = guihandles(gui);
            
            % Set SelectionChangedFcn calback for tab
            set(this.gui.tab, 'SelectionChangedFcn',...
                @(src, event) changeTab(this, src, event));   
            
            % Set callback when moving mouse
            set (this.gui.fig,'WindowButtonMotionFcn',...
                    @(src, event) moveMouse(this));
                
            % reset tab
            setUIMenu(this);
            drawnow;
            
            % Check if presenter is available
            if isa(FitLike,'FitLike')
                % Store a reference to the presenter
                this.FitLike = FitLike;                

                % Replace the close function
                set(this.gui.fig,  'closerequestfcn', ...
                    @(src, event) this.FitLike.hideWindowPressed(src));  
            else
                % set the window visible
                set(this.gui.fig,'Visible','on')
                % replace the close function
                set(this.gui.fig,  'closerequestfcn', ...
                    @(src, event) deleteWindow(this));  
            end
        end %DisplayManager

        % Destructor
        function deleteWindow(this)
            % remove all the children properly
            if ~isempty(this.gui.tab.Children)
                delete(this.gui.tab.Children)
            end
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
        % THIS = ADDTAB(THIS) adds a new tab to the current tab group. The
        % new tab which is an EmptyTab object is automaticaly selected.
        function this = addTab(this)
            % add an empty tab: Just to try different gui objects
            EmptyTab(this, uitab(this.gui.tab));
            % push this new tab to the position just before '+' tab
            uistack(this.gui.tab.Children(end),'up');
            % set the selection to this tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
            % reset tab
            setUIMenu(this);
            % EDT synchronisation
            drawnow;
        end %addTab
        
        % THIS = REMOVETAB(THIS) removes the selected tab in the current
        % tab group. If the current tab group contains two or less tabs, no
        % deletion are done. 
        function this = removeTab(this)
            % check the number of children
            n = numel(this.gui.tab.Children);
            % if more than 1 + 1, delete it
            if n > 2
                % delete the selected tab
                delete(this.gui.tab.SelectedTab);
                % check if the new selected tab is not '+'
                if isa(this.gui.tab.SelectedTab.Children,'EmptyPlusTab')
                    this.gui.tab.SelectedTab = this.gui.tab.Children(end-1);
                end
            end
        end %removeTab    
        
        % THIS = CHANGETAB(THIS,SRC,~) is a callback function fired when a
        % tab is selected. If the tab selected is an EmptyTabPlus object
        % ('+' tab), CHANGETAB adds a new tab.
        function this = changeTab(this, src, ~)
            % check if tab need to be added
            if isa(src.SelectedTab.Children,'EmptyPlusTab')
                addTab(this);
            end
            % notify
            notify(this, 'SelectTab');
        end
        
        % THIS = REPLACETAB(THIS,OLDTAB,NEWTAB) allows to replace an OLDTAB
        % object by a NEWTAB object. OLDTAB and NEWTAB should be EmptyTab
        % class object or derived classes.
        % See DispersionTab, ZoneTab, EmptyTabPlus
        function this = replaceTab(this, oldTab, newTab)
            % create the new tab
            fh = str2func(newTab);
            fh(this, uitab(this.gui.tab));
            % get the index of the oldTab
            indx = find(this.gui.tab.Children == oldTab);
            n = numel(this.gui.tab.Children);
            % move the new tab to this index
            uistack(this.gui.tab.Children(end), 'up', n-indx);
            % delete the old tab
            delete(oldTab);
            % set the selection to the new tab
            this.gui.tab.SelectedTab = this.gui.tab.Children(indx); 
            % reset tab
            setUIMenu(this);
        end %replaceTab
        
        % THIS = SETUIMENU(THIS) adds a contextmenu to the selected tab.
        % This contextmenu contains a close tab function that fires the
        % REMOVETAB function.
        function this = setUIMenu(this)
            % set contextmenu to the selected tab
            cmenu = uicontextmenu(this.gui.fig);
            uimenu(cmenu, 'Label', 'Close Tab',...
                'Callback',@(src,event) removeTab(this));
            this.gui.tab.SelectedTab.UIContextMenu = cmenu;  
        end

        % THIS = ADDPLOT(THIS,HDATA,IDXZONE) adds data to the selected tab.
        % HDATA should be an array of DataUnit and IDXZONE a vector of the
        % wanted zones with same size as HDATA. Remember that to get the
        % complete dispersion profile (all zones), IDXZONE needs to be NaN.
        function this = addPlot(this, hData, idxZone)
            % check if it is an empty tab
            if strcmp(class(this.gui.tab.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                % check the class of the first hData
                switch class(hData)
                    case 'Bloc'
                        return % TO DO
                    case 'Zone'
                        replaceTab(this, this.gui.tab.SelectedTab, 'ZoneTab');
                    case 'Dispersion'
                        replaceTab(this, this.gui.tab.SelectedTab, 'DispersionTab');
                end
            % check if correct class
            elseif ~strcmp(class(hData), this.gui.tab.SelectedTab.Children.inputType)
                % notify
                event = EventFileManager('Data',hData,'idxZone',idxZone);
                notify(this, 'PlotError', event);
                % send error
                msg = ['Error: Input data (',class(hData),') does not fit'...
                       ' the current tab (',this.gui.tab.SelectedTab.Children.inputType,')\n'];
                throwWrapMessage(this, msg);
                return
            end
            % call addPlot method of this tab
            for k = 1:numel(hData)
                addPlot(this.gui.tab.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % THIS = REMOVEPLOT(THIS,HDATA,IDXZONE) remove data from the 
        % selected tab corresponding to the HDATA and IDXZONE input.
        % HDATA should be an array of DataUnit and IDXZONE a vector of the
        % wanted zones with same size as HDATA. Remember that to remove the
        % complete dispersion profile (all zones), IDXZONE needs to be NaN.
        function this = removePlot(this, hData, idxZone)
            % check if empty tab
            if strcmp(class(this.gui.tab.SelectedTab.Children), 'EmptyTab') %#ok<STISA>
                return
            end
            % loop
            for k = 1:numel(hData)
                deletePlot(this.gui.tab.SelectedTab.Children, hData(k), idxZone(k));
            end
        end
        
        % [HDATA, IDXZONE] = GETDATA(THIS) returned the data contained in
        % the selected tab. HDATA is an array of DataUnit and IDXZONE a 
        % vector of the plotted zones with same size as HDATA.
        function [hData, idxZone] = getData(this)
            % get data
            hData = this.gui.tab.SelectedTab.Children.hData;
            idxZone = this.gui.tab.SelectedTab.Children.idxZone;
        end %getData
        
        % LEG = GETLEGEND(THIS) returned the legend input of the selected
        % tab. LEG is a cell array of string containing the legend of the
        % displayed data. Fit legend is not returned.
        % If no legend is available, LEG is empty.
        function leg = getLegend(this)
            leg = getLegend(this.gui.tab.SelectedTab.Children);
        end
        
        % THIS = THROWWRAPMESSAGE(THIS, TXT) allows to return messages. TXT
        % should be a char. If FitLike is available, this function throws
        % an event and notify else it prints the message in the command
        % window.
        % Remember to add '\n' at the end of your message if you want to
        % return to the next line.
        function this = throwWrapMessage(this, txt)
            % check FitLike
            if ~isa(this.FitLike,'FitLike')
                fprintf(txt);
            else
                notify(this.FitLike, 'ThrowMessage', EventMessage('txt',txt));
            end
        end % throwWrapMessage
        
        % THIS = SETMASK(THIS, SRC, EVENT) allows to mask data or to
        % propagate the event depending on the FitLike state. If FitLike is
        % available this function propagates the event. Else it modifies
        % the data by calling setMask() method from DataUnit container.
        function this = setMask(this, src, event)
            % check if FitLike is available
            if isa(this.FitLike,'FitLike')
                setMask(this.FitLike, src, event);
            else
                % Apply the mask on the data in DisplayManager
                if strcmp(event.Action,'SetMask')
                    % get boundaries
                    xmin = event.XRange(1); xmax = event.XRange(2);
                    ymin = event.YRange(1); ymax = event.YRange(2);
                    % define mask
                    for k = 1:numel(event.Data)
                        event.Data(k) = setMask(event.Data(k), event.idxZone(k),...
                            [xmin xmax], [ymin ymax]);
                    end
                elseif strcmp(event.Action,'ResetMask')
                    % reset mask
                    for k = 1:numel(event.Data)
                        event.Data(k) = setMask(event.Data(k), event.idxZone(k));
                    end
                end
            end
        end %setMask
        
        % THIS = MOVEMOUSE(THIS) is fired when the mouse is moved on the 
        % figure. It then fires the MOVEMOUSE() method of the selected tab.
        % Usually it is used to return the position of the mouse on the
        % axis (X/Y position).
        % Note (03/2019): This function is fired multiple times possibly
        % without any good reason (if no axis is available at the mouse
        % position) but I didnt find a way to do this directly in the
        % children tab.
        function moveMouse(this)
            % check the selected tab
            tab = this.gui.tab.SelectedTab;
            % call the mouse callback fonction of this tab
            moveMouse(tab.Children);
            % pause
            pause(0.001);
        end
    end
end

