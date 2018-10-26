function param = ppr2struct(pprData)

% change ppr cells of parameters to structure.
% for use with MR  Solution EVO consoles
%
% Lionel Broche, 19/10/2018

for i = 1:size(pprData,1)
    switch pprData{i,1}
        case 'VAR'
            param.(pprData{i,2}) = pprData{i,3};
        case 'OBSERVE_FREQUENCY'
            param.nucleus = pprData{i,2};
            param.(pprData{i,1}) = pprData{i,3};
        case 'PPL'
            [~,param.EXP] = fileparts(pprData{i,2});
        otherwise
            param.(pprData{i,1}) = pprData{i,3};
    end
end