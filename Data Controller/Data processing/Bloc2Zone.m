classdef Bloc2Zone < ProcessDataUnit
    
    properties
        
    end
    
    
    methods
        
        function self = Bloc2Zone
            self@ProcessDataUnit;
        end
        
        % function that applies the processing function to one bloc only.
        % This is where the custom processing function is being called.
        function [y,dy,params] = applyProcessFunction(self,bloc)
            sze = size(bloc.y);
            if length(sze)<3
                sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
            end
            % prepare the cell arrays, making sure the dimensions are
            % consistent
            cellx = squeeze(num2cell(bloc.x,1));
            celly = squeeze(num2cell(bloc.y,1));
            cellindex = repmat(num2cell(1:bloc.parameter.paramList.NBLK)',1,size(bloc.y,3));
            if ~isequal(size(cellindex),size(cellx))
                cellx = cellx';
                celly = celly';
            end
            % process the cell array to get the zone data
            [y, dy, paramFun] = cellfun(@(x,y,i) process(self,x,y,bloc.parameter.paramList,i),cellx,celly,cellindex,'Uniform',0);
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
            params = arrayofstruct2struct(paramFun);
            fh = str2func(class(bloc.parameter));
            params = fh(params);
            params = reshape(params,size(y));
            params = merge(bloc.parameter,params);
        end
        
        % TO DO: make some test functions
                        
        % Function that makes the actual processing of the bloc. It only
        % deals with one bloc at a time and creates one zone only.
        function zone = makeZone(self,bloc)
            % check that all the input objects are bloc objects
            
            
            % generate the data to populate the zone object
            x = getZoneAxis(bloc); % raw x-axis (needs to be repmat to fit the dimension of y)
            [y,dy,params] = arrayfun(@self.applyProcessFunction,bloc,'Uniform',0);
            
            % generate the zone object
            zone = Zone('x',x,'y',y,'dy',dy,'parameter',params);
                
        end
    end
    
end



