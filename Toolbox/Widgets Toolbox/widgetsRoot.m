function out = widgetsRoot()
% widgetsRoot - Return root folder where +uiw widgets package resides
%

% Copyright 2018 The MathWorks, Inc.
%
% Auth/Revision:
%   MathWorks Consulting
%   $Author: rjackey $
%   $Revision: 55 $  $Date: 2018-02-27 13:41:05 -0500 (Tue, 27 Feb 2018) $
% ---------------------------------------------------------------------

out = fileparts(mfilename('fullpath'));
