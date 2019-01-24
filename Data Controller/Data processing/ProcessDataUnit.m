classdef ProcessDataUnit < matlab.mixin.Heterogeneous% < handle
% this class defines the structure and general attibute of all the objects
% that are used to process the data units. It aims at facilitating
% operations on the processing functions, to streamline the creation of
% new models and to make it easier to make new models for begginers.
%
% L Broche, University of Aberdeen, 6/7/18

    properties (Abstract)
        functionName@char       % character string, name of the model, as appearing in the figure legend
        labelY@char             % string, labels the Y-axis data in graphs
        labelX@char             % string, labels the X-axis data in graphs
        legendTag@cell          % cell of strings, contain the legend associated with the data processed
    end
    
    properties
        parameter@struct        % structure containing parameters associated with the process (weighted, robust fit, log,...)
    end
    
    methods
        function self = ProcessDataUnit(varargin)
            % parsing the inputs, using the typical format ('param1',
            % value1, 'param2', value2,...)
            for i = 1:2:length(varargin)
                if isprop(model,varargin{i})
                    model = setfield(model,varargin{i},varargin{i+1}); %#ok<SFLD>
                end
            end
            % make some simple checks
            if ~selfCheck(self)
                error('Inconsistent inputs, object not created.')
            end
        end
        
        % test function to verify the object integrity (TO DO)
        function out = selfCheck(self)
            out = 1;
        end
%         
%         % main process function
%         function [childObj, parentObj] = processData(this, parentObj)
%             % get data
%             data = getProcessData(this, parentObj);
%             
%             % apply process
%             [this, new_data] = arrayfun(@(x) applyProcess(this, x, parentObj), data, 'Uniform', 0);
%             
%             % gather data and create childObj
%             childObj = makeProcessData(this, new_data, parentObj);           
%         end %processData
%         
%         
        % main process function
        function [childObj, parentObj] = processData(this, parentObj)
            % get data
            data = getProcessData(this, parentObj);
            
            % apply process
            [model, new_data] = arrayfun(@(x) applyProcess(this, x), data, 'Uniform', 0);
            
            % format output
            new_data = formatData(this, new_data);
            this = formatModel(this, model);
                        
            % assign process in parentObj (to test, Manu)
            parentObj.processingMethod = this;
            
            % gather data and create childObj
            childObj = makeProcessData(this, new_data, parentObj);     
            
            % add other data (xLabel, yLabel,...)
            childObj = addOtherProp(this, childObj);
        end %processData
   
        % function that applies one processing function to one bloc only.
        % This is where the custom processing function is being called.
