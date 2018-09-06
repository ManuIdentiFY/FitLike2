%% Table
%   Copyright 2015-2018 The MathWorks, Inc.

%% Create the widget

f = figure(...
    'Toolbar','none',...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Units','pixels',...
    'Position',[100 100 880 200]);
movegui(f,[100 -100])

w = uiw.widget.Table(...
    'Parent',f,...
    'CellEditCallback',@(h,e)disp(e),...
    'CellSelectionCallback',@(h,e)disp(e),...
    'ColumnName',{'A','B','C'},...
    'Label','Table:', ...
    'LabelLocation','top',...
    'LabelHeight',18,...
    'Units','normalized', ...
    'Position',[0 0 1 1]);


%% Place numeric data

w.Data = magic(3);


%% Disable auto-resize

w.ColumnResizePolicy = 'off';


%% Column formats

columnFormatsAndData = {
    ''          []
    'logical'   []
    'integer'   []
    'numeric'   []
    'bank'      '$ #,##0.00'
    'custom'    '0.000'
    'date'      'yyyy-MM-dd'
    'char'      []
    'longchar'  []
    'popup'     {'apples','oranges','bananas'}
    'popuplist' {'fork','spoon','knife','spatula'}
    'color'     []
    'imageicon' [] %these cells are non-editable
    };

w.ColumnName = columnFormatsAndData(:,1); %Just to show the name of each format
w.ColumnFormat = columnFormatsAndData(:,1);
w.ColumnFormatData = columnFormatsAndData(:,2);

longStr = repmat('abcdefg ',1,100); % A really long string
[~,iconPath1] = uiw.utility.loadIcon('save_24.png');
[~,iconPath2] = uiw.utility.loadIcon('add_24.png');

w.Data = {
    %''   logical integer numeric bank   custom date     char    longchar popup     popupcheckbox              color    imageicon
    20    false   20      20      20     20     datetime 'abc'   'abc'    'bananas' 'fork'                     [0 1 1]  iconPath1
    1.5   true    1.5     1.5     1.5    1.5    datetime ''      longStr  'apples'  {'fork','knife','spatula'} [1 1 0]  iconPath1
    1/8   false   10000   22/7    3.256  3.256  datetime 'defgh' longStr  'oranges' {}                         [0 0 0]  iconPath2
    true  true    1e9     0.525   1000.2 1000.2 datetime 'ddd'   'efghi'  'apples'  {'spoon'}                  [1 1 1]  iconPath1
    'abc' true    50      1e9     -3     -3     datetime 'lmnp'  ''       'apples'  {'knife','spoon'}          [1 0 0]  iconPath2
    };


%% Resize column width to fit data
w.sizeColumnsToData();


%% Make some columns non-editable

editFlags = true(1, length(columnFormatsAndData));
editFlags([1 2 4]) = false;
w.ColumnEditable = editFlags;


%% Add a context menu

hCMenu = uicontextmenu('Parent',f);
uimenu(hCMenu,'Label','Option 1');
uimenu(hCMenu,'Label','Option 2');

w.UIContextMenu = hCMenu;


%% Sort columns

% Click on a column header to sort. Ctrl-click additional column headers to
% multi-level sort.
w.Sortable = true;

% Programmatically sort
w.sortColumn(7);

% Sort an additional column in descending order
w.sortColumn(5,true,true)