classdef Zone < DataUnit
    %
    % ZONE is a container for "zone" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DISPERSION, DATAUNIT, RELAXOBJ
       
    properties 
        % See DataUnit for other properties
    end
    
    methods (Access = public)
        % Constructor
        % Zone can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Zone(varargin)
            obj = obj@DataUnit(varargin{:});
        end %Zone
        
        function x = getDispAxis(self)
            x = arrayfun(@(x) getDispAxis(x.parameter),self,'UniformOutput',0);
        end
        
        % merge two datasets together
        function selfMerged = merge(self)
            n = ndims(self(1).x); % always concatenate over the last dimension (evolution fields), the others should have the same number of inputs
            selfMerged = copy(self(1));
            selfMerged.x = cat(n,self(1).x, self(2).x);
            selfMerged.y = cat(n,self(1).y, self(2).y);
            selfMerged.dy = cat(n,self(1).dy, self(2).dy);
            selfMerged.mask = cat(n,self(1).mask, self(2).mask);
            selfMerged.parameter = merge(self(1).parameter,self(2).parameter);
            if length(self) > 2
                selfMerged = merge([selfMerged self(3:end)]);
            end
        end
                       
        % evaluate the fit function if present, for display purposes
        function y = evaluate(self, zoneIndex, x)
            model = self.parameter.paramList.modelHandle{zoneIndex};
            y = model(self.parameter.paramList.coeff(zoneIndex,:), x);
        end
        
        % Set mask according to a [x,y] range. the new mask is added to the
        % current mask. Can be called with only two input to reset the mask.
        function obj = setMask(obj, idxZone, xrange, yrange)
            % check input
            if isnan(idxZone)
                if nargin > 3
                    obj.mask = obj.mask &...
                        ~((xrange(1) < obj.x & obj.x < xrange(2))&...
                          (yrange(1) < obj.y & obj.y < yrange(2)));
                else
                    obj.mask = true(size(obj.mask));
                end
            else
                if nargin > 3
                    obj.mask(:,idxZone) = obj.mask(:,idxZone) &...
                        ~((xrange(1) < obj.x(:,idxZone) & obj.x(:,idxZone) < xrange(2))&...
                          (yrange(1) < obj.y(:,idxZone) & obj.y(:,idxZone) < yrange(2)));
                else
                    obj.mask(:,idxZone) = true(size(obj.mask(:,idxZone)));
                end
            end
        end %setMask
        
        % get the dispersion data
        function [x,y,dy,mask] = getData(obj, idxZone)
            % check input
            if ~isnan(idxZone)
               x = obj.x(:,idxZone); y = obj.y(:,idxZone);
               dy = obj.dy(:,idxZone); mask = obj.mask(:,idxZone);
            else
               % error ?
            end
        end %getData
        
        % get the dispersion fit data
        function [xfit, yfit] = getFit(obj, idxZone, xfit)
            % check if fitobj
            if isempty(obj.processingMethod)
                xfit = []; yfit = [];
                return
            end
            % check input
            if ~isnan(idxZone)
                if isempty(xfit)
                    x = sort(obj.x(obj.mask(:,idxZone),idxZone));
                    % get the interval between x pts
                    x_add = diff(x/2);
                    x = sort([x; x(1:end-1)+x_add]); %add it
                    x_add = diff(x/2); % get the interval between x pts
                    xfit = sort([x; x(1:end-1)+x_add]); %add it
                end
                yfit = evaluate(obj, idxZone, xfit);
            else
                % error ?
            end
        end %getFit
        
        % get the legend for dispersion data. 
        % plotType: {'Data','Mask','...}
        % extend is a logical to generate an extended version of the legend
        % included the displayName (filename (displayName)). Can be useful
        % when several plot coming from the same file are displayed.
        function leg = getLegend(obj, idxZone, plotType, extend)
            % switch according to the input
            switch plotType
                case 'Data'
                    if isnan(idxZone)
                        % error ?
                    else
                        leg = sprintf('Zone %d: %s', idxZone, obj.filename);
                    end
                    
                    if extend
                        leg = [leg,' (',obj.displayName,')'];
                    end
                case 'Fit'
                    leg = sprintf('%s', obj.processingMethod.functionName);
                    
                    if isnan(idxZone)
                        % error ?
                    else
                        leg = sprintf('%s  (r² = %.3f)',leg,...
                            obj.parameter.paramList.gof{idxZone}.rsquare);
                                                                                     
                        if extend                        
                            leg = sprintf('%s: Zone %d - %s', leg, idxZone, obj.filename);
                        end
                    end
                case 'Mask'
                    leg = [];
            end
        end %getLegend
    end % methods
   
    methods % plotting methods
%          % plot dispersion data
%         % varargin: color, style, marker, markersize
%         function h = plotData(obj, zoneIndex, axe, color, style, mrk, mrksize)
%             % plot
%             h = errorbar(axe,...
%                     obj.x(obj.mask(:, zoneIndex), zoneIndex),...
%                     obj.y(obj.mask(:, zoneIndex), zoneIndex),...
%                     [],...
%                     'DisplayName', obj.filename,...
%                     'Color',color,...
%                     'LineStyle',style,...
%                     'Marker',mrk,...
%                     'MarkerSize',mrksize,...
%                     'MarkerFaceColor','auto',...
%                     'Tag',[obj.fileID,'@',num2str(zoneIndex)]); 
%         end %plotData
%         
%         % Add error to an existing errorbar. If multiple, should be in the
%         % same order.
%         function h = addError(obj, zoneIndex, h)
%              set(h,...
%                  'YNegativeDelta',-obj.dy(obj.mask(:, zoneIndex), zoneIndex),...
%                  'YPositiveDelta',obj.dy(obj.mask(:, zoneIndex), zoneIndex));
%         end %addError
%         
%         % Plot Masked data
%         % varargin: color, marker, markersize
%         function h = plotMaskedData(obj, zoneIndex, axe, color, mrk, mrksize)
%             % check if data to plot
%             if ~isempty(obj.y(~obj.mask))
%                 % plot
%                 h = scatter(axe,...
%                     obj.x(~obj.mask(:, zoneIndex), zoneIndex),...
%                     obj.y(~obj.mask(:, zoneIndex), zoneIndex),...
%                     'MarkerEdgeColor', color,...
%                     'Marker', mrk,...
%                     'SizeData',mrksize,...
%                     'MarkerFaceColor','auto',...
%                     'Tag',[obj.fileID,'@',num2str(zoneIndex)]);
%                 % remove this plot from legend
%                 set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%             end
%         end
%         
%         % Plot Fit
%         % varargin: color, style, marker
%         function plotFit(obj, zoneIndex, axe, color, style, mrk)
%             % check if possible to plot fit
%             if ~isempty(obj.processingMethod)
%                 % get x-values and increase its  number
%                 x = sort(obj.x(obj.mask(:, zoneIndex), zoneIndex));
%                 x_add = diff(x/2); % get the interval between x pts
%                 x_fit = sort([x; x(1:end-1)+x_add]); %add it
% 
%                 % get y-values
%                 y_fit = evaluate(obj, zoneIndex, x_fit);
% 
%                 % change the displayed name and add the rsquare
%                 fitName = sprintf('%s: %s (R^2 = %.3f)',...
%                     obj.processingMethod.functionName, obj.filename,...
%                     obj.parameter.paramList.gof{zoneIndex}.rsquare);
% 
%                 % plot
%                 plot(axe, x_fit, y_fit,...
%                     'DisplayName', fitName,...
%                     'Color', color,...
%                     'LineStyle', style,...
%                     'Marker', mrk,...
%                     'Tag',[obj.fileID,'@',num2str(zoneIndex)]); 
%             end
%         end 
    end
end