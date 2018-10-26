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
        
        % plot dispersion data
        % varargin: color, style, marker, markersize
        function h = plotData(obj, axe, color, style, mrk, mrksize)
            % plot
            h = errorbar(axe,...
                    obj.x(obj.mask),...
                    obj.y(obj.mask),...
                    [],...
                    'DisplayName', obj.filename,...
                    'Color',color,...
                    'LineStyle',style,...
                    'Marker',mrk,...
                    'MarkerSize',mrksize,...
                    'MarkerFaceColor','auto',...
                    'Tag',obj.fileID); 
        end %plotData
        
        % Add error to an existing errorbar. If multiple, should be in the
        % same order.
        function h = addError(obj, h)
             set(h,...
                 'YNegativeDelta',-obj.dy(obj.mask),...
                 'YPositiveDelta',obj.dy(obj.mask));
        end %addError
        
        % Plot Masked data
        % varargin: color, marker, markersize
        function h = plotMaskedData(obj, axe, color, mrk, mrksize)
            % check if data to plot
            if ~isempty(obj.y(~obj.mask))
                % plot
                h = scatter(axe,...
                    obj.x(~obj.mask),...
                    obj.y(~obj.mask),...
                    'MarkerEdgeColor', color,...
                    'Marker', mrk,...
                    'SizeData',mrksize,...
                    'MarkerFaceColor','auto',...
                    'Tag',obj.fileID);
                % remove this plot from legend
                set(get(get(h,'Annotation'),'LegendInformation'),'IconDisplayStyle','off');
            end
        end
        
        % Plot Fit
        % varargin: color, style, marker
        function plotFit(obj, axe, color, style, mrk)
                % check if possible to plot fit
                if ~isempty(obj.processingMethod)
                    % get x-values and increase its  number
                    x = sort(obj.x(obj.mask));
                    x_add = diff(x/2); % get the interval between x pts
                    x_fit = sort([x; x(1:end-1)+x_add]); %add it

                    % get y-values
                    y_fit = evaluate(obj.processingMethod, x_fit);

                    % change the displayed name and add the rsquare
                    fitName = sprintf('%s: %s (R^2 = %.3f)',...
                        obj.processingMethod.model.modelName, obj.filename,...
                        obj.processingMethod.model.gof.rsquare);

                    % plot
                    plot(axe, x_fit, y_fit,...
                        'DisplayName', fitName,...
                        'Color', color,...
                        'LineStyle', style,...
                        'Marker', mrk,...
                        'Tag',obj.fileID); 
                end
        end 
    end    
end