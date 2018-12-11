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
        
%         % overwrite addplot function to select zone index
%         function [this, tf] = addPlot(this, hData, idxZone) 
%             % check input
%             if ~isa(hData,'Zone')
%                 tf = 1;
%                 return
%             end
%             % check if duplicates
%             if isempty(this.hData)
%                 tf = 0;
%             else
%                 if ~all(strcmp(getZoneID(this),...
%                         strcat(hData.fileID,'@',num2str(idxZone))) == 0)
%                    tf = 1; 
%                    return
%                 else 
%                    tf = 0;
%                 end
%             end
%             % append data
%             this.hData = [this.hData hData];
%             this.idxZone = [this.idxZone idxZone];
%             
%             % add listener 
%             addlistener(hData,'DataHasChanged',@(src, event) updateData(this, src));
%             addlistener(hData,'FileDeletion', @(src, event) deletePlot(this, hData));
%             
%             % + set plot specification
%             getPlotSpec(this, hData);
%             
%             % + data
%             showData(this);
% 
%             % + fit
%             showFit(this);
%             
%             % + residuals
%             showResidual(this);
% 
%             % + legend
%             showLegend(this);               
%         end %addPlot
%         
%         % overwrite deleteplot function to delete zone
%         function this = deletePlot(this, hData, idxZone)
%             % get all plot corresponding to the hData and delete them
%             hAxe = findobj(this, 'Type', 'axes');
%             % check input          
%             if isempty(idxZone)
%                 % remove all zone belonging to hData: contain the fileID!
%                 % loop over axis
%                 for k = 1:numel(hAxe)
%                     hPlot = findobj(hAxe(k).Children, '-regexp','Tag', hData.fileID);
%                     delete(hPlot);
%                 end
%                 drawnow;
%                 tf = strcmp({this.hData.fileID}, hData.fileID);  
%             else
%                 % remove only one zone
%                 zoneID = [hData.fileID,'@',num2str(idxZone)];
%                 % loop over axis
%                 for k = 1:numel(hAxe)
%                     hPlot = findobj(hAxe(k).Children, 'Tag', zoneID);
%                     delete(hPlot);
%                 end
%                 drawnow;
%                 tf = strcmp(getZoneID(this), zoneID);  
%             end    
%             % reset legend
%             showLegend(this);
%             % remove handle
%             this.hData = this.hData(~tf);
%             this.PlotSpec = this.PlotSpec(~tf);
%             this.idxZone = this.idxZone(~tf);
%         end %deletePlot
%         
%         % overwrite the update data method
%         function this = updateData(this, src)
%             % loop over the file and reset data
%             for k = 1:numel(src)
%                % find plot containing this ID
%                hPlot = findobj(this.axe.Children, '-regexp','Tag', src(k).fileID);
%                % loop over the zone
%                zoneID = unique({hPlot.Tag});
%                
%                for i = 1:numel(zoneID)
%                    % get zone index
%                    zoneIdx = strsplit(zoneID{i});
%                    zoneIdx = num2str(zoneIdx{end});
%                    
%                    % reset data
%                    hData = findobj(hPlot,'Type','ErrorBar','-and','Tag',zoneID{i});
%                    if ~isempty(hData)
%                        % update data
%                        hData.XData = src(k).x(src(k).mask(:,zoneIdx), zoneIdx);
%                        hData.YData = src(k).y(src(k).mask(:,zoneIdx), zoneIdx);
%                        % add error if needed
%                        if ~isempty(hData.YNegativeDelta)
%                             hData.YNegativeDelta = -src(k).dy(src(k).mask(:,zoneIdx), zoneIdx);
%                             hData.YPositiveDelta = +src(k).dy(src(k).mask(:,zoneIdx), zoneIdx);
%                        end
%                        % clear if needed
%                        if isempty(hData.YData)
%                            delete(hData); 
%                        end
%                    end
% 
%                    % reset mask
%                    hMask = findobj(hPlot,'Type','Scatter','-and','Tag',zoneID{i});
%                    if ~isempty(hMask)
%                         % update data
%                         hMask.XData = src(k).x(~src(k).mask(:,zoneIdx), zoneIdx);
%                         hMask.YData = src(k).y(~src(k).mask(:,zoneIdx), zoneIdx);
%                         % clear if needed
%                         if isempty(hMask.YData)
%                            delete(hMask); 
%                         end
%                    end
% 
%                    % reset fit
%                    hFit = findobj(hPlot,'Type','Line','-and','Tag',zoneID{i});
%                    if ~isempty(hFit) && ~isempty(src(k).processingMethod)
%                         % update data
%                         hFit.XData = sort(src(k).x(src(k).mask(:,zoneIdx), zoneIdx));
%                         hFit.YData = evaluate(src(k).processingMethod, zoneIdx, hFit.XData);
%                         % clear if needed
%                         if isempty(hFit.YData)
%                            delete(hFit); 
%                         end
%                    end
% 
%                    % reset residuals
%                    if ~isempty(this.axeres)
%                         hResidual = findobj(this.axeres.Children, 'Tag', zoneID{i});
%                         if ~isempty(hResidual)
%                            hResidual.XData = hData.XData;
%                            hResidual.YData = hFit.YData - hData.YData; 
%                            % clear if needed
%                            if isempty(hResidual.YData)
%                                 delete(hResidual); 
%                            end
%                         end
%                    end
%                end %zone loop
%             end %file loop
%             drawnow;
%         end %updateData
%     end
%     
%     % Overwrite some responce to the display options callback
%     methods 
%         function this = showData(this)
%             % check input
%             if this.optsButton.DataCheckButton.Value
%                 % get ID
%                 zoneID = getZoneID(this);
%                 for k = 1:numel(this.hData)
%                     % check plot existence
%                     hPlot = findobj(this.axe.Children,'Type','ErrorBar','Tag', zoneID{k});
%                     if isempty(hPlot)
%                         plotData(this.hData(k), this.idxZone(k), this.axe,...
%                             this.PlotSpec(k).Color, this.DataLineStyle,...
%                             this.PlotSpec(k).DataMarker, this.DataMarkerSize);
%                     end
%                 end
%                 drawnow;
%                 showError(this);
%                 showMask(this);
%             else
%                 delete(findobj(this.axe.Children,'Type','ErrorBar'));
%                 delete(findobj(this.axe.Children,'Type','Scatter'));
%                 drawnow;
%             end
%             showLegend(this);
%         end %showData
%         
%         function this = showError(this)
%             % check input
%             if this.optsButton.ErrorCheckButton.Value
%                  % get ID
%                 zoneID = getZoneID(this);
%                 for k = 1:numel(this.hData)
%                     % check plot existence
%                     hPlot = findobj(this.axe.Children,'Type','ErrorBar','Tag',zoneID{k});
%                     if ~isempty(hPlot)
%                         addError(this.hData(k), this.idxZone(k), hPlot);
%                     end
%                 end
%             else
%                 set(findobj(this.axe.Children,'Type','ErrorBar'),...
%                     'YNegativeDelta',[],'YPositiveDelta',[]);
%             end
%             drawnow;
%         end %showError
%         
%         function this = showFit(this)
%             % check input
%             if this.optsButton.FitCheckButton.Value
%                 % get ID
%                 zoneID = getZoneID(this);
%                 for k = 1:numel(this.hData)
%                     % check plot existence
%                     hPlot = findobj(this.axe.Children, 'Type','Line', 'Tag', zoneID{k});
%                     if isempty(hPlot)
%                         plotFit(this.hData(k), this.idxZone(k), this.axe, this.PlotSpec(k).Color,...
%                             this.FitLineStyle, this.FitMarkerStyle);
%                     end
%                 end
%             else
%                 delete(findobj(this.axe.Children,'Type','Line'));
%             end
%             drawnow;
%             showLegend(this);
%         end %showFit
%         
%         function this = showMask(this)
%             % check input
%             if this.optsButton.MaskCheckButton.Value
%                 % get ID
%                 zoneID = getZoneID(this);
%                 for k = 1:numel(this.hData)
%                     % check plot existence
%                     hPlot = findobj(this.axe.Children, 'Type','Scatter', 'Tag', zoneID{k});
%                     if isempty(hPlot)
%                         plotMaskedData(this.hData(k), this.idxZone(k), this.axe,...
%                             this.PlotSpec(k).Color, this.DataMaskedMarkerStyle,...
%                             this.DataMarkerSize);
%                     end
%                 end
%             else
%                 delete(findobj(this.axe.Children,'Type','Scatter'));
%             end
%             drawnow;
%         end %showMask
%     end   
    end
end

