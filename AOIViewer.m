classdef AOIViewer < handle
    % AOI viewer
    % input is hImageStack
    % 4 axes figure handle
    
    
    properties
        
        hAOI
        hName
        hTime_s
        
        hGallery
        hColor = 'grey'
        hPlotColor = 'blue'
        hIdealColor = 'black'
        hPlotMarker = 'line'
        
        hPanel
        hAxesGallery % top
        hAxesTimeSeries % bottom left
        hAxesHistogram % bottom right
        hButtonPrev
        hButtonNext
        hButtonName
        hButtonZoom
        hButtonReset
        hButtonMenu
        hSlider
        
        showGallery = 1;
        showTimeSeries = 1;
        showHistogram = 1;
        
        testMenu
        GridOn = 'on'
        
    end
    
    properties (Dependent)
        Parent % hPanel.Parent
        Position % hPanel.Position
        numAOI
        ContextMenu
        AOILabel
    end
    
    properties (SetObservable)
        ColorMap
        PlotColor
        PlotMarker
        IdealColor
        hBC
        idx
        hLayout
        
    end
    
    methods
        % Constructor
        function obj = AOIViewer(x, parent)
            % x can be AOI or ImageStack
            obj.hAOI = [];
            obj.hName = '';
            obj.hTime_s = [];
            
            switch class(x)
                case {'ImageStack'}
                    obj.hAOI = x.AOIs;
                    obj.hName = x.name;
                    obj.hTime_s = x.time_s;
            end
            obj.idx = 1;
            
            % make input aoi and aoi setting
            % main panel will hold all other UI elements
            obj.hPanel = uipanel( ...
                'BorderType', 'none', ...
                'AutoResizeChildren', 'off', ... % will be handeld by resize()
                'UserData', obj, ... % ref this object
                'Visible', 'Off');
            if exist('parent', 'var') && ~isempty(parent) && isvalid(parent) && isgraphics(parent)
                obj.hPanel.Parent = parent;
            else
                obj.hPanel.Parent.NumberTitle = 'Off';
                obj.hPanel.Parent.MenuBar = 'None';
                obj.hPanel.Parent.Name = 'AOI Viewer';
            end
            
            % max of 4 axes. Two main, 2 small. resize when turned on and off
            obj.hAxesGallery = axes(obj.hPanel,...
                'Units', 'pixels',...
                'XTick', [],...
                'YTick', [],...
                'box', 'on');
            
            obj.hGallery = imagesc(obj.hAxesGallery, [],...
                'HitTest', 'off',...
                'PickableParts', 'none');
            axis(obj.hAxesGallery, 'image');
            colormap(obj.hAxesGallery, obj.ColorMap);
            
            obj.hAxesTimeSeries = axes(obj.hPanel,...
                'Units', 'pixels',...
                'XTick', [],...
                'YTick', [],...
                'box', 'on');
            
            obj.hAxesHistogram = axes(obj.hPanel,...
                'Units', 'pixels',...
                'XTick', [],...
                'YTick', [],...
                'box', 'on');
            
            obj.hButtonPrev = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', '<',...
                'Visible', 'Off',....
                'Callback', @(src,event)prevAOI(obj));
            
            obj.hButtonNext = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', '>',...
                'Visible', 'Off',....
                'Callback', @(src,event)nextAOI(obj));
            
            obj.hButtonName = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', 'Button Top Left',...
                'Visible', 'Off');
            
            obj.hButtonZoom = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', '<HTML> &#8981; <HTML>',...
                'Visible', 'Off');
            
            obj.hButtonReset = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', '<HTML> &#10530 <HTML>',...
                'Visible', 'Off');
            
            obj.hButtonMenu = uicontrol(obj.hPanel,...
                'Style', 'Pushbutton', ...
                'String', '<HTML> &#10070 <HTML>',...
                'Visible', 'Off',...
                'Callback', @(src,event)menuButtonPushed(obj, event));
            obj.hButtonMenu.ContextMenu = obj.ContextMenu;
            
            obj.hPanel.Visible = 'on';
            obj.resize();
            obj.updateAOI(1);
            
            
            % -------------------------------------------------------------
            % Listeners
            % -------------------------------------------------------------
            obj.hPanel.SizeChangedFcn = @(varargin) obj.resize();
            addlistener(obj, 'idx', 'PostSet', @(varargin) obj.updateAOI(0));
            % addlistener(obj, 'hLayout', 'PostSet', @(varargin) obj.resize());
            
        end
        
        function cm = get.ContextMenu(obj)
            cm = uicontextmenu;
            
            % Image Display -----------------------------------------------
            mView = uimenu(cm,"Text", "View");
            obj.testMenu = uimenu(mView, 'Text', 'Gallery', 'Checked', 'off', 'Callback', @(varargin)obj.menuViewChanged('gallery'));
            uimenu(mView, 'Text', 'Time Series', 'Checked', 'off','Callback', @(varargin)obj.menuViewChanged('timeseries'));
            uimenu(mView, 'Text', 'Histogram', 'Checked', 'off', 'Callback', @(varargin)obj.menuViewChanged('histogram'));
            
            mImage = uimenu(cm,"Text", "Gallery");
            % uimenu(mImage,"Text", "Brightness & Contrast", 'Callback', @(varargin)obj.menuLaunchBC());
            mImageColor = uimenu(mImage, 'Text', 'color', 'Separator', 'off');
            uimenu(mImageColor, 'Text', 'grey','Callback', @(varargin)obj.menuGalleryColorChanged('grey'));
            uimenu(mImageColor, 'Text', 'blue','Callback', @(varargin)obj.menuGalleryColorChanged('blue'));
            uimenu(mImageColor, 'Text', 'green','Callback', @(varargin)obj.menuGalleryColorChanged('green'));
            uimenu(mImageColor, 'Text', 'red', 'Callback', @(varargin)obj.menuGalleryColorChanged('red'));
            uimenu(mImageColor, 'Text', 'yellow','Callback', @(varargin)obj.menuGalleryColorChanged('yellow'));
            uimenu(mImageColor, 'Text', 'pink','Callback', @(varargin)obj.menuGalleryColorChanged('pink'));
            uimenu(mImageColor, 'Text', 'teal','Callback', @(varargin)obj.menuGalleryColorChanged('teal'));
            
            mTrace = uimenu(cm, 'Text', 'Trace');
            mPlotColor = uimenu(mTrace, 'Text', 'color', 'Separator', 'off');
            uimenu(mPlotColor, 'Text', 'grey','Callback', @(varargin)obj.menuPlotColorChanged('grey'));
            uimenu(mPlotColor, 'Text', 'blue','Callback', @(varargin)obj.menuPlotColorChanged('blue-d'));
            uimenu(mPlotColor, 'Text', 'light blue','Callback', @(varargin)obj.menuPlotColorChanged('blue-l'));
            uimenu(mPlotColor, 'Text', 'green','Callback', @(varargin)obj.menuPlotColorChanged('green'));
            uimenu(mPlotColor, 'Text', 'red', 'Callback', @(varargin)obj.menuPlotColorChanged('red'));
            uimenu(mPlotColor, 'Text', 'yellow','Callback', @(varargin)obj.menuPlotColorChanged('yellow'));
            uimenu(mPlotColor, 'Text', 'purple','Callback', @(varargin)obj.menuPlotColorChanged('purple'));
            uimenu(mPlotColor, 'Text', 'orange','Callback', @(varargin)obj.menuPlotColorChanged('orange'));
            uimenu(mPlotColor, 'Text', 'black','Callback', @(varargin)obj.menuPlotColorChanged('black'));
            
            mPlotGrid = uimenu(mTrace, 'Text', 'Grid', 'Separator', 'off');
            uimenu(mPlotGrid, 'Text', 'On','Callback', @(varargin)obj.menuGridOnOff('on'));
            uimenu(mPlotGrid, 'Text', 'Off','Callback', @(varargin)obj.menuGridOnOff('off'));
            
            % add somthing for plot type
            mPlotMarker = uimenu(mTrace, 'Text', 'marker', 'Separator', 'off');
            uimenu(mPlotMarker, 'Text', 'line','Callback', @(varargin)obj.menuPlotMarkerChanged('line'));
            uimenu(mPlotMarker, 'Text', 'circle','Callback', @(varargin)obj.menuPlotMarkerChanged('circle'));
            uimenu(mPlotMarker, 'Text', 'line & circle','Callback', @(varargin)obj.menuPlotMarkerChanged('line&circle'));
            
            % Idealization ------------------------------------------------
            mIdeal = uimenu(cm,"Text", "Ideal");
            uimenu(mIdeal,"Text", "Idealize AOI", 'Callback', @(varargin)obj.idealizeAOI());
        end
        
        % Parent & Position -----------------------------------------------
        function h = get.Parent(obj)
            h = obj.hPanel.Parent;
        end
        function set.Parent(obj, h)
            obj.hPanel.Parent = h;
        end
        function bbox = get.Position(obj)
            bbox = obj.hPanel.Position;
        end
        function set.Position(obj, bbox)
            obj.hPanel.Position = bbox;
            obj.resize();
        end
        
        function n = get.numAOI(obj)
            n = length(obj.hAOI);
        end
        
        function nextAOI(obj)
            i = obj.idx + 1;
            if i > obj.numAOI
                i = obj.numAOI;
            end
            obj.idx = i;
            obj.updateAOI(0)
        end
        
        function prevAOI(obj)
            i = obj.idx - 1;
            if i < 1
                i = 1;
            end
            obj.idx = i;
            obj.updateAOI(0)
        end
        
        
        function menuButtonPushed(obj, ~)
            obj.hPanel.Units = 'Pixels';
            x = [obj.hButtonMenu.Position(1)+obj.hButtonMenu.Position(3),obj.hButtonMenu.Position(2)+obj.hButtonMenu.Position(4)] + obj.hPanel.Position(1:2);
            obj.hButtonMenu.ContextMenu.Position = x-[0,10];
            obj.hButtonMenu.ContextMenu.Visible = 1;
            obj.hPanel.Units = 'Normalized';
        end
        
        function menuViewChanged(obj, whatChanged)
            switch whatChanged
                case {'gallery'}
                    obj.showGallery = ~obj.showGallery;
                    
                case {'timeseries'}
                    obj.showTimeSeries = ~obj.showTimeSeries;
                    
                case {'histogram'}
                    obj.showHistogram = ~obj.showHistogram;
                    
            end
            obj.hLayout;
            obj.resize();
        end
        
        function l = get.hLayout(obj)
            
            if  obj.showGallery && obj.showTimeSeries && obj.showHistogram
                l = '3';
            elseif obj.showGallery && obj.showTimeSeries && ~obj.showHistogram
                l = '2b';
            elseif ~obj.showGallery && obj.showTimeSeries && obj.showHistogram
                l = '2a';
            elseif obj.showGallery && ~obj.showTimeSeries && ~obj.showHistogram
                l = '1b';
            elseif ~obj.showGallery && obj.showTimeSeries && ~obj.showHistogram
                l = '1a';
            elseif  ~obj.showGallery && ~obj.showTimeSeries && obj.showHistogram
                l = '1c';
            else
                obj.showHistogram = 1;
                obj.showHistogram = 1;
                obj.showTimeSeries = 1;
                l = '3';
            end
        end
        
        % Colormap (i.e., psuedocolor) ------------------------------------
        function colorMap = get.ColorMap(obj)
            % Psuedo color grayscale image
            colorMap = zeros(256, 3);
            switch obj.hColor
                case 'red'
                    colorMap(:,1) = linspace(0,1,256);
                case 'green'
                    colorMap(:,2) = linspace(0,1,256);
                case 'blue'
                    colorMap(:,3) = linspace(0,1,256);
                case 'yellow'
                    colorMap(:,1) = linspace(0,1,256);
                    colorMap(:,2) = linspace(0,1,256);
                case 'pink'
                    colorMap(:,1) = linspace(0,1,256);
                    colorMap(:,3) = linspace(0,1,256);
                case 'teal'
                    colorMap(:,2) = linspace(0,1,256);
                    colorMap(:,3) = linspace(0,1,256);
                case {'gray', 'grey'}
                    colorMap(:,1) = linspace(0,1,256);
                    colorMap(:,2) = linspace(0,1,256);
                    colorMap(:,3) = linspace(0,1,256);
                otherwise
                    colorMap(:,1) = linspace(0,1,256);
                    colorMap(:,2) = linspace(0,1,256);
                    colorMap(:,3) = linspace(0,1,256);
            end
        end
        
        function plotColor = get.PlotColor(obj)
            switch obj.hPlotColor
                case 'grey'
                    plotColor = [0.7,0.7,0.7];
                case {'blue', 'blue-d'}
                    plotColor = [0, 0.4470, 0.7410];
                case {'blue-l'}
                    plotColor = [0.3010, 0.7450, 0.9330];
                case 'green'
                    plotColor = [0.4660, 0.6740, 0.1880];
                case 'red'
                    plotColor = [0.6350, 0.0780, 0.1840];
                case 'yellow'
                    plotColor = [0.9290, 0.6940, 0.1250];
                case 'purple'
                    plotColor = [0.4940, 0.1840, 0.5560];
                case 'orange'
                    plotColor = [0.8500, 0.3250, 0.0980];
                case 'black'
                    plotColor = [0, 0, 0];
                otherwise
                    plotColor = [0, 0.4470, 0.7410];
                    
            end
        end
        
        function plotMarker = get.PlotMarker(obj)
            switch obj.hPlotMarker
                case 'line'
                    plotMarker = {'-', 'none'};
                case {'circle'}
                    plotMarker = {'none', 'o'};
                case {'line&circle'}
                    plotMarker = {'-', 'o'};
                otherwise
                    plotMarker = {'-', 'none'};
            end
        end
        
        function menuGalleryColorChanged(obj,newcolor)
            obj.hColor = newcolor;
            colormap(obj.hAxesGallery, obj.ColorMap);
        end
        
        function menuPlotColorChanged(obj, newcolor)
            obj.hPlotColor = newcolor;
            obj.plotTimeSeries(1);
            obj.plotHistogram(1);
        end
        
        function menuPlotMarkerChanged(obj, newMarker)
            obj.hPlotMarker = newMarker;
            obj.plotTimeSeries(1);
        end
        
        function menuGridOnOff(obj, OnOff)
            obj.GridOn = OnOff; % should have a listener on this
            obj.plotTimeSeries(1);
            obj.plotHistogram(1);
        end
        
        % AOI & Slider--------------------------------------------------
        
        function set.idx(obj, f)
            obj.idx = f;
        end
        
        function resize(obj)
            margin = 2;
            lineh = 20;
            fontsize = 14;
            % lineh cannot be greater than button size ?
            
            bbox = getpixelposition(obj.hPanel);
            y3 = bbox(4) - margin - lineh;
            x1 = 50;
            w0 = bbox(3)-4*lineh;
            
            % Buttons
            obj.hButtonPrev.Position = [x1 y3 lineh lineh];
            obj.hButtonPrev.Visible = 'on';
            
            obj.hButtonNext.Position = [x1+lineh y3 lineh lineh];
            obj.hButtonNext.Visible = 'on';
            
            obj.hButtonName.Position = [x1+2*lineh, y3, w0-5*lineh, lineh];
            obj.hButtonName.Visible = 'on';
            
            obj.hButtonZoom.Position = [x1+w0-3*lineh, y3, lineh, lineh];
            obj.hButtonZoom.Visible = 'on';
            obj.hButtonZoom.FontSize = fontsize;
            
            obj.hButtonReset.Position = [x1+w0-2*lineh, y3, lineh, lineh];
            obj.hButtonReset.Visible = 'on';
            obj.hButtonReset.FontSize = fontsize;
            
            obj.hButtonMenu.Position = [x1+w0-lineh, y3, lineh, lineh];
            obj.hButtonMenu.Visible = 'on';
            obj.hButtonMenu.FontSize = fontsize;
            
            obj.hAxesGallery.Visible = 'on';
            obj.hAxesTimeSeries.Visible = 'on';
            obj.hAxesHistogram.Visible = 'on';
            
            switch obj.hLayout
                
                case {'3'}
                    % All three plots on
                    
                    h1 = (bbox(4)-4*lineh-2*margin)/2;
                    w0 = bbox(3)-4*lineh;
                    w1 = 0.85*(w0);
                    w2 = 0.15*(w0-margin);
                    
                    x2 = x1 + margin + w1;
                    y2 = y3 - h1 - margin; % top axes
                    y1 = y2 - h1 - margin; % bottom axes
                    
                    % Axes
                    obj.hAxesGallery.Position = [x1 y2 w0 h1];
                    obj.hAxesGallery.XTick = [];
                    obj.hAxesGallery.YTick = [];
                    obj.hAxesTimeSeries.Position = [x1 y1 w1 h1];
                    obj.hAxesHistogram.Position = [x2 y1 w2 h1];
                    
                    obj.plotImageGallery(1);
                    
                case {'2b'}
                    % Gallery and TimeSeries
                    obj.hAxesHistogram.Position = [0 0 1 1];
                    h1 = (bbox(4)-4*lineh-2*margin)/2;
                    w0 = bbox(3)-4*lineh;
                    y2 = y3 - h1 - margin; % top axes
                    y1 = y2 - h1 - margin; % bottom axes
                    
                    obj.hAxesGallery.Position = [x1 y2 w0 h1];
                    obj.hAxesGallery.XTick = [];
                    obj.hAxesGallery.YTick = [];
                    obj.hAxesTimeSeries.Position = [x1 y1 w0 h1];
                    
                    obj.plotImageGallery(1);
                    
                case {'2a'}
                    % TimeSeries and Histogram
                    obj.hAxesGallery.Position = [0,0,1,1];
                    h1 = (bbox(4)-4*lineh-2*margin);
                    w0 = bbox(3)-4*lineh;
                    w1 = 0.85*(w0);
                    w2 = 0.15*(w0-margin);
                    y1 = y3 - h1 - margin; % top axes
                    x2 = x1 + margin + w1;
                    
                    obj.hAxesTimeSeries.Position = [x1 y1 w1 h1];
                    obj.hAxesHistogram.Position = [x2 y1 w2 h1];
                    
                case {'1c'}
                    % Histogram only (not sure why...)
                    obj.hAxesTimeSeries.Position = [0 0 1 1];
                    obj.hAxesGallery.Position = [0 0 1 1];
                    
                    h1 = (bbox(4)-4*lineh-2*margin);
                    w0 = bbox(3)-4*lineh;
                    y1 = y3 - h1 - margin; % top axes
                    obj.hAxesHistogram.Position = [x1 y1 w0 h1];
                    
                case {'1b'}
                    % Gallery
                    obj.hAxesTimeSeries.Position = [0 0 1 1];
                    obj.hAxesHistogram.Position = [0 0 1 1];
                    
                    h1 = (bbox(4)-4*lineh-2*margin);
                    w0 = bbox(3)-4*lineh;
                    y1 = y3 - h1 - margin; % top axes
                    obj.hAxesGallery.Position = [x1 y1 w0 h1];
                    
                    obj.plotImageGallery(1)
                    
                case {'1a'}
                    % Time Series
                    obj.hAxesGallery.Position = [0 0 1 1];
                    obj.hAxesHistogram.Position = [0 0 1 1];
                    
                    h1 = (bbox(4)-4*lineh-2*margin);
                    w0 = bbox(3)-4*lineh;
                    y1 = y3 - h1 - margin; % top axes
                    obj.hAxesTimeSeries.Position = [x1 y1 w0 h1];
            end
        end
        
        function n = get.AOILabel(obj)
            str1 = convertCharsToStrings(sprintf(' %d | %d (%0.2f, %0.2f)',...
                obj.idx, obj.numAOI, obj.hAOI(obj.idx).centroid(1), obj.hAOI(obj.idx).centroid(2)));
            n = obj.hName + ' ' + str1;
        end
        
        function updateAOI(obj, init)
            
            obj.hButtonName.String = obj.AOILabel;
            
            switch obj.hLayout
                case {'3'}
                    obj.plotTimeSeries(init);
                    obj.plotImageGallery(init);
                    obj.plotHistogram(init);
                    
                case {'2a'}
                    obj.plotTimeSeries(init);
                    obj.plotHistogram(init);
                case {'2b'}
                    obj.plotTimeSeries(init);
                    obj.plotImageGallery(init);
                    
                case {'1a'}
                    obj.plotTimeSeries(init);
                case {'1b'}
                    obj.plotImageGallery(init);
                case {'1c'}
                    obj.plotHistogram(init);
                    
            end
        end
        
        function plotImageGallery(obj, init)
            im = obj.hAOI(obj.idx).gallery;
            [mu,sigma] = normfit(im(:));
            im = padarray(im, [1,1], NaN, 'both');
            if init
                %nImages = size(im,3);
                nImages = ceil(size(im,3)/10)*10;
                n1 = 1:ceil(sqrt(nImages));
                n2 = ceil(nImages./n1);
                n3 = n2./n1;
                w = obj.hAxesGallery.Position(3);
                h = obj.hAxesGallery.Position(4);
                aspectratio = w/h;
                [~,i] = min(abs(aspectratio-n3));
                ncol = n2(i);
                nrow = n1(i);
                im2 = imtile(im, 'GridSize', [nrow, ncol]);
                obj.hGallery.CData = im2;
                obj.hAxesGallery.CLim = [mu-sigma, mu+5*sigma];
                
            else
                ims = size(im,1);
                [nrow, ncol] = size(obj.hGallery.CData);
                nrow = nrow/ims;
                ncol = ncol/ims;
                obj.hGallery.CData = imtile(im, 'GridSize', [nrow, ncol]);
                obj.hAxesGallery.CLim = [mu-sigma, mu+5*sigma];
                
            end
        end
        
        % Plot Time Series
        function plotTimeSeries(obj, init)
            x = obj.hAOI(obj.idx).timeSeries - obj.hAOI(obj.idx).minTimeSeriesValue;
            if init
                if isempty(obj.hTime_s)
                    plot(x,...
                        'Parent', obj.hAxesTimeSeries,...
                        'Color', obj.PlotColor,...
                        'LineStyle', obj.PlotMarker{1},...
                        'Marker', obj.PlotMarker{2});
                    xlabel('Frames', 'Parent',  obj.hAxesTimeSeries);
                    set(obj.hAxesTimeSeries, 'XLim', [0, length(x)])
                else
                    plot(obj.hTime_s, x,...
                        'Parent', obj.hAxesTimeSeries,...
                        'Color', obj.PlotColor,...
                        'LineStyle', obj.PlotMarker{1},...
                        'Marker', obj.PlotMarker{2});
                    xlabel('Time (s)', 'Parent',  obj.hAxesTimeSeries);
                    ylabel('Fluoresence (AU)', 'Parent',  obj.hAxesTimeSeries);
                    set(obj.hAxesTimeSeries, 'XLim', [obj.hTime_s(1), obj.hTime_s(end)])
                end
                set(obj.hAxesTimeSeries, 'tickdir', 'out', 'box', 'off')
                grid(obj.hAxesTimeSeries, obj.GridOn);
            else
                % only need to change the data
                obj.hAxesTimeSeries.Children(end).YData = x;
            end
        end
        
        % Plot Histogram
        function plotHistogram(obj, init)
            x = obj.hAOI(obj.idx).timeSeries - obj.hAOI(obj.idx).minTimeSeriesValue;
            % bins = ceil(1 + log2(numel(x))); % sturges
            bins = ceil(sqrt(numel(x))); % sqrt
            %bins = round(numel(x)/3);
            max_value = round(max(x), 1);
            min_value = round(min(x),-1);
            if min_value == 0
                max_value = round(max(x),2);
                min_value = round(min(x)*-1,2)*-1;
            end
            
            if length(unique(x)) > 1
                data_range = linspace(min_value, max_value,bins); % edges
                data_counts = histcounts(x, [data_range, Inf]);
            else
                [data_range, data_counts] = histcounts(x);
            end
            
            if init
                bar(obj.hAxesHistogram, data_range, data_counts,...
                    'BarWidth', 1,...
                    'FaceColor', obj.PlotColor,...
                    'EdgeColor', obj.PlotColor);
                %grid(obj.hAxesHistogram, obj.GridOn);
                
            else
                obj.hAxesHistogram.Children(end).XData = data_range;
                obj.hAxesHistogram.Children(end).YData = data_counts;
            end
            set(obj.hAxesHistogram,'xtick',[]);
            set(obj.hAxesHistogram,'ytick',[]);
            view(obj.hAxesHistogram,[90,-90])
            obj.hAxesHistogram.Box = 'off';
            set(obj.hAxesHistogram, 'XLim',get(obj.hAxesTimeSeries,'Ylim'));
        end
        
        function idealizeAOI(obj)
            % AOIs(obj.idx).idealize();
            obj.hAOIs(obj.idx).fitAOI();
        end
        
        function delete(obj)
            % obj.deleteListeners();
            delete(obj.hPanel); % will delete all other child graphics objects
        end
    end
end