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
        function this = Dispersion(varargin)
            this = this@DataUnit(varargin{:});                    
        end %Dispersion
    end
    
    methods            
        % assign a processing function to the data object (over rides the
        % metaclass function to add initial parameter estimation when
        % loading the processing object)
        function this = assignProcessingFunction(this,processObj)
            % assign the process object to each dataset
            this = arrayfun(@(s)setfield(s,'processingMethod',processObj),this,'UniformOutput',0); %#ok<*SFLD>
            this = [this{:}];
            % then evaluate the initial parameters if a method is provided
            this = arrayfun(@(s)evaluateStartPoint(s.processingMethod,s.x,s.y),this,'UniformOutput',0); %#ok<*SFLD>
            this = [this{:}];
        end
        
        % define dimension indexing for data selection
        function dim = getDim(this, idxZone)
            % check input
            if isnan(idxZone)
                dim = {1:numel(this.y)};
            else
                dim = {idxZone};
            end
        end %getDim
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Can be simplify by using smart dimension indexing! [Manu]
        % These functions should be set in DataUnit whereas only dimension
        % access should be set here!
        
%         % Set mask according to a [x,y] range. the new mask is added to the
%         % current mask. Can be called with only two input to reset the mask.
%         function this = setMask(this, idxZone, xrange, yrange)
%             % check input
%             if isnan(idxZone)
%                 if nargin > 3
%                     this.mask = this.mask &...
%                         ~((xrange(1) < this.x & this.x < xrange(2))&...
%                           (yrange(1) < this.y & this.y < yrange(2)));
%                 else
%                     this.mask = true(size(this.mask));
%                 end
%             else
%                 if nargin > 3
%                     this.mask(idxZone) = this.mask(idxZone) &...
%                         ~((xrange(1) < this.x(idxZone) & this.x(idxZone) < xrange(2))&...
%                           (yrange(1) < this.y(idxZone) & this.y(idxZone) < yrange(2)));
%                 else
%                     this.mask(idxZone) = true;
%                 end
%             end
%         end %setMask
        
%         % get the dispersion data
%         function [x,y,dy,mask] = getData(this, idxZone)
%             % check input
%             if ~isnan(idxZone)
%                x = this.x(idxZone); y = this.y(idxZone); dy = this.dy(idxZone);
%                mask = this.mask(idxZone);
%             else
%                x = this.x; y = this.y; dy = this.dy; mask = this.mask;
%             end
%         end %getData
        
        % get the dispersion fit data
        function [xfit, yfit] = getFit(this, idxZone, xfit)
            % check if fitobj
            if isempty(this.processingMethod)
                xfit = []; yfit = [];
                return
            end
            % check input
            if ~isnan(idxZone)
               x = this.x(idxZone); mask = this.mask(idxZone);
               xfit = x(mask);
               yfit = evaluate(this.processingMethod, xfit);
            else
                if isempty(xfit)
                    % resample x data
                    x = sort(this.x(this.mask));
                    x_add = diff(x/2); % get the interval between x pts
                    x = sort([x; x(1:end-1)+x_add]); %add it
                    x_add = diff(x/2); % get the interval between x pts
                    xfit = sort([x; x(1:end-1)+x_add]); %add it
                end
                % get y-values
                yfit = evaluate(this.processingMethod, xfit);
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
                        leg = sprintf('%s', this.relaxObj.filename);
                    else
                        leg = sprintf('Zone %d: %s', idxZone, this.relaxObj.filename);
                    end
                    
                    if extend
                        leg = [leg,' (',this.displayName,')'];
                    end
                case 'Fit'
                    leg = sprintf('%s (r² = %.3f)',...
                            this.processingMethod.model.modelName,...
                            this.processingMethod.model.gof.rsquare);
                    
                    if extend == -1
                        return
                    end
                        
                    if isnan(idxZone)
                        leg = sprintf('%s: %s', leg, this.relaxObj.filename);
                    else
                        leg = sprintf('%s: Zone %d - %s', leg, idxZone, this.relaxObj.filename);
                    end
                     
                    if extend
                        leg = [leg,' (',this.displayName,')'];
                    end
                case 'Mask'
                    leg = [];
            end
        end %getLegend
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end    
end