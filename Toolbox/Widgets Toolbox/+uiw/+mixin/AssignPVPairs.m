classdef (Abstract) AssignPVPairs < handle
    % AssignPVPairs - Mixin to assign PV pairs to public properties
    % ---------------------------------------------------------------------
    % This mixin class provides a method to assign PV pairs to populate
    % public properties of a handle object. This is typically performed in
    % a constructor.
    %
    % The class must inherit this object to access the method. Call the
    % protected method like this to assign properties:
    %
    %     % Assign PV pairs to properties
    %     obj.assignPVPairs(varargin{:});
    %
    %       or
    %
    %     % Assign PV pairs to properties and return non-matches
    %     UnmatchedPairs = obj.assignPVPairs(varargin{:});
    %
    % Methods of uiw.abstract.AssignPVPairs:
    %
    %   varargout = assignPVPairs(obj,varargin) - assigns the
    %   property-value pairs to matching properties of the object
    %
    
    % Copyright 2015-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 55 $  $Date: 2018-02-27 13:41:05 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Protected Methods
    
    methods (Access=protected)
        
        function varargout = assignPVPairs(obj,varargin)
            % Assign the specified property-value pairs
            
            % Get a list of public properties
            metaObj = metaclass(obj);
            isSettableProp = strcmp({metaObj.PropertyList.SetAccess}','public');
            SettableProps = metaObj.PropertyList(isSettableProp);
            PublicPropNames = {SettableProps.Name}';
            HasDefault = [SettableProps.HasDefault]';
            DefaultValues = repmat({[]},size(HasDefault));
            DefaultValues(HasDefault) = {SettableProps(HasDefault).DefaultValue};
            
            % Create a parser for all public properties
            p = inputParser;
            if nargout
                p.KeepUnmatched = true;
            end
            for pIdx = 1:numel(PublicPropNames)
                p.addParameter(PublicPropNames{pIdx}, DefaultValues{pIdx});
            end
            
            % Parse the P-V pairs
            p.parse(varargin{:});
            
            % Set just the parameters the user passed in
            ParamNamesToSet = varargin(1:2:end);
            ParamsInResults = fieldnames(p.Results);
            
            % Assign properties
            for ThisName = ParamNamesToSet
                if any(strcmpi(ThisName,ParamsInResults)) && ...
                        ~isequal(obj.(ThisName{1}), p.Results.(ThisName{1}))
                    obj.(ThisName{1}) = p.Results.(ThisName{1});
                end
            end
            
            % Return unmatched pairs
            if nargout
                varargout{1} = p.Unmatched;
            end
            
        end %function
        
    end %methods
        
        
        %% Static, Sealed, Protected Methods
    methods (Static, Sealed, Access=protected)
        
        function  [splitArgs,remArgs] = splitArgs(argnames,varargin)
            % Separate specified P-V arguments from the rest
            
            narginchk(1,inf) ;
            splitArgs = {};
            remArgs = {};
            
            if nargin>1
                props = varargin(1:2:end);
                values = varargin(2:2:end);
                if ( numel( props ) ~= numel( values ) ) || any( ~cellfun( @ischar, props ) )
                    error( 'uiw:utility:splitArgs:BadSyntax', 'Arguments must be supplied as property-value pairs' );
                end
                ToSplit = ismember(props,argnames);
                ToSplit = reshape([ToSplit; ToSplit],1,[]);
                splitArgs = varargin(ToSplit);
                remArgs = varargin(~ToSplit);
            end
            
        end %function
        
    end %methods
        
    
end %classdef