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
        function this = Zone(varargin)
            this = this@DataUnit(varargin{:});
        end %Zone
        
        function x = getDispAxis(this)
            x = arrayfun(@(x) getDispAxis(x.parameter),this,'UniformOutput',0);
        end
        
%         % merge two datasets together
%         function selfMerged = merge(self)
%             n = ndims(self(1).x); % always concatenate over the last dimension (evolution fields), the others should have the same number of inputs
%             selfMerged = copy(self(1));
%             selfMerged.x = cat(n,self(1).x, self(2).x);
%             selfMerged.y = cat(n,self(1).y, self(2).y);
%             selfMerged.dy = cat(n,self(1).dy, self(2).dy);
%             selfMerged.mask = cat(n,self(1).mask, self(2).mask);
%             selfMerged.parameter = merge(self(1).parameter,self(2).parameter);
%             if length(self) > 2
%                 selfMerged = merge([selfMerged self(3:end)]);
%             end
%         end
                       
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Need to be simplify to get fitting data from processing method
        % instead of parameter! [Manu]
        % Need to modify the Zone2Disp storage pipeline! [Manu]
        % evaluate the fit function if present, for display purposes
        function y = evaluate(this, zoneIndex, x)
            model = this.parameter.paramList.modelHandle{zoneIndex};
            y = model(this.parameter.paramList.coeff(zoneIndex,:), x);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Can be simplify by using smart dimension indexing! [Manu]
        % These functions should be set in DataUnit whereas only dimension
        % access should be set here!
        
        % Set mask according to a [x,y] range. the new mask is added to the
        % current mask. Can be called with only two input to reset the mask.
        function this = setMask(this, idxZone, xrange, yrange)
            % check input
            if isnan(idxZone)
                if nargin > 3
                    this.mask = this.mask &...
                        ~((xrange(1) < this.x & this.x < xrange(2))&...
                          (yrange(1) < this.y & this.y < yrange(2)));
                else
                    this.mask = true(size(this.mask));
                end
            else
                if nargin > 3
                    this.mask(:,idxZone) = this.mask(:,idxZone) &...
                        ~((xrange(1) < this.x(:,idxZone) & this.x(:,idxZone) < xrange(2))&...
                          (yrange(1) < this.y(:,idxZone) & this.y(:,idxZone) < yrange(2)));
                else
                    this.mask(:,idxZone) = true(size(this.mask(:,idxZone)));
                end
            end
        end %setMask
        
        % get the dispersion data
        function [x,y,dy,mask] = getData(this, idxZone)
            % check input
            if ~isnan(idxZone)
               x = this.x(:,idxZone); y = this.y(:,idxZone);
               dy = this.dy(:,idxZone); mask = this.mask(:,idxZone);
            else
               % error ?
            end
        end %getData
        
        % get the dispersion fit data
        function [xfit, yfit] = getFit(this, idxZone, xfit)
            % check if fitobj
            if isempty(this.processingMethod)
                xfit = []; yfit = [];
                return
            end
            % check input
            if ~isnan(idxZone)
                if isempty(xfit)
                    x = sort(this.x(this.mask(:,idxZone),idxZone));
                    % get the interval between x pts
                    x_add = diff(x/2);
                    x = sort([x; x(1:end-1)+x_add]); %add it
                    x_add = diff(x/2); % get the interval between x pts
                    xfit = sort([x; x(1:end-1)+x_add]); %add it
                end
                yfit = evaluate(this, idxZone, xfit);
            else
                % error ?
            end
        end %getFit
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Need to be modify to get filename from RelaxObj wrapper! [Manu]
        % Can probably be simplify to set getLegend in RelaxObj directly!
        
        % get the legend for dispersion data. 
        % plotType: {'Data','Mask','...}
        % extend is a logical to generate an extended version of the legend
        % included the displayName (filename (displayName)). Can be useful
        % when several plot coming from the same file are displayed.
        function leg = getLegend(this, idxZone, plotType, extend)
            % switch according to the input
            switch plotType
                case 'Data'
                    if isnan(idxZone)
                        % error ?
                    else
                        leg = sprintf('Zone %d: %s', idxZone, this.relaxObj.filename);
                    end
                    
                    if extend
                        leg = [leg,' (',this.displayName,')'];
                    end
                case 'Fit'
                    leg = sprintf('%s', this.processingMethod.functionName);
                    
                    if isnan(idxZone)
                        % error ?
                    else
                        leg = sprintf('%s  (r� = %.3f)',leg,...
                            this.parameter.paramList.gof{idxZone}.rsquare);
                                                                                     
                        if extend                        
                            leg = sprintf('%s: Zone %d - %s', leg, idxZone, this.relaxObj.filename);
                        end
                    end
                case 'Mask'
                    leg = [];
            end
        end %getLegend
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end % methods
end