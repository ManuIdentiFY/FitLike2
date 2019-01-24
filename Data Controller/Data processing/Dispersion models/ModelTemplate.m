classdef ModelTemplate < DataUnit2DataUnit & DataFit
    % Class template for models of NMRD profiles. To use it:
    % - Replace 'ModelTemplate' by the name of the model you wish to
    %   implement (type control+f and replace). Do not use space or special
    %   characters for the class name.
    % - Save the file using the same name as the model.
    % - Adapt the values of the properties to your needs.
    %
    % That is it! Naming conventions for class objects are:
    % - start with a letter
    % - no special symbols or spaces. Underscores are allowed (_).
    %
    % Lionel Broche, University of Aberdeen, 08/02/2017
    % modified 23/08/2018 for compatibility with FitLike2
    
    % Definition rules for modelEquation:
    % - The model name obeys LaTeX formatting, subscripts can be obtained
    %   using the underscore _ and exponents using the sign ^
    %   examples: '^{14}N quadrupolar peaks' or 'Lorentzian_{low field}'
    % - Parameter names must follow the Matlab syntax for variables.
    % - Calculations are made using the Larmor frequency in Hz
    % - All the fields present in the section 'properties' MUST be defined
    % - The methods functions are not mandatory and may be deleted if not
    %   used (be careful not to delete the final 'end', though)
    
    % Do not change this.
    properties 
        functionName@char = 'DispersionModel'   % character string, name of the model, as appearing in the figure legend
        labelY@char = '';             % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {''};          % cell of strings, contain the legend associated with the data processed
    end 
    
    properties
        % start editing from here:

        % It is a good idea to put some explanations about the model,
        % and a reference to the publication where the model has been
        % derived. Use the comments for this (after the symbol %)

        modelName     = 'Dummy model';  % character string, name of the model as appearing in the figure legend or elsewhere. You may use spaces here.
        modelEquation = 'p*f + c';      % character string, equation that relates the Larmor frequency (Hz) to the parameters to R1 (s^{-1})
        variableName  = {'f'};          % List of characters, name of the variables appearing in the equation (usually the frequency). Only one-D support for now, but it may change in the future...
        parameterName = {'p', 'c'};     % List of characters, name of the parameters appearing in the equation in any order, but the order defined here is the same as for the boundary arrays below
        minValue      = [0    -10]      % array of values, minimum boundary for each parameter, respective to the order of parameterName
        maxValue      = [Inf   10]      % array of values, maximum boundary for each parameter, respective to the order of parameterName
        startPoint    = [5     0];      % array of values, starting point for each parameter, respective to the order of parameterName 
        isFixed       = [0     0];      % array of booleans, set to 1 if the corresponding parameter is fixed, 0 if they are to be optimised by the fit.
                    
        % The field 'visualisationFunction' allows plotting additional
        % functions related to the main equation. This may come handy
        % if the model equation contains several contributions that we
        % want to visualise independantly. Each contribution can be
        % written in a separate line of the cell array, using the same
        % parameter and variable names as in the main equation.
        visualisationFunction@cell = {};
    end

    methods
        % Here replace ModelTemplate by your classname
        function this = ModelTemplate
            % call superclass constructor
            this = this@DataUnit2DataUnit;
            this = this@DataFit;
        end
    end
    
    % additional methods are available if one wants to fine-tune the model.
    % These are available in the section 'methods' but can be safely
    % deleted if unnecessary.
    methods
        % The function below runs only once, when the model is assigned to
        % a data set. It allows generating a good start point, or setting
        % the boundaries correctly. The formula used to perform this has to
        % be written by the user, given the data values (x and y).
        % Accessing the properties is done by dot notation: 
        % self.startPoint provides the list of start parameters.
        function this = evaluateStartPoint(this,xdata,ydata)

        end
        
        % If you want to create an object with the fit result you can use
        % this function to decide which coefficients will become y-values
        % (idem for dy-values).
        function data = formatFitData(this, model)
            % Example:
            %data.y =  [model.bestValue(3), model.bestValue(5)];
            %data.dy = [model.errorBar(3),  model.errorBar(5)];
        end %formatFitData
    end

end % end of the class (do not delete)