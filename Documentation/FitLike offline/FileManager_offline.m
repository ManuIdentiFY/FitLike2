clear all
close all

% This script shows how to use FileManager without FitLike software. Do not
% forget to add path to FitLike repository before running the script.
%
% M.Petit - 03/2019
% manuel.petit@inserm.fr

% Load some data (RelaxObj)
dataset = load('dataset_example.mat');
data = dataset.relaxData;

% Run FileManager without FitLike
fig = FileManager(0); % 0 avoid input error and replace FitLike input

%% Add data to FileManager.
addFile(fig, data); pause(0.05);

%% Delete data from FileManager
checkFile(fig, data(2:5)); %manually check some files, you can do this directly in the window!
deleteFile(fig); %delete selected files

%% Get the selected files
addFile(fig, data(2:10)); pause(0.01); %add data again
checkFile(fig, data(2)); %manually check some files, you can do this directly in the window!
getSelectedFile(fig)

%% Change the selected data tree. 
% Again, you can do this directly in the window by selected another tab.
setTree(fig, 'Zone'); % change to the Zone tab

%% Get the selected data. 
% Selection of data can be done directly in the window by clicking on the
% checkboxes in the data tree.

% for the example select manually data
zone = getData(data(2),'Zone'); % just for the example, get zone data
checkData(fig, zone, 1, 1); %quite complex here, just for the example

[hData, idxZone] = getSelectedData(fig)

%% Reset the file tree: unchecked all nodes
reset(fig);

%% Edit file
% Here I do this operation manually but you can edit nodes (file tree)
% directly by clicking on the text next to the checkbox. I just added this
% example to show the update of the RelaxObj
node = TreeManager.findobj(fig.gui.treefile.Root,'UserData', data(2)); 
fprintf('Old filename: %s\n', node.Name)
event = struct('Nodes',node,'OldName',data(2).filename,'NewName','Edit!');
editFile(fig, [], event);
fprintf('New filename: %s\n', data(2).filename);
% Here I printed the filename directly from the RelaxObj since it does not
% update automaticaly the concerned node. It is because such behaviour
% (doing edition manually) is not normally permitted
node.Name = 'Edit!'; % I do it manually

% you can also try to 'edit' file by using Drag and drop and see the
% results in your RelaxObj array



