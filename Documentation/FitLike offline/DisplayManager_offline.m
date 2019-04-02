clear all
close all

% This script shows how to use DisplayManager without FitLike software. Do not
% forget to add path to FitLike repository before running the script.
%
% M.Petit - 03/2019
% manuel.petit@inserm.fr

% Load some data (RelaxObj)
dataset = load('dataset_example.mat');
data = dataset.relaxData;

% Run DisplayManager without FitLike input
fig = DisplayManager(0); %add random input to avoid error

%% Add data to DisplayManager
% Start with Dispersion data: it will changes the type of tab from Untitled
% to Dispersion. Keep in mind that data are added to the selected tab.
% Adding data to DisplayManager requires to indicate a zone index. If all
% zone index are wanted for a given data(i) then idxZone(i) = NaN.
dispersion = getData(data,'Dispersion'); %get dispersion data
addPlot(fig, dispersion, nan(size(dispersion))); %here we want the complete dispersion profile, thus idxZone = [NaN NaN...NaN] with size(idxZone) = size(hData)

%% Delete data from DisplayManager
% Deleting data from DisplayManager requires the same input as adding data:
% for each data deleted, the corresponding zone index need to be indicated.
% Another way to avoid error is to get data from DisplayManager first then
% remove what you do no want
[hData, idxZone] = getData(fig); %get data from the selected tab (Dispersion tab here)
removePlot(fig, hData(1:2), idxZone(1:2)); %delete the two first dispersion data

%% Add new tab
% You can do this manually by clicking on the '+' tab. Here I am doing this
% programmaticaly for the example
addTab(fig);

%% Add new data type (zone data) to the new untitled tab
% Keep in mind that you cannot add zone data in the Dispersion tab (only
% dispersion data are accepted). Thus it is required to 
zone = getData(data,'Zone'); %get zone data
addPlot(fig, zone(1:2), [1 6]) %add the zone 4 of the first zone object and the zone 6 of the second

% Note also that if you want to add multiple zone index from the same data
% object you need to repeat the data object to fit the idxZone vector
% length. See:
addPlot(fig, repelem(zone(2), 3), 1:3); % zone(2) is repetead three times to fit the idxZone length (=3)

%% Get legend from the selected tab
leg = getLegend(fig) %it avoids fit legend input

%% Mask data
addTab(fig);
addPlot(fig, dispersion(1), NaN); %add one dispersion data
% You can do this by clicking on the 'Mask data' pushbutton. I call the
% function programmaticaly for the example
% The mouse cursor will changed (+ shape) and you can draw a rectangle by
% holding the left-click. The rectangle can be resized or moved. Validate
% the selection by double-clicking anywhere on the rectangle's border.
maskData(fig.gui.tab.SelectedTab.Children);

% Then you can visualise the masked points using the 'Show mask data'
% checkbox

% Note that your masked point are automaticaly stored in the handle object 
fprintf('Mask of the dispersion data:\n')
disp(dispersion(1).mask')

% Note2: You are manipulating handle objects. Thus deletion of any handle
% objects will delete also graphical objects.

%% Delete a tab
% You can delete tabs by right-clicking on any tab and select the 'Close
% tab' menu in the context menu. Here I'm removing the selected tab
% programmaticaly for the example
removeTab(fig);




