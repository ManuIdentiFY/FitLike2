classdef MergeBloc < Bloc2Bloc & ProcessDataUnit
    
    properties
        %InputChildClass@char; 	% defined in DataUnit2DataUnit
        %OutputChildClass@char;	% defined in DataUnit2DataUnit
        functionName@char = 'Merge blocs';     % character string, name of the model, as appearing in the figure legend
        labelY@char = '';       % string, labels the Y-axis data in graphs
        labelX@char = '';             % string, labels the X-axis data in graphs
        legendTag@cell = {'Merged'};         % tag appearing in the legend of data derived from this object
    end
        
    methods
        % Constructor
        function this = MergeBloc()
            % call both superclass constructor
            this = this@Bloc2Bloc;
            this = this@ProcessDataUnit;
            % set the ForceDataCat flag to true. Allow to get all the 3D
            % bloc matrix.
            % Warning: output data should be formated as:
            % new_data.x = NBLK x BRLX matrix
            % new_data.y = NBLK x BRLX matrix
            % ...
            %
            this.ForceDataCat = true;
        end % AverageAbs
    end
    
    methods
        % Define abstract method applyProcess(). See ProcessDataUnit.
        function [model, new_data] = applyProcess(this, data, dataList, fitlikeHandle)
            
            model = [];
            new_data.y = [];
            new_data.dy = [];
            
            % only perform the merge operation once
            if ~isequal(data.y,dataList(1).y)                
                return
            end
            
            % make sure this is the very first data set of the
            % selection (to run this process only once)
            relaxObj = getSelectedFile(fitlikeHandle.FileManager);
            bloclist = getData(relaxObj(1), 'Bloc');
            firstdata = getProcessData(this, bloclist(1));
            if ~isequal(data.y,firstdata.y)
                return
            end
            
            % at this point, we know we are running this function for the
            % first time after the user invoked the merge function. We can
            % then proceed with the merging of all similar files.
            % merge all PP and NP acquisitions from similar files
            filename = unique({relaxObj.filename});
            while ~isempty(filename)
                indexMerge = strcmp(filename{1},{relaxObj.filename});
                if sum(indexMerge)>1  % ignore files containing only one type of pulse sequences
                    % make the merged item
                    bloclist = getData(relaxObj(indexMerge), 'Bloc');
                    mergedbloc = merge(bloclist);
                    paramlist = [relaxObj(indexMerge).parameter];
                    mergedparam = merge(paramlist);
                    % add the merged item to the FitLike handle
                    mergedRelaxObj = RelaxObj('data',         mergedbloc,...
                                              'parameter',    mergedparam,...
                                              'label',        relaxObj(indexMerge(1)).label,...
                                              'filename',     filename{1},...
                                              'sequence',     '',...
                                              'dataset',      getRelaxProp(bloclist(1),'dataset'));
                    mergedbloc.relaxObj = mergedRelaxObj;
                    fitlikeHandle.RelaxData(end+1) = mergedRelaxObj;
                    addFile(fitlikeHandle.FileManager, mergedRelaxObj); % add the new object to the file manager
                    mergedRelaxObj.subRelaxObj = relaxObj(indexMerge); % keep the old objects to allow un-merge
                    % remove the old files from the tree manager to avoid
                    % re-processing the initial blocs during the next
                    % algorithm
                    inddelete = find(indexMerge);
                    for indref = 1:numel(inddelete)
                        indrem = find(arrayfun(@(r) isequal(r,relaxObj(inddelete(indref))),fitlikeHandle.RelaxData));
                        deleteFile(fitlikeHandle.FileManager,fitlikeHandle.RelaxData(indrem));
                        remove(fitlikeHandle.RelaxData,indrem);
                    end
                end
                % make sure we don't process a dataset twice
                filename(1) = [];
                % select the new files instead of the old ones
                % TO DO
            end
            
        end %applyProcess
    end
end
