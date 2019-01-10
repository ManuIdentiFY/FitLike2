classdef ZoneTab < DispersionTab
    %
    % Class that design containers for zone data
    %
    % See also DISPERSIONTAB, DISPLAYTAB
    
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    % Note2: the hData input should be improved to be: one object = one
    % plot. A possibility could be the creation of a subzone object
    % containing all the information for only one zone.
    %
    % M.Petit - 11/2018
    % manuel.petit@inserm.fr
    
    properties

    end
    
    methods
        % constructor
        function this = ZoneTab(FitLike, tab)
            % call the superclass constructor and set the Presenter
            this = this@DispersionTab(FitLike, tab);
            % update title and type
            this.Parent.Title = 'Zone';
            this.inputType = 'Zone';
            % change default X/Y Scale
            this.optsButton.XAxisPopup.Value = 1;
            this.optsButton.YAxisPopup.Value = 1;
            this.axe.XScale = this.optsButton.XAxisPopup.String{this.optsButton.XAxisPopup.Value};
            this.axe.YScale = this.optsButton.YAxisPopup.String{this.optsButton.YAxisPopup.Value}; 
        end % ZoneTab  
    end
end

