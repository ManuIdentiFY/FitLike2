function out = removeBaselineQP(hDispersion, qp_range, mdl)
%
% This function create a small GUI where user can remove the baseline from
% the Quadrupolar peaks. The baseline is a linear function.
% It is also possible to remove some files (will be included in out).

% INPUT:
% hDispersion: 1xN Dispersion object
% qp_range: [min max] vector for qp boundaries
% mdl: DispersionModel object (QP model should have 6 parameters in this
% version). For instance: QPFriesBelorizkyNormalised().

% OUTPUT:
% out: structure containing all the information accumulated during the
% process.
% Organized as:
% out.rejected: 1xM Dispersion object not accepted
% out.accepted: 1xL Dispersion object accepted (L+M = N)
% out.qp: 1xL Dispersion object containing the QP information (they are
% exactly like the right plot on the GUI, including the fit)
% out.baseline: 1xL [a b] vector containing the coefficient for the
% baseline chosen (y = a*x + b)

% M.Petit - 10/2018
% manuel.petit@inserm.fr

% check input
if ~isa(hDispersion, 'Dispersion') || isempty(hDispersion)
    error('Data should be Dispersion class unit')
end

% check if relaxObj (RelaxObj) is attached to the Dispersionobject
tf_relax = arrayfun(@(x) isa(x.relaxObj,'RelaxObj'), hDispersion);
if all(tf_relax == 0)
    error('No RelaxObj is linked to the Dispersion objects (see the relaxObj property in DataUnit).')
elseif any(tf_relax == 0)
    warning('Some Dispersion objects are not linked to RelaxObj. They have been ignored.');
    hDispersion = hDispersion(tf_relax);
end
    

if numel(qp_range) ~= 2 
    error('Range should contain both boundaries!')
elseif qp_range(1) > qp_range(2)
    error('Wrong qp boundaries')
end

% init count
n = numel(hDispersion);
k = 1;

% create fig and buttons
fig = figure('Unit','normalized','Position',[0.25 0.15 0.7 0.7]);
h = uipanel('Parent',fig, 'Position',[0 0.2 1 0.8]);

ax1 = subplot(1,2,1,'Parent',h);
ax2 = subplot(1,2,2,'Parent',h,'NextPlot','add');

% add option buttons 
opts = uipanel('Parent',fig, 'Position',[0 0 0.3 0.2]);
bg = uibuttongroup(opts);

uicontrol(bg, 'Style', 'pushbutton', 'String', 'Rejected',...
    'Units','normalized','Position',[0.15 0.05 0.3 0.3],...
    'ForegroundColor',[0.8500 0.3250 0.0980],'Callback', @(s,e) next(s,e));

uicontrol(bg, 'Style', 'pushbutton', 'String', 'Accepted',...
    'Units','normalized','Position',[0.15 0.55 0.3 0.3],...
    'ForegroundColor',[0.4660 0.6740 0.1880],'Callback', @(s,e) next(s,e));

uicontrol(bg, 'Style', 'pushbutton', 'String', 'Draw Baseline',...
    'Units','normalized','Position',[0.55 0.05 0.3 0.3],...
    'Callback', @(s,e) drawbaseline());

uicontrol(bg, 'Style', 'pushbutton', 'String', 'Smooth',...
    'Units','normalized','Position',[0.55 0.55 0.3 0.3],...
    'Callback', @(s,e) smoothline());

% add model buttons 
opts2 = uipanel('Parent',fig, 'Position',[0.3 0 0.7 0.2]);
bg2 = uibuttongroup(opts2,'Position',[0.01 0.05 0.2 0.86]);

uicontrol(bg2, 'Style', 'pushbutton', 'String', 'Apply Fit',...
    'Units','normalized','Position',[0.1 0.1 0.8 0.3],...
    'Callback', @(s,e) applyFit());

uicontrol(bg2, 'Style', 'pushbutton', 'String', 'Set Boundaries',...
    'Units','normalized','Position',[0.1 0.55 0.8 0.3],...
    'Callback', @(s,e) setBound());

