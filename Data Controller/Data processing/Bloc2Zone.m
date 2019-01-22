classdef Bloc2Zone < DataUnit2DataUnit
    
    properties
        InputChildClass@char = 'Bloc';
        OutputChildClass@char = 'Zone';
    end
   
    methods
        function this = Bloc2Zone
            this@DataUnit2DataUnit;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Remove metadata from the function
        % If required, use wrapper(s) to get access [Manu]
        % Need to change the processing model to store parameters from the
        % function inside the processingMethod property [Manu]
        
        % function that applies one processing function to one bloc only.
        % This is where the custom processing function is being called.
        function [zone,bloc] = applyProcessFunction(this,bloc,zone)            
            
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
                
                for i = 1:getRelaxProp(bloc, 'NBLK')                
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
                [z, dz, paramFun] = cellfun(@(x,y,i) process(this,x,y,bloc,i),cellx,celly,cellindex,'Uniform',0);
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
%             params = repmat({params},size(cellz));
            labelX = repmat({this.labelX},size(cellz));
            labelY = repmat({this.labelY},size(cellz));
            if numel(this.legendTag) ~= numel(labelX)
                legendTag = repmat(this.legendTag,size(cellz));
            else
                legendTag = this.legendTag;
            end
            
            % generate the children objects if they are not yet created
            if isempty(this.OutputData)||~prod(isvalid(this.OutputData))
                this.OutputData = Zone('parent',repmat({bloc},size(celldz)),...
                                       'x',x,'xLabel',labelX,...
                                       'y',cellz,'dy',celldz,'yLabel',labelY,...
                                       'legendTag',legendTag,...
                                       'relaxObj',bloc.relaxObj);
            else % if a child object is there, just update it
                this.OutputData = arrayfun(@(z,lx,cz,cdz,ly,l) updateProperties(z,...
                                            'xLabel',lx,...
                                            'y',cz,'dy',cdz,'yLabel',ly,...
                                            'legendTag',l),...
                                            this.OutputData,labelX,cellz,celldz,labelY,legendTag);
            end
            
            zone = this.OutputData;
            bloc = this.InputData;
%             
%             if isempty(this.children)
%                 zone = 
        end
    end

        
end



