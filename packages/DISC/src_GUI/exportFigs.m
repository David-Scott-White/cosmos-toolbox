function exportFigs(data, indices, channel_colors)

% close the figure if it is already open
if exist('f','var')
    clf(f);
end
checked = channelSelectDialog(data.names);
% allocate
ax = gobjects(length(checked),3);
for i = checked
    roi = data.rois(indices(1), i);
    trace = roi.time_series;
    if isfield(roi, 'time_s')
        xValue = roi.time_s;
        xLabel = 'Time (s)';
    else
        xValue = 1:1:length(traces); 
        xLabel = 'Frames';
    end
    h = figure; hold on
    plot(xValue, trace, 'color', channel_colors(i,:));
    xlabel(xLabel); 
    ylabel('Intensity (au)')
    
    if isfield(roi, 'disc_fit')
        if ~isempty(roi.disc_fit)
            if ~isempty(roi.disc_fit.ideal)
                plot(xValue, roi.disc_fit.ideal, '-k');
            end
        end
    end
    
    % save the figure; 
    figName = ['roi',num2str(indices(1)), '_channel', num2str(i)];
    [saveName,savePath] = uiputfile([figName,'.mat']);
    
    % save as .fig and .pdf
    publishFigure(h, 'figureSize', [4,2], 'figureName', [savePath, saveName(1:end-4)]); 
    close(h)
end

% save the figure


% figure('units','normalized','outerposition',[0 0 1 1]); % fullscreen
% make the subplots
% for jj=1:length(checked)
%     ax(jj,1) = subplot(length(checked),4,(4*(jj-1)+[1,2]));
%     ax(jj,2) = subplot(length(checked),4,(4*(jj-1)+3));
%     ax(jj,3) = subplot(length(checked),4,(4*(jj-1)+4));
% end
% % fill the subplots based on indices determined in dialog
% for ii = checked
%     row = find(checked==ii);
%     roi = data.rois(indices(1), ii);
%     plotTrajectory(ax(row,1), roi, channel_colors(ii,:));
%     xlabel(ax(row,1), 'Frames'); 
%     ylabel(ax(row,1), 'Intensity (AU)');
%     set(ax(row,1), 'fontsize', 12);
%     set(ax(row,1), 'fontname', 'arial');
%     plotHistogram(ax(row,2), ax(row,1), roi, channel_colors(ii,:));
%     plotMetric(ax(row,3), roi);
% end
    
end

% dialog to select which channels to place in figure
function checked = channelSelectDialog(names)
% create dialog
dspyinfo = get(0,'screensize');
dwidth = 350;
dheight = 100 + 20*length(names);
d = dialog('Position',[0.5*(dspyinfo(3)-dwidth) 0.5*(dspyinfo(4)-dheight) dwidth dheight],...
           'Name','Channels to export to figure at current ROI ...');
% dialog adjusts to number of channels in data set
channelCheck = gobjects(length(names),1);
for ii=1:length(names)
    channelCheck(ii) = uicontrol(d,'style','checkbox','string',names(ii),'Position',[0.5*dwidth-115 dheight-(ii+1)*20 300 20]);
end
% create cancel and export buttons
uicontrol(d,'string','Cancel','Position',...
    [0.5*dwidth-115 25 100 30],'callback','delete(gcf)');
uicontrol(d,'string','Export','Position',...
    [0.5*dwidth+15 25 100 30],'callback',@exportChannelSelect_callback);
uiwait(d);
    % export selected channels to original function; check for null
    % selection
    function exportChannelSelect_callback(~,~)
        vals = get(channelCheck,'Value');
        checked = find([vals{:}]);
        if isempty(checked)
            msgbox('Please select at least one channel to export.','Error','error');
            return
        end
        
        delete(gcf);
    end
end