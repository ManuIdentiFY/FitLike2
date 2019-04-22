function blocList = makeComplexBloc(data) 
% This class accepts the output from file readers and turn them into
% Bloc objects.
% make a list of blocs from data arrays obtained from the file
% readers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
% Remove parameter or change data access [Manu]
blocList = Bloc('y',cellfun(@(x,y) x+1i*y,data.real,data.imag,'UniformOutput',0),'x',data.time);
% for i = 1:length(blocList)
%     blocList(i).parameter = param(i);
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 