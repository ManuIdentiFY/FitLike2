classdef Zone2Disp < ProcessDataUnit
    
    properties
        
    end
    
    
    methods
        
        function self = Zone2Disp
            self@ProcessDataUnit;
        end
        
        
        % function that applies the processing function to one zone only.
        % This is where the custom processing function is being called.
        function [y,dy,params] = applyProcessFunction(self,zone)
            sze = size(zone.y);
            if length(sze)<3
                sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
            end
            % prepare the cell arrays, making sure the dimensions are
            % consistent
            cellx = squeeze(num2cell(zone.x,1));
            celly = squeeze(num2cell(zone.y,1));
            cellindex = repmat(num2cell(1:size(celly,2))',1,size(zone.y,3));
            if ~isequal(size(cellindex),size(cellx))
                cellx = cellx';
                celly = celly';
            end
            % process the cell array to get the zone data
            [y, dy, paramFun] = cellfun(@(x,y,i) process(self,x,y,zone.parameter.paramList,i),cellx,celly,cellindex,'Uniform',0);
            szeout = size(y{1,1});
            [szeout,ind] = max(szeout); 
            if ind == 2 % check that the result of the process is a column array
                y = reshape(cell2mat(y),sze(2),szeout,sze(3));
                dy = reshape(cell2mat(dy),sze(2),szeout,sze(3));
            else
                y = reshape(cell2mat(y),szeout,sze(2),sze(3));
                y = permute(y,[2 1 3]);
                dy = reshape(cell2mat(dy),szeout,sze(2),sze(3));
                dy = permute(dy,[2 1 3]);
            end
            % finally, reshape the list of updated parameters and make a
            % list of adapted structure objects
            if length(paramFun)>1
                params = arrayofstruct2struct(paramFun);
            else
                params = paramFun{1};
            end
            fh = str2func(class(zone.parameter));
            params = fh(params);
            params = reshape(params,size(y));
            params = merge(zone.parameter,params);
        end
        
        % TO DO: make some test functions
                           
        % Function that makes the actual processing of the zone. It only
        % deals with one zone at a time and creates one disp only.
        function disp = makeDisp(self,zone)
            % check that all the input objects are zone objects
            
            
            % generate the data to populate the zone object
            x = getDispAxis(zone); % raw x-axis (needs to be repmat to fit the dimension of y)
            [y,dy,params] = arrayfun(@self.applyProcessFunction,zone,'Uniform',0);
            
            % generate the zone object
            disp = Dispersion('x',x,'y',y,'dy',dy,'parameter',params);
            disp = arrayfun(@(x,y) setfield(x,'parent',y),disp,zone);
        end
    end
    
end



