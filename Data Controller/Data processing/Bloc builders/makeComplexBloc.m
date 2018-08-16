function blocList = makeComplexBloc(data,param) 
% This class accepts the output from file readers and turn them into
% Bloc objects.
% make a list of blocs from data arrays obtained from the file
% readers
        
blocList = Bloc('y',cellfun(@(x,y) x+1i*y,data.real,data.imag,'UniformOutput',0),'x',data.time,'parameter',param);
