classdef ProcessTab < uix.Container & handle
    %
    % Class that define custom tab for ProcessingManager (Process settings)
    %
    
    % Presenter
    properties (Access = public)
        FitLike % handle to Presenter
    end
    
    % Boxes
    properties (Access = public)
       hbox % main horizontal box
       vbox % array of vertical box (function name, input type, output type,...
            % parameter, remove option)
    end
    
    % Tab
    properties (Access = public)
        TabTitle % tab title
    end
    
    methods
        % Constructor
        function this = ProcessTab(FitLike, tab, TabTitle)
            % Call superclass constructor
            this@uix.Container();
            % set Presenter & Title
            this.FitLike = FitLike;
            this.TabTitle = TabTitle;
            % Create the grid in the parent tab
            grid = uix.Grid('Parent',this,'Spacing', 2); 
            % set the Parent 
            this.Parent = tab;
            this.Parent.Title = this.TabTitle;            
            %---------------------------BUILDER---------------------------%
            % create main horyzontal box
            this.hbox = uix.HBox( 'Parent', grid, 'Padding', 2);
            % create vertical boxes (fonction name, input type, output
            % type, parameter, remove option)
            this.vbox(1) = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 20]);
            this.vbox(2) = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 20]);
            this.vbox(3) = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 20]);
            this.vbox(4) = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 20]);
            this.vbox(5) = uix.VButtonBox( 'Parent', this.hbox,...
                'VerticalAlignment','top','Padding', 2,...
                'ButtonSize',[150 20]);
            
            % create titles for the boxes
            uix.Text( 'Parent', this.vbox(1), 'String', 'Name',...
                'FontName','Helvetica','FontSize',9,'FontWeight','bold',...
                'HorizontalAlignment','center');
            uix.Text( 'Parent', this.vbox(2), 'String', 'Input',...
                'FontName','Helvetica','FontSize',9,'FontWeight','bold',...
                'HorizontalAlignment','center');
            uix.Text( 'Parent', this.vbox(3), 'String', 'Output',...
                'FontName','Helvetica','FontSize',9,'FontWeight','bold',...
                'HorizontalAlignment','center');
            uix.Text( 'Parent', this.vbox(4), 'String', 'Parameter',...
                'FontName','Helvetica','FontSize',9,'FontWeight','bold',...
                'HorizontalAlignment','center');
            uix.Empty( 'Parent', this.vbox(5));
            
            % add "add" pushbutton and empty space
            uicontrol( 'Parent', this.vbox(1),...
                       'Style','pushbutton',...
                       'FontSize',7,...
                       'String','Add Process');
            uix.Empty( 'Parent', this.vbox(2));
            uix.Empty( 'Parent', this.vbox(3));
            uix.Empty( 'Parent', this.vbox(4));
            uix.Empty( 'Parent', this.vbox(5));

            % set width
            this.hbox.Widths = [-1.5 -1 -1 -2 -0.5];                  
        end %DisplayTab
    end
    
end

