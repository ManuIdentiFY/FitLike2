function time = getinvtime(parameters)
%
% TIME = GETINVTIME(PARAMETERS) calculates the inversion time series
% according to the Stelar parameters structure. 
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr

% check input
if ~isfield(parameters,'BGRD')
    time = [];
    return
end

% get the time series
switch parameters.BGRD
    case 'LIST'
        T1MX = parameters.T1MX; %get all the T1MX values for eval()
        blst = regexp(parameters.BLST,'[;:]','split'); %split the field BLST
        Ti = eval(parameters.BINI);
        Te = eval(parameters.BEND);  
        if strcmp(blst{3},'LOG')
           time = logspace(log10(Ti),log10(Te),parameters.NBLK); %create all the time vectors
        else %'LIN'
           time = linspace(Ti,Te,parameters.NBLK); %create all the time vectors
        end                
    case 'LOG'
        T1MX = parameters.T1MX; %get all the T1MX values for eval()
        Ti = eval(parameters.BINI);
        Te = eval(parameters.BEND);
        time = logspace(log10(Ti),log10(Te),parameters.NBLK); %create all the time vectors
    case 'LIN'
        T1MX = parameters.T1MX; %get all the T1MX values for eval()
        Ti = eval(parameters.BINI);
        Te = eval(parameters.BEND);
        time = linspace(Ti,Te,parameters.NBLK); %create all the time vectors
    otherwise
        disp('Warning: BGRD parameter seems absent from the parameter structure')
end %switch

end

