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
        function y = evaluate(self,zoneIndex,x)
            model = self.parameter.paramList.modelHandle{zoneIndex};
            y = model(self.parameter.paramList.coeff(zoneIndex,:), x);
        end
        
        % create a zone subset according to a particular zone and link both
        % objects in case where original object is modified
        function selfSub = subzone(self, zoneIndex)
            % create a copy of the obj
            selfSub = copy(self);
            % select data according to zoneIndex
            selfSub.x = selfSub.x(:,zoneIndex{1});
            selfSub.y = selfSub.y(:,zoneIndex{1});
            selfSub.dy = selfSub.dy(:,zoneIndex{1});
            selfSub.mask = selfSub.mask(:,zoneIndex{1});
            % remove children and parent to avoir errors
            remove(selfSub.children);
            remove(selfSub.parent);
            % add the zoneIndex information in userdata and fileID
            selfSub.fileID = [self.fileID, '@', num2str(zoneIndex{1})];
        end %subzone
    end % methods
   
    methods % plotting methods
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