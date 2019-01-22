classdef Bloc2Disp < ProcessDataUnit
    
    properties
        Bloc@Bloc;  % store the Bloc object to be processed
        InputChildClass = Bloc;
        OutputChildClass = Dispersion;
    end
    
    
    methods
        
        function self = Bloc2Disp
            this@DataUnit2DataUnit;
        end
    end
%         
%         % function that applies the processing function to one bloc only.
%         % This is where the custom processing function is being called.
%         function [dispersion,bloc] = applyProcessFunction(self,bloc)
%             sze = size(bloc.y);
%             if length(sze)<3
%                 sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
%             end
%             
%             % process the cell array to get the zone data
%             [z, dz, paramFun] = process(self,bloc.x,bloc.y,bloc,'Uniform',0);
%             
%             % finally, reshape the list of updated parameters and make a
%             % list of adapted structure objects
%             params = arrayofstruct2struct(paramFun);
%             fh = str2func(class(bloc.parameter));
%             params = fh(params);
%             params = reshape(params,size(z));
%             params = merge([bloc.parameter,params]);
%             bloc.parameter = params;
%             
%             % generate one zone object for each component provided by the
%             % processing algorithm
%             warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved') % avoid spamming the terminal when the data is not multiexponential
%             cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
%             celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
%             cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
%             celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
%             x = getDispAxis(bloc); % raw x-axis (needs to be repmat to fit the dimension of y)
%             x = repmat(x,size(cellz)); % make sure that all cell arrays are consistent
%             params = repmat({params},size(cellz));
%             
%             % store the data, but do not erase previous zone objects if
%             % they were already processed
%             Nzone = length(cellz);
%             if isempty(bloc.children)
%                 dispersion = Dispersion('x',x,'xLabel',{self.labelX},...
%                     'y',cellz,'dy',celldz,'yLabel',{self.labelY},...
%                     'parameter',params,'legendTag',self.legendTag,...
%                     'filename',{bloc.filename},'sequence',{bloc.sequence},...
%                     'dataset',{bloc.dataset},'label',{bloc.label});
% 
%                 % link the children and parent objects
%                 [bloc,dispersion] = link(bloc,dispersion);
%             elseif length(bloc.children) < Nzone
%                 % case when the new processing function produces more
%                 % outputs than the previous one. In that case we replace
%                 % when can be replaced and create new zone objects
%                 index = 1:length(bloc.children);
%                 bloc.children = updateProperties(bloc.children,...
%                     'x',x(index),'xLabel',{self.labelX},...
%                     'y',cellz(index),'dy',celldz(index),'yLabel',{self.labelY},...
%                     'parameter',params(index),'legendTag',self.legendTag(index),...
%                     'filename',{bloc.filename},'sequence',{bloc.sequence},...
%                     'dataset',{bloc.dataset},'label',{bloc.label});
%                 index = length(bloc.children)+1 : Nzone;
%                 dispersion = Dispersion('x',x(index),'xLabel',{self.labelX},...
%                     'y',cellz(index),'dy',celldz(index),'yLabel',{self.labelY},...
%                     'parameter',params(index),'legendTag',self.legendTag(index),...
%                     'filename',{bloc.filename},'sequence',{bloc.sequence},...
%                     'dataset',{bloc.dataset},'label',{bloc.label});
%                 % link the children and parent objects
%                 [bloc,~] = link(bloc,dispersion);
%                 % add the other zone objects to return them all
%                 dispersion = bloc.children;
%             else
%                 % case when the new processing function provides less or as
%                 % many outputs as the previous one. In that case we update
%                 % all the zonea we can and discard the others.
%                 bloc.children(1:Nzone) = updateProperties(bloc.children(1:Nzone),...
%                     'x',x,'xLabel',{self.labelX},...
%                     'y',cellz,'dy',celldz,'yLabel',{self.labelY},...
%                     'parameter',params,'legendTag',self.legendTag,...
%                     'filename',{bloc.filename},'sequence',{bloc.sequence},...
%                     'dataset',{bloc.dataset},'label',{bloc.label});
%                 remove(bloc.children(Nzone+1:end));
%                 dispersion = bloc.children;
%             end
%         end
%         
%         % TO DO: make some test functions
%                         
%         % Function that makes the actual processing of the bloc. It only
%         % deals with one bloc at a time and creates one zone only.
%         function [dispersion,bloc] = makeZone(self,bloc)
%             % check that all the input objects are bloc objects
%             % TO DO
%             
%             % generate the data to populate the zone object
%             [dispersion,bloc] = arrayfun(@self.applyProcessFunction,bloc,'Uniform',0);
%             dispersion = [dispersion{:}]; % back to array of objects
%             bloc = [bloc{:}];
%         end
%     end
%     
%     methods (Sealed)
%         % standard naming convention for the processing function
%         function [dispersion,bloc] = processData(self,bloc)
%             [d,b] = arrayfun(@(s)makeZone(s,bloc),self,'UniformOutput',0);
%             dispersion = [d{:}];
%             bloc = [b{:}];
%         end
%     end
%     
end



