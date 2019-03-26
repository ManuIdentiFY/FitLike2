function data = readsef(filename)
%
% DATA = READSEF(FILENAME) reads data from a Stelar file .sef. It
% returns the magnetic fields x, the relaxation times y and its errors dy 
% in a structure DATA.
% DATA contains three fields (x, y, dy) where each field is a vector.
%
% Example:
% filename = 'stelar_data.sef';
% data = readsef(filename);
%
% See also READSDFV1, READSDF2
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr

fid = fopen(filename,'r');
rawdata = textscan(fid,'%f %*f %f %*f %f %*f %*[^\n]','HeaderLines',4);
fclose(fid);

data.x = rawdata{1};
data.y = rawdata{2};
data.dy = rawdata{3};
end

