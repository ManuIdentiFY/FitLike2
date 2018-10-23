function [dataContent, parameter] = readH9ScannerFile(filename,varargin)

% [BLOC, PARAMETERS] = readH9ScannerFile(FILENAME,VARARGIN) reads data
% obtained from the Aberdeen H9 FFC-MRI scanner, from non-imaging
% dispersion acquisition sequence.
% 
% l.broche@abdn.ac.uk

%% Open the file
load(filename) % this imports the cell 'saveList' that contains the pulse sequence data
sequenceList = cellfun(@(x)class(x),saveList,'UniformOutput',0); %#ok<USENS>
selection = strcmp(sequenceList,'H9_InversionRecoveryFC');  % select the correct pulse sequence
dataContent = struct(); % formating the output structure
n = 0; % number of datasets imported

%% analyse the data
for i = 1:length(sequenceList)
    % check the data
    if ~selection(i)  % reject all the sequences that are not about dispersion curves
        continue
    end
    data = squeeze(saveList{i}.data);
    if ~isequal(size(data),[saveList{i}.pprParamList{7,3},saveList{i}.waveformProfile.generator.NTevo,saveList{i}.waveformProfile.generator.NBevo])
        continue
    end
    % grab the raw data
    n = n+1;
    dt = saveList{i}.pprParamList{2,3}{2}*1e-6; % dwell time in s
    t = dt*(1:size(saveList{i}.data,1))';
    dataContent.real{n} = real(data);
    dataContent.imag{n} = imag(data);
    dataContent.time{n} = repmat(t,1,size(data,2),size(data,3));
    paramCell = ppr2struct(saveList{i}.pprParamList);
    if n==1
        parameter = ParamH9(paramCell);  % this is needed to initialise an array of objects
    else
        parameter(n) = ParamH9(paramCell);
    end
    parameter(n).paramList.BRLX = saveList{i}.waveformProfile.generator.Bevo*42.57e6;
    parameter(n).paramList.T1MX = saveList{i}.dataProcessed(:,4);
    [~,parameter(n).paramList.FILE] = fileparts(filename);
    parameter(n).paramList.FILE = [parameter(n).paramList.FILE ' - ' num2str(n)];
    parameter(n).paramList.EXP = saveList{i}.userData.sequenceInfo;
    parameter(n).paramList.NBLK = size(data,2);
    parameter(n).paramList.rawData = saveList{i};
    parameter(n).paramList.Tevo = saveList{i}.waveformProfile.generator.Tevo;
end
        
