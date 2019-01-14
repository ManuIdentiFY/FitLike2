classdef Bloc2Zone < ProcessDataUnit
    
    properties
        
    end
    
    
    methods
        
        function self = Bloc2Zone
            self@ProcessDataUnit;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Remove metadata from the function
        % If required, use wrapper(s) to get access [Manu]
        % Need to change the processing model to store parameters from the
        % function inside the processingMethod property [Manu]
        
        % function that applies the processing function to one bloc only.
        % This is where the custom processing function is being called.
        function [zone,bloc] = applyProcessFunction(self,bloc)
            sze = size(bloc.y);
            if length(sze)<3
                sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
            end
            % prepare the cell arrays, making sure the dimensions are
            % consistent
            cellx = squeeze(num2cell(bloc.x,1));
            celly = squeeze(num2cell(bloc.y,1));
            % make sure the data is sorted
            [cellx,ord] = cellfun(@(c)sort(c),cellx,'UniformOutput',0);
            celly = cellfun(@(c,o)c(o),celly,ord,'UniformOutput',0);
            % cast to cell array for cellfun
%             cellindex = repmat(num2cell(1:bloc.parameter.paramList.NBLK)',1,size(bloc.y,3));
            if isempty(bloc.y)
                z = [];
                dz = [];
                paramFun = {};
            else
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                for i = 1:bloc.parameter.paramList.NBLK
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                    for j = 1:size(bloc.y,3)
                        cellindex{i,j} = [i,j]; %#ok<AGROW>
                    end
                end
                if ~isequal(size(cellindex),size(cellx))
                    cellx = cellx';
                    celly = celly';
                end
                % make sure that each acquisition is referenced from the time
                % of acquisition within the data bloc
                cellx = cellfun(@(x)x-x(1),cellx,'UniformOutput',0);
                % process the cell array to get the zone data
                [z, dz, paramFun] = cellfun(@(x,y,i) process(self,x,y,bloc,i),cellx,celly,cellindex,'Uniform',0);
                szeout = size(z{1,1});
                [szeout,ind] = max(szeout); 
                if ind == 2 % check that the result of the process is a column array
                    z = reshape(cell2mat(z),sze(2),szeout,sze(3));
                    dz = reshape(cell2mat(dz),sze(2),szeout,sze(3));
                else
                    z = reshape(cell2mat(z),szeout,sze(2),sze(3));
                    z = permute(z,[2 1 3]);
                    dz = reshape(cell2mat(dz),szeout,sze(2),sze(3));
                    dz = permute(dz,[2 1 3]);
                end
            
                % finally, reshape the list of updated parameters and make a
                % list of adapted structure objects
                params = arrayofstruct2struct(paramFun);
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                fh = str2func(class(bloc.parameter));
                params = fh(params);
                params = reshape(params,size(z));
                params = replace([bloc.parameter,params]);
                bloc.parameter = params;
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
            end
            
            % generate one zone object for each component provided by the
            % processing algorithm
            warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved') % avoid spamming the terminal when the data is not multiexponential
            cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
            celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
            cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
            celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
            x = getZoneAxis(bloc); % raw x-axis (needs to be repmat to fit the dimension of y)
            x = repmat(x,size(cellz)); % make sure that all cell arrays are consistent
            params = repmat({params},size(cellz));
            labelX = repmat({self.labelX},size(cellz));
            labelY = repmat({self.labelY},size(cellz));
            if numel(self.legendTag) ~= numel(labelX)
                legendTag = repmat(self.legendTag,size(cellz));
            else
                legendTag = self.legendTag;
            end
            
            % store the data, but do not erase previous zone objects if
            % they were already processed
            Nzone = length(cellz);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            if isempty(bloc.children)
                zone = Zone('parent',repmat({bloc},size(celldz)),...
                    'x',x,'xLabel',labelX,...
                    'y',cellz,'dy',celldz,'yLabel',labelY,...
                    'parameter',params,'legendTag',legendTag,...
                    'filename',repmat({bloc.filename},size(celldz)),...
                    'sequence',repmat({bloc.sequence},size(celldz)),...
                    'dataset',repmat({bloc.dataset},size(celldz)),...
                    'label',repmat({bloc.label},size(celldz)));
            elseif length(bloc.children) < Nzone
                % case when the new processing function produces more
                % outputs than the previous one. In that case we replace
                % when can be replaced and create new zone objects
                index = 1:length(bloc.children);
                bloc.children = updateProperties(bloc.children,...
                    'x',x(index),'xLabel',labelX(index),...
                    'y',cellz(index),'dy',celldz(index),'yLabel',labelY(index),...
                    'parameter',params(index),'legendTag',legendTag(index));
                index = length(bloc.children)+1 : Nzone;
                Zone('parent',repmat({bloc},size(index)),...
                    'x',x(index),'xLabel',labelX(index),...
                    'y',cellz(index),'dy',celldz(index),'yLabel',labelY(index),...
                    'parameter',params(index),'legendTag',legendTag(index),...
                    'filename',repmat({bloc.filename},size(index)),...
                    'sequence',repmat({bloc.sequence},size(index)),...
                    'dataset',repmat({bloc.dataset},size(index)),...
                    'label',repmat({bloc.label},size(index)));
                % add the other zone objects to return them all
                zone = bloc.children;
            else
                % case when the new processing function provides less or as
                % many outputs as the previous one. In that case we update
                % all the zonea we can and discard the others.
                bloc.children(1:Nzone) = updateProperties(bloc.children,...
                    'x',x,'xLabel',labelX,...
                    'y',cellz,'dy',celldz,'yLabel',labelY,...
                    'parameter',params,'legendTag',legendTag);
                remove(bloc.children, Nzone+1:numel(bloc.children));
                zone = bloc.children;
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % TO DO: make some test functions
                        
        % Function that makes the actual processing of the bloc. It only
        % deals with one bloc at a time and creates one zone only.
        function [zone,bloc] = makeZone(self,bloc)
            % check that all the input objects are bloc objects
            % TO DO
            
            % generate the data to populate the zone object
            [zone,bloc] = arrayfun(@self.applyProcessFunction,bloc,'Uniform',0);
            zone = [zone{:}]; % back to array of objects
            bloc = [bloc{:}];
        end
    end
    
    methods (Sealed)
        % standard naming convention for the processing function
        function [zone,bloc] = processData(self,bloc)
            [z,b] = arrayfun(@(s)makeZone(s,bloc),self,'UniformOutput',0);
            zone = [z{:}];
            bloc = [b{:}];
        end
    end
    
end



