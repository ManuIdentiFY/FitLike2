classdef Zone2Disp < ProcessDataUnit
    
    properties
        
    end
    
    
    methods
        
        function self = Zone2Disp
            self@ProcessDataUnit;
        end
        
    end
    
    
    methods (Sealed)
        
        % function that applies the processing function to one zone only.
        % This is where the custom processing function is being called.
        function [dispersion,zone] = applyProcessFunction(self,zone)
            sze = size(zone.y);
            if length(sze)<3
                sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
            end
            % prepare the cell arrays, making sure the dimensions are
            % consistent
            cellx = squeeze(num2cell(zone.x,1));
            celly = squeeze(num2cell(zone.y,1));
            % make sure the data is sorted
            [cellx,ord] = cellfun(@(c)sort(c),cellx,'UniformOutput',0);
            celly = cellfun(@(c,o)c(o),celly,ord,'UniformOutput',0);
            % cast to cell array for cellfun
            cellindex = num2cell(1:size(zone.y,2));
            if ~isequal(size(cellindex),size(cellx))
                cellx = cellx';
                celly = celly';
            end
            % make sure that each acquisition is referenced from the time
            % of acquisition within the data zone
            cellx = cellfun(@(x)x-x(1),cellx,'UniformOutput',0);
            % process the cell array to get the zone data
            [z, dz, paramFun] = cellfun(@(x,y,i) process(self,x,y,zone,i),cellx,celly,cellindex,'Uniform',0);
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
            if iscell(paramFun)
                paramFun = [paramFun{:}];
            end
            params = arrayofstruct2struct(paramFun);
            fh = str2func(class(zone.parameter));
            params = fh(params);
            params = reshape(params,size(z));
            params = replace([zone.parameter,params]);
            zone.parameter = params;
            
            % generate one zone object for each component provided by the
            % processing algorithm
            warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved') % avoid spamming the terminal when the data is not multiexponential
            cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
            celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
            cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
            celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
            x = getDispAxis(zone); % raw x-axis (needs to be repmat to fit the dimension of y)
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
            if isempty(zone.children)
                dispersion = Dispersion('parent',repmat({zone},size(cellz)),...
                    'x',x,'xLabel',labelX,...
                    'y',cellz,'dy',celldz,'yLabel',labelY,...
                    'parameter',params,'legendTag',legendTag,...
                    'filename',repmat({zone.filename},size(cellz)),...
                    'sequence',repmat({zone.sequence},size(cellz)),...
                    'dataset',repmat({zone.dataset},size(cellz)),...
                    'label',repmat({zone.label},size(cellz)));

                % link the children and parent objects
                [zone,dispersion] = link(zone,dispersion);
            elseif length(zone.children) < length(cellz)
                % case when the new processing function produces more
                % outputs than the previous one. In that case we replace
                % when can be replaced and create new zone objects
                index = 1:length(zone.children);
                zone.children = updateProperties(zone.children,...
                    'x',x(index),'xLabel',labelX(index),...
                    'y',cellz(index),'dy',celldz(index),'yLabel',labelY(index),...
                    'parameter',params(index),'legendTag',legendTag(index));
                index = length(zone.children)+1 : Nzone;
                Zone('parent',repmat({zone},size(index)),...
                    'x',x(index),'xLabel',labelX(index),...
                    'y',cellz(index),'dy',celldz(index),'yLabel',labelY(index),...
                    'parameter',params(index),'legendTag',legendTag(index),...
                    'filename',repmat({zone.filename},size(index)),...
                    'sequence',repmat({zone.sequence},size(index)),...
                    'dataset',repmat({zone.dataset},size(index)),...
                    'label',repmat({zone.label},size(index)));
                % link the children and parent objects
                %[zone,~] = link(zone,zone);
                % add the other zone objects to return them all
                dispersion = zone.children;
            else
                % case when the new processing function provides less or as
                % many outputs as the previous one. In that case we update
                % all the zonea we can and discard the others.
                zone.children(1:Nzone) = updateProperties(zone.children,...
                    'x',x,'xLabel',labelX,...
                    'y',cellz,'dy',celldz,'yLabel',labelY,...
                    'parameter',params,'legendTag',legendTag);
                remove(zone.children(Nzone+1:end));
                dispersion = zone.children;
            end
        end
        
        % TO DO: make some test functions
                           
        % Function that makes the actual processing of the zone. It only
        % deals with one zone at a time and creates one disp only.
        function [dispersion,zone] = makeDisp(self,zone)
            % check that all the input objects are zone objects
            
%             
%             % generate the data to populate the zone object
%             x = getDispAxis(zone); % raw x-axis (needs to be repmat to fit the dimension of y)
%             [y,dy,params] = arrayfun(@self.applyProcessFunction,zone,'Uniform',0);
%             
%             % generate the zone object
%             disp = Dispersion('x',x,'y',y,'dy',dy,'parameter',params);
%             disp = arrayfun(@(x,y) setfield(x,'parent',y),disp,zone);
            % generate the data to populate the zone object
            [dispersion,zone] = arrayfun(@self.applyProcessFunction,zone,'Uniform',0);
            dispersion = [dispersion{:}]; % back to array of objects
            zone = [zone{:}];
        end
    
        % standard naming convention for the processing function
        function [disp,zone] = processData(self,zone)
            [d,z] = arrayfun(@(s)makeDisp(s,zone),self,'UniformOutput',false);
            zone = [z{:}];
            disp = [d{:}];
        end

    end
    
end



