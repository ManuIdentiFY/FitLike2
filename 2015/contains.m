function tf = contains(str, pattern)
%
% Just a function to re-write the contains function from Matlab 2016b.
%
% M.Petit - 2018/10
% manuel.petit@inserm.fr

if iscell(str)
    tf = false(size(str));
    % loop over the cell array of string
    for k = numel(str):-1:1
        % check if multiple patterns
        if iscell(pattern)
            for j = 1:numel(pattern)
                if ~isempty(strfind(str{k}, pattern{j}))
                    tf(k) = 1;
                    break
                end
            end
        else
            tf(k) = ~isempty(strfind(str{k}, pattern));
        end
    end
elseif ischar(str)
    % check if multiple patterns
    if iscell(pattern)
        tf = 0;
        for j = 1:numel(pattern)
            if ~isempty(strfind(str, pattern{j}))
                tf = 1;
                break
            end
        end
    else
        tf = ~isempty(strfind(str, pattern)); %#ok<STREMP>
    end
else
    error('Wrong input: str must be a char or cell array of string')
end
end