% add parameter panel to modify starting point
h = uipanel(opts2,'Title','Model Parameters','Position',[0.22 0.05 0.55 0.9]);
PnlOpt.title = 'Parameter Tool';
PnlOpt.bordertype = 'none';
PnlOpt.titleposition = 'centertop';
PnlOpt.fontweight = 'bold';
EditOpts = {'fontsize',8};
LabelOpts = {'fontsize',7,'fontweight','b'};
numFormat = '%0.0f';
startPos = {[0.05 0.05 0.3 0.4];
	        [0.05 0.55 0.3 0.4];
	        [0.35 0.05 0.3 0.4];
	        [0.35 0.55 0.3 0.4];
            [0.65 0.05 0.3 0.4];
            [0.65 0.55 0.3 0.4]};
idx = [2 1 4 3 6 5];        
        
for ii = 1:numel(idx)
	PnlOpt.position = startPos{ii};
	PnlOpt.title = mdl.parameterName{idx(ii)};
    SldrOpt.min = mdl.minValue(idx(ii));
    SldrOpt.max = mdl.maxValue(idx(ii));
    SldrOpt.value = mdl.startPoint(idx(ii)); 
    SldrOpt.callback = @(s,e) setStartPoint(s, e);
	sliderPanel(h,PnlOpt,SldrOpt,EditOpts,LabelOpts,numFormat);
end

% add model results
bg3 = uipanel(opts2,'Title','Model Results','Position',[0.78 0.05 0.21 0.9]);

startPos = {[0.05 0.01 0.4 0.25];
	        [0.05 0.31 0.4 0.25];
	        [0.05 0.61 0.4 0.25];
	        [0.55 0.01 0.4 0.25];
            [0.55 0.31 0.4 0.25];
            [0.55 0.61 0.4 0.25]};
idx = [4 2 1 6 5 3];   
for ii = 1:numel(idx)
    txt = sprintf('%s =', mdl.parameterName{idx(ii)});
    uicontrol(bg3, 'Style', 'text', 'String', txt,...
        'HorizontalAlignment','left','Units','normalized',...
        'Position',startPos{ii},'Tag', mdl.parameterName{idx(ii)});
end



% init ax1
plotDisp();

% init out
out = [];

% wait for the end of file
waitfor(fig)  

