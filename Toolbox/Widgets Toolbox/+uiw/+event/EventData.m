classdef EventData < event.EventData & dynamicprops & uiw.mixin.AssignPVPairs
    % EventData - Class for providing custom eventdata to listeners
    %
    % This class provides storage of event data to provide to a listener
    %
    % Syntax:
    %           obj = uiw.event.EventData()
    %           obj = uiw.event.EventData('Property','Value',...)
    %

    % Copyright 2017-2018 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 59 $  $Date: 2018-02-27 15:40:39 -0500 (Tue, 27 Feb 2018) $
    % ---------------------------------------------------------------------

    %% Properties
    properties
        Interaction char
    end %properties


    %% Constructor / destructor
    methods
        function obj = EventData(varargin)

            % Parse inputs
            remArgs = assignPVPairs(obj,varargin{:});

            % Add dynamic props
            dynProps = fieldnames(remArgs);
            for idx=1:numel(dynProps)
                thisProp = dynProps{idx};
                thisValue = remArgs.(thisProp);
                obj.addprop(thisProp);
                obj.(thisProp) = thisValue;
            end

        end %constructor
    end %methods

end % classdef