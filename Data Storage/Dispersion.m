classdef Dispersion < DataUnit
    %
    % DISPERSION is a container for "dispersion" data from Stelar SPINMASTER
    %
    % SEE ALSO BLOC, ZONE, DATAUNIT
    
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
        
        % get x-values        
        function x = getXData(this)
            % get data
            x = arrayfun(@(x) getDispAxis(x),this.relaxObj.parameter,'UniformOutput',0);
            % cat cell array to have NBLK x BRLX matrix
            x = [x{:}];
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
        
        % evaluate the fit function if present, for display purposes
        function y = evaluate(this, x)
            if isempty(this.processingMethod); y = []; return; end
            
            model = this.processingMethod.modelHandle;
            x = [num2cell(this.processingMethod.bestValue{1}), {x}];
            y = model(x{:});
        end
        
        % get the dispersion fit data
        function [xfit, yfit] = getFit(this, idxZone, xfit)
            % check input
            if ~isnan(idxZone)
               x = this.x(idxZone); mask = this.mask(idxZone);
               xfit = x(mask);
               yfit = evaluate(this, xfit);
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
                yfit = evaluate(this, xfit);
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
                            this.processingMethod.modelName,...
                            this.processingMethod.gof{1}.rsquare);
                    
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