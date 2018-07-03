function [x,y,dy] = readsef(filename)
%
%[X,Y,DY] = READSEF(FILENAME) reads data from a Stelar file .sef. It
%returns the magnetic fields x, the relaxation times y and its errors dy 
% as vectors.
%
% Example:
% filename = 'stelar_data.sef';
% [x,y,dy] = readsef(filename);
%
% See also READSDFV1, READSDF2
%
% Manuel Petit, May 2018
% manuel.petit@inserm.fr

fid = fopen(filename,'r');
data = textscan(fid,'%f %*f %f %*f %f %*f %*[^\n]','HeaderLines',4);
fclose(fid);

x = data{1};
y = data{2};
dy = data{3};
end

