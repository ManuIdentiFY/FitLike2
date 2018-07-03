function ver = checkversion(filename)
%
% VER = CHECKVERSION(FILENAME) check the version of an .sdf Stelar file
% from the SPINMASTER.

fid = fopen(filename, 'r'); % open the file in read only mode
line = textscan(fid,'%s',1,'Delimiter','=','HeaderLines',2); %read the first field to check the version

if strcmp(deblank(line{1}),'VERSION') 
    ver = 2;
else
    ver = 1;
end
end

