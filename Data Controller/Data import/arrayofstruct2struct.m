function stackstruct = arrayofstruct2struct(arrayofstruct)
%
% STACKSTRUCT = ARRAYOFSTRUCT2STRUCT(ARRAYOFSTRUCT) compress an array of
% struct to a structure by checking each field and replace identical values
% by the single appropriate one (string or numeric). If the values are
% different then ARRAYOFSTRUCT2STRUCT convert them into the appropriate
% stacked format (cell for string or array for numeric)
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr

% check input
if max(size(arrayofstruct)) == 1
    disp('Warning: input is not an array of structure')
    stackstruct = arrayofstruct;
    return
end

fld = fieldnames(arrayofstruct); 
val = cell(size(fld));

for i = 1:length(fld)
    % check if the value is a string
    if ischar(arrayofstruct(1).(fld{i}))
        v = {arrayofstruct.(fld{i})}; % get all the values
        % check if the string is repeated along the array
        if all(strcmp(v(1),v(2:end)) == 1)
            val{i} = v{1};
        else
            val{i} = v;
        end
    else
        v = [arrayofstruct.(fld{i})]; % get all the values 
         % check if the number/array is repeated along the array
        if all(v == v(1))
            val{i} = v(1);
        else
            val{i} = v;
        end
    end
end

stackstruct = cell2struct(val,fld,1);
end