%%% Callback
    function drawbaseline()
        % check if baseline already exists
        baseline = findobj(ax1.Children,'tag','imline');
        if ~isempty(baseline)
            delete(baseline);
        end
        % draw line
        baseline = imline(ax1);
        % plotQP
        plotQP();
        % add callback to update the other graph when changing baseline position
        addNewPositionCallback(baseline, @getPos);
    end %drawbaseline

    function next(source, ~)
        % check source
        if strcmp(source.String, 'Rejected')
            % get the current dispersion object            
            out(end+1).rejected = hDispersion(k); 
        else
            % get the QP
            hPlot = findobj(ax2.Children,'Tag','QP');
            % check if baseline was drawned
            if isempty(hPlot)
                warndlg('You need to plot baseline!')
            else
                % get the current dispersion object     
                coeff = hPlot.UserData{2};
                out(end+1).accepted = hDispersion(k); 
                out(end).qp = hPlot.UserData{1};
                out(end).baseline = struct('a',coeff(1),'b',coeff(2));
            end
        end
        % go next if possible
        k = k + 1;
        resetAxis();
    end %next

    function resetAxis()
        % check if possible to plot object
        if k > n
            delete(fig)
            return
        else
            % clear axis
            cla(ax1);
            cla(ax2);
            % plot new data
            plotDisp();
        end
    end %resetAxis

    function plotDisp()
        % get the current object
        obj = hDispersion(k);
        % plot data in the first axis
        errorbar(ax1, obj.x(obj.mask), obj.y(obj.mask), obj.dy(obj.mask),...
            'LineStyle','none','Marker','o','MarkerSize',6,...
            'MarkerFaceColor','auto','tag','Dispersion','DisplayName',getRelaxProp(obj,'filename'));
        % set axis
        dx = diff(obj.x(obj.mask));
        if max(abs(dx - dx(1))) > 0.1
            set(ax1, 'XScale', 'log');
        end
        yl = get(ax1,'YLim');
        set(ax1,'YLim',[0 yl(2)]);
        % add range for visual purpose
        y = ylim(ax1);
        line(ax1, [qp_range(1) qp_range(1)],y,'Color','red','LineStyle','--','DisplayName','QP range');
        hl = line(ax1, [qp_range(2) qp_range(2)],y,'Color','red','LineStyle','--');
        hl.Annotation.LegendInformation.IconDisplayStyle = 'off';
        xlabel(ax1, 'Magnetic Field (Hz)');
        ylabel(ax1, 'Relaxation Rate (s^{-1})');
        title(ax1, 'Dispersion curve');
        legend(ax1, 'show');
    end %plotDisp

    function getPos(pos)
        % get the baseline position and find the equation ax+b
        a = (log(pos(2,2)) - log(pos(1,2)))/(pos(2,1)-pos(1,1));
        b = log(pos(1,2)) - a*pos(1,1);
        % update the QP axis
        plotQP(a,b)
    end

    function plotQP(a,b)
        % if position is not provided, get the baseline object and get it
        if nargin == 0
            % get the baseline obj
            baseline = findobj(ax1.Children,'tag','imline');
            api = iptgetapi(baseline);
            pos = api.getPosition();
            % calculate the baseline equation
            a = (log(pos(2,2)) - log(pos(1,2)))/(pos(2,1)-pos(1,1));
            b = log(pos(1,2)) - a*pos(1,1);
        end
        % get the range defined
        obj = hDispersion(k);
        range = obj.x > qp_range(1) & obj.x < qp_range(2);
        mask = obj.mask & range;
        % get the current object and calculate the y_qp values according to
        % the baseline equation.
        x = obj.x(mask);
        y = obj.y(mask) - exp(a.*x + b);
        dy = obj.dy(mask);   
        % calculate also the new y_values for the plot(can be different if
        % smoothing!)
        hPlotDisp = findobj(ax1.Children,'Tag','Dispersion');
        y_plot = hPlotDisp.YData(mask(obj.mask)) - exp(b + a.*hPlotDisp.XData(mask(obj.mask)));
        % check if current QP plot already exists
        if isempty(ax2.Children)
            % get the data and create a new Dispersion object
            obj_qp = Dispersion('x',x,'y',y,'dy',dy,...
                            'xLabel',obj.xLabel, 'yLabel',obj.yLabel,...
                            'relaxObj',obj.relaxObj,'legendTag',obj.legendTag,...
                            'displayName',obj.displayName);                
            % plot
            hPlotQP = errorbar(ax2, x, y_plot, [], dy,...
                'LineStyle','none','Marker','o','MarkerSize',6,...
                'MarkerFaceColor','auto','Tag','QP','DisplayName',getRelaxProp(obj_qp,'filename'));
            % set axis
            dx = diff(x);
            if max(abs(dx - dx(1))) > 0.1
                set(ax2, 'XScale', 'log');
            end
            xlabel(ax2, 'Magnetic Field (Hz)');
            ylabel(ax2, 'Relaxation Rate (s^{-1})');
            title(ax2, 'Quadrupolar Peak: Baseline removed');
            legend(ax2, 'show');
            set(ax2,'YGrid','on');
        else
            % get the current QP plot
            hPlotQP = findobj(ax2.Children,'Tag','QP');
            % get and update the qp object
            obj_qp = hPlotQP.UserData{1};
            [obj_qp.x, indx] = sort(x);
            obj_qp.y = y(indx);
            obj_qp.dy = dy(indx);
            % update plot values
            hPlotQP.XData = hPlotDisp.XData(mask(obj.mask));
            hPlotQP.YData = y_plot;
            hPlotQP.YPositiveDelta = hPlotDisp.YPositiveDelta(mask(obj.mask));
        end
        
        % store the new data
       hPlotQP.UserData{1} = obj_qp;
       hPlotQP.UserData{2} = [a,b];
    end %plotQP

    function smoothline()
        % apply a savitzky-golay filtering in order to smooth the curve
        % check if previous smoothing was applied
        hPlot = findobj(ax1.Children,'Tag','Dispersion');
        if isempty(hPlot.UserData)
            % apply smooth
            hPlot.YData = smooth(hPlot.YData,5,'sgolay',2);
            % put dummy data in userdata
            hPlot.UserData = 'sgolay';
        else
            % get original data
            obj = hDispersion(k);            
            hPlot.XData = obj.x(obj.mask);
            hPlot.YData = obj.y(obj.mask);
            hPlot.YPositiveDelta = obj.dy(obj.mask);
            hPlot.YNegativeDelta = -obj.dy(obj.mask);
            % reset userdata
            hPlot.UserData = [];
        end
        % check if QP plot exists
        if ~isempty(ax2.Children)
            plotQP()
        end
    end %smoothline

    function applyFit()
        % get the QP plot
        hPlotQP = findobj(ax2.Children,'Tag','QP');
        % check if QP plot exists
        if isempty(hPlotQP)
            warndlg('You need to set a baseline before fitting!')
            return
        end
        % get the current qp object        
        obj_qp = hPlotQP.UserData{1};
        % check if another fit already exists
        hFit = findobj(ax2.Children,'type','line');
        if ~isempty(hFit)
            delete(hFit);
        end        
        % for the fit only: get absolute y-values (avoid errors)
        s = sign(obj_qp.y);
        obj_qp.y = abs(obj_qp.y);
        % apply fit
        try
            processData(obj_qp, mdl); 
        catch
            obj_qp.y = s.*obj_qp.y;
            warndlg('Fit did not succeed!')
            return
        end
        
        %%% ----- Small test ---------- %%%
