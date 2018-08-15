classdef Zone2Disp < ProcessDataUnit
    
    properties
        
    end
    
    
    methods
        
        function self = Zone2Disp
            self@ProcessDataUnit;
        end
        
        % function that applies the processing function to one bloc only.
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
            cellindex = num2cell(1:size(zone.y,2));
            if ~isequal(size(cellindex),size(cellx))
                cellx = cellx';
                celly = celly';
            end
            % make sure that each acquisition is referenced from the time
            % of acquisition within the data bloc
            cellx = cellfun(@(x)x-x(1),cellx,'UniformOutput',0);
            % process the cell array to get the zone data
            [z, dz, paramFun] = cellfun(@(x,y,i) process(self,x,y,zone.parameter.paramList,i),cellx,celly,cellindex,'Uniform',0);
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
            params = merge(zone.parameter,params);
            
            % generate one zone object for each component provided by the
            % processing algorithm
            cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
            celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
            cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
            celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
            x = getDispAxis(zone); % raw x-axis (needs to be repmat to fit the dimension of y)
            x = repmat(x,size(cellz)); % make sure that all cell arrays are consistent
            params = repmat({params},size(cellz));
            dispersion = Zone('x',x,'y',cellz,'dy',celldz,'parameter',params,'legendTag',self.legendTag);
            
            % link the children and parent objects
            dispersion = arrayfun(@(x) setfield(x,'parent',zone),dispersion);
            zone.children = [zone.children dispersion];
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
    end
    
end



