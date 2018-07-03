function [bloc, parameters] = readsdfv2(fid)
%
% [BLOC, PARAMETERS] = READSDFV2(FID) reads data from a Stelar file .sdf
% version 2. Use FOPEN to open the file and obtain FID. It returns the data
% as DataUnit and the parameters as cells.
%
% The number of DataUnit and cell is determined by the number of different
% acquisitions in the Stelar file. Two acquisitions are different if one of
% the following condition is not fullfilled:
% 1. The sequence are not the same (see the field "EXP")
% 2. The size of the data is not consistent between the acquisitions 
% 3. The parameter's fields are not the same
% 
% Notes:
% When two acquisitions are the same, data (fields: x,y) are stacked along 
% the third dimensions and parameters are concatenated.
%
% Example:
% filename = 'stelar_data.sdf';
% fid = fopen(filename, 'r');
% [bloc, parameters] = readsdfv2(fid);
%
% See also DATAUNIT, READSDFV1
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr


N_MAX_PARAMETERS = 150; % maximum number of parameter in the header

bloc = DataUnit(); % preallocation 
parameters = cell(1,1); %preallocation
iAcq = 1; % number of acquisition

%% Read the file
while 1 
    %+ Get the header information   
    % Find the length of the header by reading a bloc and catch 'DATA'
    pos = ftell(fid); %memorize the position       
    txt = textscan(fid,'%s',N_MAX_PARAMETERS,'delimiter','\r'); %read the bloc
    if length(txt{1}) < N_MAX_PARAMETERS
        break %end of the file
    end  
    % Get the sequence name
    seqpos = find(startsWith(txt{1},'SEQUENCE'),1);
    seq = strtrim(txt{1}{seqpos}(15:end));
    % Read the header
    offset = find(startsWith(txt{1},'PARAMETER'),1)+1;
    nRow = find(startsWith(txt{1},'ZONE'),1) - offset;
    fseek(fid,pos,'bof'); %replace the position
    hdr = textscan(fid, '%s %s', nRow, 'delimiter', '=','Headerlines',offset+2);
    % Remove all the space
    hdr = cellfun(@(x) regexprep(x, '\s+', ''),hdr,'UniformOutput',0);     
    % Format the header's values
    isdouble = cellfun(@str2double, hdr{2}); 
    hdr{2}(~isnan(isdouble)) = num2cell(isdouble(~isnan(isdouble))); %convert to double if possible
    % Create the header
    header = cell2struct(hdr{2},hdr{1},1); 
    
    %+ Get the data 
    if header.NBLK == 0 % this happens when the sequence is not staggered (not over multiple fields such as PP, NP, etc...)
        header.NBLK = 1;
    end
    
    %% TO DO: read the data and format the ouput
    
end %while
bloc = 1;
parameters = 1;
end



