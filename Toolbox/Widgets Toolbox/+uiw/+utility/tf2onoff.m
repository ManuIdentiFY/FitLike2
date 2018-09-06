function str = tf2onoff(tf)
% tf2onoff - Utility to convert logical true/false to char 'on'/'off'
% 
% This function converts a single true/false flag to an on/off string
%
% Syntax:
%           str = uiw.utility.tf2onoff(tf)
%
% Inputs:
%           tf - logical scalar or vector
%
% Outputs:
%           str - 'on' or 'off'
%
% Examples:
%           none
%
% Notes: none
%

% Copyright 2016-2018 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 58 $  $Date: 2018-02-27 14:53:00 -0500 (Tue, 27 Feb 2018) $
% ---------------------------------------------------------------------


if isscalar(tf)
    if tf
        str = 'on';
    else
        str = 'off';
    end
else
    str = repmat({'off'},size(tf));
    str(tf) = {'on'};
end