%         % cast logical
%         mdl.isFixed = logical(mdl.isFixed);
%         fo = fitoptions('Method','NonlinearLeastSquares',...
%                         'Lower',mdl.minValue(~mdl.isFixed),...
%                         'Upper',mdl.maxValue(~mdl.isFixed),...
%                         'StartPoint',mdl.startPoint(~mdl.isFixed));
%         ft = fittype([mdl.modelEquation ],...
%                        'independent',mdl.variableName,...                           
%                        'coefficients',mdl.parameterName(~mdl.isFixed),...
%                        'problem',mdl.parameterName(mdl.isFixed),...
%                        'options',fo);
%         if size(obj_qp.x,2)>1; x = obj_qp.x'; else x = obj_qp.x; end
%         if size(obj_qp.y,2)>1; y = obj_qp.y'; else y = obj_qp.y; end
%         
%         [fitres, gof] = fit(x, y,ft,...
%             'problem',num2cell(mdl.startPoint(mdl.isFixed)),'Robust','bisquare');
%             %'Weights',1./(obj_qp.dy.^2)); 
%         
%         mdl.bestValue(~mdl.isFixed) = coeffvalues(fitres)';
%         mdl.bestValue(mdl.isFixed) = mdl.startPoint(mdl.isFixed);
%         
%         err = bsxfun(@minus, confint(fitres)', mdl.bestValue(~mdl.isFixed)');
%         mdl.errorBar(~mdl.isFixed,:) = err; 
%         mdl.errorBar(mdl.isFixed,:) = NaN(length(find(mdl.isFixed)),2);     
%         
%         mdl.gof = gof;
%         mdl.fitobj = fitres;
        %%% --------------------------- %%%    
        obj_qp.y = s.*obj_qp.y;      
%         obj_qp.processingMethod.subModel = mdl;
%         obj_qp.processingMethod.model.bestValue = mdl.bestValue;
%         obj_qp.processingMethod.model.errorBar = mdl.errorBar;
%         obj_qp.processingMethod.model.gof = mdl.gof;
        % plot result
        fitname = sprintf('QP Fit (R^2 = %.3f)', obj_qp.processingMethod.gof.rsquare);
        plot(ax2, obj_qp.x, evaluate(obj_qp.processingMethod, obj_qp.x),...
            'LineStyle','-','Marker','none',...
            'Color',[0.8500    0.3250    0.0980],...
            'DisplayName',fitname,'Tag','Fit');
        % update result
        setModelRes(obj_qp.processingMethod)
    end %applyFit

    function setStartPoint(source, ~)
        % check which slider was modified
        name = source.Parent.Title;
        parameter = mdl.parameterName;
        tf = strcmp(parameter, name);
        % modified the starting point of this parameter
        mdl.startPoint(tf) = source.Value;
    end %setStartPoint

    function setModelRes(model)
        % loop over the model parameters and update their result
        for i = 1:numel(mdl.parameterName)
            % find the obj
            hObj = findobj(bg3,'Tag',mdl.parameterName{i});
            % update string
            str = sprintf('%s = %0.3g',mdl.parameterName{i}, model.bestValue(i));
            hObj.String = str;
        end
    end %setModelRes
end

