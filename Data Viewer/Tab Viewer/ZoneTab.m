classdef ZoneTab < DispersionTab
    %
    % Class that design containers for zone data
    %
    % See also DISPERSIONTAB, DISPLAYTAB
    
    % Note: Plotting data requires lot of time, especially because
    % we need to dynamically update the legend (50% maybe) and the axis
    % (10%). Could be improved.
    
    properties
        idxZone
    end
    
    methods
        % overwrite addplot function to select zone index
        function this = addPlot(this, hData, varargin) 
                        
        end %addPlot
    end
    
end

