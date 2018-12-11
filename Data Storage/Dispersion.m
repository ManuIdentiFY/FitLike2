classdef Dispersion < DataUnit
    %
    % DISPERSION is a container for "dispersion" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DATAUNIT, DISPERSIONMODEL
    
    properties
        % See DataUnit for other properties
    end
    
    methods (Access = public)  
        % Constructor
        % Dispersion can build structure or array of structure. Input format is
        % equivalent to DataUnit: 
        % cell(s) input: array of structure
        % other: structure
        function obj = Dispersion(varargin)
            obj = obj@DataUnit(varargin{:});                    
        end %Dispersion
    end
    
    methods            
        % assign a processing function to the data object (over rides the
        % metaclass function to add initial parameter estimation when
        % loading the processing object)
        function self = assignProcessingFunction(self,processObj)
            % assign the process object to each dataset
            self = arrayfun(@(s)setfield(s,'processingMethod',processObj),self,'UniformOutput',0); %#ok<*SFLD>
            self = [self{:}];
            % then evaluate the initial parameters if a method is provided
            self = arrayfun(@(s)evaluateStartPoint(s.processingMethod,s.x,s.y),self,'UniformOutput',0); %#ok<*SFLD>
            self = [self{:}];
        end
        
        % TODO: Export data from Dispersion object in text file.
        function export(obj,method)
            
        end %export
        
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
                    obj.mask(idxZone) = obj.mask(idxZone) &...
                        ~((xrange(1) < obj.x(idxZone) & obj.x(idxZone) < xrange(2))&...
                          (yrange(1) < obj.y(idxZone) & obj.y(idxZone) < yrange(2)));
                else
                    obj.mask(idxZone) = true;
                end
            end
        end %setMask
        
        % get the dispersion data
        function [x,y,dy,mask] = getData(obj, idxZone)
            % check input
            if ~isnan(idxZone)
               x = obj.x(idxZone); y = obj.y(idxZone); dy = obj.dy(idxZone);
               mask = obj.mask(idxZone);
            else
               x = obj.x; y = obj.y; dy = obj.dy; mask = obj.mask;
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
               x = obj.x(idxZone); mask = obj.mask(idxZone);
               xfit = x(mask);
               yfit = evaluate(obj.processingMethod, xfit);
            else
                if isempty(xfit)
                    % resample x data
                    x = sort(obj.x(obj.mask));
                    x_add = diff(x/2); % get the interval between x pts
                    x = sort([x; x(1:end-1)+x_add]); %add it
                    x_add = diff(x/2); % get the interval between x pts
                    xfit = sort([x; x(1:end-1)+x_add]); %add it
                end
                % get y-values
                yfit = evaluate(obj.processingMethod, xfit);
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
                        leg = sprintf('%s', obj.filename);
                    else
                        leg = sprintf('Zone %d: %s', idxZone, obj.filename);
                    end
                    
                    if extend
                        leg = [leg,' (',obj.displayName,')'];
                    end
                case 'Fit'
                    leg = sprintf('%s (r² = %.3f)',...
                            obj.processingMethod.model.modelName,...
                            obj.processingMethod.model.gof.rsquare);
                    
                    if extend == -1
                        return
                    end
                        
                    if isnan(idxZone)
                        leg = sprintf('%s: %s', leg, obj.filename);
                    else
                        leg = sprintf('%s: Zone %d - %s', leg, idxZone, obj.filename);
                    end
                     
                    if extend
                        leg = [leg,' (',obj.displayName,')'];
                    end
                case 'Mask'
                    leg = [];
            end
        end %getLegend
%         
%         % plot dispersion data
%         % varargin: color, style, marker, markersize
%         function h = plotData(obj, axe, color, style, mrk, mrksize)
%             % plot
%             h = errorbar(axe,...
%                     obj.x(obj.mask),...
%                     obj.y(obj.mask),...
%                     [],...
%                     'DisplayName', obj.filename,...
%                     'Color',color,...
%                     'LineStyle',style,...
%                     'Marker',mrk,...
%                     'MarkerSize',mrksize,...
%                     'MarkerFaceColor','auto',...
%                     'Tag',obj.fileID); 
%         end %plotData
%         
%         % Add error to an existing errorbar. If multiple, should be in the
%         % same order.
%         function h = addError(obj, h)
%              set(h,...
%                  'YNegativeDelta',-obj.dy(obj.mask),...
%                  'YPositiveDelta',obj.dy(obj.mask));
%         end %addError
%         
%         % Plot Masked data
%         % varargin: color, marker, markersize
%         function h = plotMaskedData(obj, axe, color, mrk, mrksize)
%             % check if data to plot
%             if ~isempty(obj.y(~obj.mask))
%                 % plot
%                 h = scatter(axe,...
%                     obj.x(~obj.mask),...
%                     obj.y(~obj.mask),...
%                     'MarkerEdgeColor', color,...
%                     'Marker', mrk,...
%                     'SizeData',mrksize,...
%                     'MarkerFaceColor','auto',...
%                     'Tag',obj.fileID);
%                 % remove this plot from legend
%                 set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
%             end
%         end
%         
%         % Plot Fit
%         % varargin: color, style, marker
%         function plotFit(obj, axe, color, style, mrk)
%                 % check if possible to plot fit
%                 if ~isempty(obj.processingMethod)
%                     % get x-values and increase its  number
%                     x = sort(obj.x(obj.mask));
%                     x_add = diff(x/2); % get the interval between x pts
%                     x_fit = sort([x; x(1:end-1)+x_add]); %add it
% 
%                     % get y-values
%                     y_fit = evaluate(obj.processingMethod, x_fit);
% 
%                     % change the displayed name and add the rsquare
%                     fitName = sprintf('%s: %s (R^2 = %.3f)',...
%                         obj.processingMethod.model.modelName, obj.filename,...
%                         obj.processingMethod.model.gof.rsquare);
% 
%                     % plot
%                     plot(axe, x_fit, y_fit,...
%                         'DisplayName', fitName,...
%                         'Color', color,...
%                         'LineStyle', style,...
%                         'Marker', mrk,...
%                         'Tag',obj.fileID); 
%                 end
%         end 
    end    
end