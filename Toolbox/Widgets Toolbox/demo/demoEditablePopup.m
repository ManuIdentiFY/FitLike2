%% Editable Popup
%   Copyright 2017-2018 The MathWorks, Inc.

%% Create the widget

f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 320 45]);
movegui(f,[100 -100])

w = uiw.widget.EditablePopup(...
    'Parent',f,...
    'Items',{'USA','Canada','Mexico'},...
    'SelectedIndex',2,...
    'Value','France',...
    'Callback',@(h,e)disp(e),...
    'Label','Country:',...
    'LabelLocation','left',...
    'LabelWidth',90,...
    'Units','pixels',...
    'Position',[10 10 300 25]);


%% Set the value to freeform text

w.Value = 'Spain';


%% Set to a value in the list by Value

w.Value = 'Mexico';


%% Set to a value in the list by index

w.SelectedIndex = 1;


%% Show text validity

% Toggle this if the user enters an invalid value
w.TextIsValid = false;


%% Adjust invalid coloring if desired

% Invalid text colors
w.TextInvalidBackgroundColor = [1 .8 .8];
w.TextInvalidForegroundColor = [1 0 0];


%% Restore text validity

w.TextIsValid = true;