%         function [outputdata,inputdata] = applyProcessFunction(this)  
%             
%             sze = size(this.InputData.y);
%             if length(sze)<3
%                 sze(3) = 1;   % make sure the data is interpreted as a 3D matrix
%             end
%             % prepare the cell arrays, making sure the dimensions are
%             % consistent
%             cellx = squeeze(num2cell(this.InputData.x,1));
%             celly = squeeze(num2cell(this.InputData.y,1));
%             % make sure the data is sorted
%             [cellx,ord] = cellfun(@(c)sort(c),cellx,'UniformOutput',0);
%             celly = cellfun(@(c,o)c(o),celly,ord,'UniformOutput',0);
%             % cast to cell array for cellfun
% %             cellindex = repmat(num2cell(1:this.InputData.parameter.paramList.NBLK)',1,size(this.InputData.y,3));
%             if isempty(this.InputData.y)
%                 z = [];
%                 dz = [];
%                 this.ProcessData = {};
%             else
%                 for i = 1:getRelaxProp(this.InputData, 'NBLK')                
%                     for j = 1:size(this.InputData.y,3)
%                         cellindex{i,j} = [i,j]; %#ok<AGROW>
%                     end
%                 end
%                 if ~isequal(size(cellindex),size(cellx))
%                     cellx = cellx';
%                     celly = celly';
%                 end
%                 % make sure that each acquisition is referenced from the time
%                 % of acquisition within the data this.InputData
%                 cellx = cellfun(@(x)x-x(1),cellx,'UniformOutput',0);
%                 % process the cell array to get the this.OutputData data
%                 [z, dz, this.ProcessData] = cellfun(@(x,y,i) process(this,x,y,this.InputData,i),cellx,celly,cellindex,'Uniform',0);
%                 szeout = size(z{1,1});
%                 [szeout,ind] = max(szeout); 
%                 if ind == 2 % check that the result of the process is a column array
%                     z = reshape(cell2mat(z),sze(2),szeout,sze(3));
%                     dz = reshape(cell2mat(dz),sze(2),szeout,sze(3));
%                 else
%                     z = reshape(cell2mat(z),szeout,sze(2),sze(3));
%                     z = permute(z,[2 1 3]);
%                     dz = reshape(cell2mat(dz),szeout,sze(2),sze(3));
%                     dz = permute(dz,[2 1 3]);
%                 end
%             end
%             
%             % generate one this.OutputData object for each component provided by the
%             % processing algorithm
%             warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved') % avoid spamming the terminal when the data is not multiexponential
%             cellz = mat2cell(z,size(z,1),ones(1,size(z,2)),size(z,3));
%             celldz = mat2cell(dz,size(dz,1),ones(1,size(dz,2)),size(dz,3));
%             cellz = cellfun(@(x) squeeze(x),cellz,'UniformOutput',0);
%             celldz = cellfun(@(x) squeeze(x),celldz,'UniformOutput',0);
%             x = getZoneAxis(this.InputData); % raw x-axis (needs to be repmat to fit the dimension of y)
%             x = repmat(x,size(cellz)); % make sure that all cell arrays are consistent
% %             params = repmat({params},size(cellz));
%             labelX = repmat({this.labelX},size(cellz));
%             labelY = repmat({this.labelY},size(cellz));
%             if numel(this.legendTag) ~= numel(labelX)
%                 legendTag = repmat(this.legendTag,size(cellz));
%             else
%                 legendTag = this.legendTag;
%             end
%             
%             % generate the children objects if they are not yet created
%             if isempty(this.OutputData)
%                 this.OutputData = Zone('parent',repmat({this.InputData},size(celldz)),...
%                                        'x',x,'xLabel',labelX,...
%                                        'y',cellz,'dy',celldz,'yLabel',labelY,...
%                                        'legendTag',legendTag,...
%                                        'relaxObj',this.InputData.relaxObj);
%             else % if a child object is there, just update it
%                 this.OutputData = arrayfun(@(z,lx,cz,cdz,ly,l) updateProperties(z,...
%                                             'xLabel',lx,...
%                                             'y',cz,'dy',cdz,'yLabel',ly,...
%                                             'legendTag',l),...
%                                             this.OutputData,labelX,cellz,celldz,labelY,legendTag);
%             end
%             outputdata = this.OutputData;
%             inputdata = this.InputData;
%         end
        
        % format output data from process: cell array to array of structure
        % This function could also be used to modify this in order to
        % gather all fit data for instance [Manu]
        function this = formatModel(this, model)
            
        end %formatData
        
        % add other properties (xLabel, yLabel, legendTag
        function childObj = addOtherProp(this, childObj)
            % add xLabel and yLabel
            [childObj.xLabel] = deal(this.labelX);
            [childObj.yLabel] = deal(this.labelY);
            
            % add legendTag
            [childObj.legendTag] = this.legendTag{:};
        end %addOtherProp
    end
    
    methods (Abstract)
        applyProcess(this, data, parentObj)
    end
    
%     methods (Abstract)
%         function [this, new_data] = applyProcess(this, data, parentObj)
%             
%         end %applyProcess
%     end
%       
%         % function that allows estimating the start point. It should be 
%         % over-riden by the derived classes
%         function self = evaluateStartPoint(self,x,y)
%         end
        
%         function [newData, dataObj] = processData(self,dataObj)
%             newData = dataObj;
%         end
    
%     methods (Abstract)
%         
%         [newData, dataObj] = processData(self,dataObj)
%         
%     end
    
end