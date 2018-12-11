classdef EmptyTab2 < DisplayTab
    %
    % Empty container for DisplayManager
    %
    % SEE ALSO DISPERSIONTAB, DISPLAYMANAGER
    
    % set the abstract property
    properties
        
    end
    
    methods
        % Constructor
        function this = EmptyTab2(FitLike, tab)
            % call the superclass constructor
            this = this@DisplayTab(FitLike, tab);
            % set the name of the subtab 
            this.Parent.Title = 'Untitled';
            % set the axis visibility to "off"
            this.axe.Visible = 'off';
        end %EmptyTab
    end
    
    % adding dummy methods
    methods (Access = public)      
        function moveMouse(this)
            return
        end
        
        function 
    end
    
end

