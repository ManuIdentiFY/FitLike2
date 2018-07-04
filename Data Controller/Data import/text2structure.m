function paramStruct = text2structure(txt)
% This function reads a section of text and convert the lines into a
% structure, supposing that the parameters are defined by the following
% format:
% 'NAME = VALUE'
% and the txtcell array contains one set of parameters per lines

posEq = strfind(txt,'=');
fieldName =  cellfun(@(x) x(1:strfind(x,'=')-2),txt,'UniformOutput',0);
fieldContent = cellfun(@(x) x(strfind(x,'=')+2:end),txt,'UniformOutput',0);
emptyField = cellfun(@isempty,fieldName); % find the lines that do not correspond to parameters...
fieldName(emptyField) = [];   % and remove the corresponding lines.
fieldContent(emptyField) = [];
fieldName = cellfun(@(x) regexprep(x, '\s+', ''), fieldName, 'UniformOutput',0);  % Remove all the spaces in the field names        
% Format the header's values
isdouble = cellfun(@str2double, fieldContent); 
fieldContent(~isnan(isdouble)) = num2cell(isdouble(~isnan(isdouble))); %convert to double if possible
paramStruct = cell2struct(fieldContent,fieldName,1);
        
    



% % for info: when dealing with file ID (does not work correctly because of
% % the poor handling of empty lines by Matlab in SDF files version 2)
% paramList = textscan(fid, '%s %s', nLines, 'delimiter', '=','Headerlines',headerLines);
% paramList{1} = cellfun(@(x) regexprep(x, '\s+', ''),paramList{1},'UniformOutput',0);  % remove the blanks from the parameter names
%  % Format the parameters's values
% isdouble = cellfun(@str2double, paramList{2}); 
% paramList{2}(~isnan(isdouble)) = num2cell(isdouble(~isnan(isdouble))); %convert to double if possible
% % Create the parameter structure
% paramStruct = cell2struct(paramList{2},paramList{1},1);