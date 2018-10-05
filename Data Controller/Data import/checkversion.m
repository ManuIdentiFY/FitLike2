function ver = checkversion(filename)
%
% VER = CHECKVERSION(FILENAME) check the version of an .sdf Stelar file
% from the SPINMASTER.

fid = fopen(filename, 'r'); % open the file in read only mode
line = textscan(fid,'%s',1,'Delimiter','=','HeaderLines',2); %read the first field to check the version

% Version 2 files can start in different ways depending on how the
% acquisition was performed. Therefore several tests are needed.
if strcmp(deblank(line{1}),'VERSION') || strcmp(deblank(line{1}),'PARAMETER SUMMARY') || strcmp(deblank(line{1}),'SEQUENCE NAME')
    ver = 2;
else
    ver = 1;
end

fclose(fid); %close file
end

