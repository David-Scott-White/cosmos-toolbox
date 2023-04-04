classdef ImageStackViewer < handle
    % GUI to view IMAGE STACK CLASS
    
    properties
        hImageStack
        
        hPanel
        hAxes
        hImage
        hSlider
        hMenuBar
        hName
        hAOI
        hReset
        hZoom
        hMenu
        hText
        hColor = 'gray'
        CurrentFrameIdx
        CurrentZoomPixels
        MenuShowAOIs = true
        MenuDisplayUnits = 'f'
    end
    
    properties (Access = private)
        
    end
    
    properties (Dependent)
        Parent % hPanel.Parent
        Position % hPanel.Position
        ContextMenu
        MenuShowAOIsIdx
        CurrentString
        OperatingSystem
        UserAOIActive
        CustomAOICoordinates
    end
    
    properties (SetObservable)
        ColorMap
        hBC
        CurrentFrame
    end
    
    events
        ExpandView
    end
    
    
    methods
        function obj = ImageStackViewer(imageData, parent)
            %IMAGESTACKVIEWER Constructor ---------------------------------
            obj.hImageStack = imageData;
            
            %  NEED To check that data is given and not empty. Else quit
            
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
                obj.hPanel.Parent.Name = 'ImageStackViewer';
            end
            
            % Objects in panel
            obj.hAxes = axes(obj.hPanel,...
                'Units', 'pixels',...
                'XTick', [],...
                'YTick', [],...
                'YDir', 'reverse',...
                'box', 'on');
            obj.hImage =imagesc(obj.hAxes, [],...
                'HitTest', 'off',...
                'PickableParts', 'none');
            axis(obj.hAxes, 'image');
            set(obj.hAxes, 'ButtonDownFcn', {@toggleSelection, obj})
            colormap(obj.hAxes, obj.ColorMap);
            
            % Clicking on the image ---------------------------------------
            function toggleSelection(~, event, obj)
                % select this axes over the others
                switch double(event.Button)
                    case 1
                        % Left click function
                         obj.menuZProjectSelection();
                    otherwise % could be middle (2) or right (3)
                        % right click function
                        obj.clearCustomAOI()
                end
            end
            
            obj.hSlider = uicontrol(obj.hPanel,...
                'Style', 'slider', ...
                'Min', 1, 'Max', obj.hImageStack.numFrames, 'Value', 1, ...
                'SliderStep', [1/obj.hImageStack.numFrames 1/obj.hImageStack.numFrames*10], ...
                'Units', 'pixels', ...
                'Visible', 'off');
            obj.hName = uicontrol(obj.hPanel,...
                'Style', 'edit', ...
                'String', '',...
                'Visible', 'off');
            obj.hName = uicontrol(obj.hPanel,...
                'Style', 'edit', ...
                'String', '',...
                'Visible', 'off');
            
            % Buttons -----------------------------------------------------
            obj.hText = uicontrol(obj.hPanel,...
                'Style', 'PushButton', ...
                'String', '',...
                'Visible', 'off');
            obj.hAOI = uicontrol(obj.hPanel,...
                'Style', 'PushButton',...
                'String', '', ...
                'Visible', 'off', ...
                'Callback',@(src,event)drawCustomAOI(obj));
            
            obj.hZoom = uicontrol(obj.hPanel,...
                'Style', 'PushButton',...
                'String', '', ...
                'Visible', 'off', ...
                'Callback',@(src,event)zoomIn(obj));
            
            obj.hMenu = uicontrol(obj.hPanel,...
                'Style', 'PushButton',...
                'String', '', ...
                'Visible', 'off',...
                'Callback', @(src,event)menuButtonPushed(obj, event));
            
            obj.hReset = uicontrol(obj.hPanel,...
                'Style', 'PushButton',...
                'String', '', ...
                'Visible', 'off', ...
                'Callback',@(src,evnt)resetView(obj));
            
            % -------------------------------------------------------------
            % Listeners
            % -------------------------------------------------------------
            addlistener(obj.hSlider, 'Value', 'PostSet', @(varargin) obj.sliderMoved());
            addlistener(obj.hName, 'String', 'PostSet', @(varargin) obj.nameChanged());
            % set(obj.Parent, 'KeyPressFcn', {@keyPressedLocal})
            addlistener(obj, 'hBC', 'PostSet', @(varargin) obj.updateImage());
            obj.hPanel.SizeChangedFcn = @(varargin) obj.resize();
            
            % set some condition to activate shortcuts if parent is not
            % smExperimentViewer
            
            % -------------------------------------------------------------
            % Keyboard shortcuts
            % -------------------------------------------------------------
%             function keyPressedLocal(obj, event)
%                 % need an index for which plot is active still...
%                 switch event.Key
%                     case {'x'}
%                         obj.UserData.clearCustomAOI();
%                         
%                     case {'z', 'g'}
%                         obj.menuZProjectSelection();
%                 end
%             end
            
            % Initialize (Currently not possible to be empty) -------------
            if ~isempty(obj.hImageStack)
                obj.resetView();
                updateImage(obj);
                resize(obj);
            end
            
            obj.hPanel.Visible = 'on';
        end
        
        % END OF CONSTRUCTOR ----------------------------------------------
        
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
        
        % -----------------------------------------------------------------
        % Context Menu
        % -----------------------------------------------------------------
        function cm = get.ContextMenu(obj)
            
            cm = uicontextmenu;
            
            % Image Display -----------------------------------------------
            mImage = uimenu(cm,"Text", "Image");
            uimenu(mImage,"Text", "Brightness & Contrast", 'Callback', @(varargin)obj.menuLaunchBC());
            uimenu(mImage, 'Text', 'Crop', 'Separator', 'on');
            mImageColor = uimenu(mImage, 'Text', 'Pseudocolor', 'Separator', 'on');
            uimenu(mImageColor, 'Text', 'grey','Callback', @(varargin)obj.menuColorChanged('grey'));
            uimenu(mImageColor, 'Text', 'blue','Callback', @(varargin)obj.menuColorChanged('blue'));
            uimenu(mImageColor, 'Text', 'green','Callback', @(varargin)obj.menuColorChanged('green'));
            uimenu(mImageColor, 'Text', 'red', 'Callback', @(varargin)obj.menuColorChanged('red'));
            uimenu(mImageColor, 'Text', 'yellow','Callback', @(varargin)obj.menuColorChanged('yellow'));
            uimenu(mImageColor, 'Text', 'pink','Callback', @(varargin)obj.menuColorChanged('pink'));
            uimenu(mImageColor, 'Text', 'teal','Callback', @(varargin)obj.menuColorChanged('teal'));
            mFlipImage = uimenu(mImage, 'Text', 'Flip Image', 'Separator', 'on');
            uimenu(mFlipImage, "Text", "Flip Vertical", 'Callback', @(varargin)obj.menuFlipVertical());
            uimenu(mFlipImage, "Text", 'Flip Horizontal','Callback', @(varargin)obj.menuFlipHorizontal());
            uimenu(mFlipImage, "Text", 'Reset','Callback', @(varargin)obj.menuFlipReset());
            
            % Process -----------------------------------------------------
            mProcess = uimenu(cm,"Text", "Process");
            uimenu(mProcess,"Text", "Load Images to Memory", 'Callback', @(varargin)obj.menuLoadToMemory());
            uimenu(mProcess,"Text", "Clear Images from Memory", 'Callback', @(varargin)obj.menuClearFromMemory());
            mDrift = uimenu(mProcess, 'Text', 'Drift Correction', 'Separator', 'on');
            uimenu(mDrift,"Text", "Compute Drift Correction", 'Callback', @(varargin)obj.menuComputeDriftCorrectionVideo());
            uimenu(mDrift,"Text", "Apply Drift Correction", 'Callback', @(varargin)obj.menuApplyDriftCorrectionVideo());
            uimenu(mDrift,"Text", "Clear Drift Correction", 'Callback', @(varargin)obj.menuClearDriftCorrectionVideo());
            uimenu(mProcess,"Text", "Subtract Background", 'Separator', 'on', 'Callback', @(varargin)obj.menuSubtractBackground());
            uimenu(mProcess,"Text", "Restore Background", 'Callback', @(varargin)obj.menuRestoreBackground());
            uimenu(mProcess,"Text", "Z-Project Selection", 'Separator', 'on', 'Callback', @(varargin)obj.menuZProjectSelection());
            uimenu(mProcess,"Text", "Duplicate", 'Separator', 'on', 'Callback', @(varargin)obj.menuDuplicateImageStackViewer());
            
            % AOIs --------------------------------------------------------
            mAOIs = uimenu(cm, "Text", "AOIs");
            uimenu(mAOIs,"Text","Set AOI Parameters", 'Callback', @(varargin)obj.menuSetAOIParameters);
            uimenu(mAOIs,"Text","Find AOIs", 'Callback', @(varargin)obj.menuFindAOIs);
            uimenu(mAOIs,"Text","Show AOIs", 'Checked', obj.MenuShowAOIs, 'Callback', @(varargin)obj.menuUpdateShowAOI());
            uimenu(mAOIs,"Text","Filter AOIs", 'Callback', @(varargin)obj.menuFilterAOIs, 'Separator', 'on');
            uimenu(mAOIs,"Text",'Propogate AOIs', 'Separator', 'on');
            uimenu(mAOIs,"Text","Clear AOIs", 'Callback', @(varargin)obj.menuDeleteAOIs, 'Separator', 'on');
            
            % View --------------------------------------------------------
            mView = uimenu(cm, 'Text', 'View');
            uimenu(mView, 'Text', 'Set Scale Bar')
            uimenu(mView, 'Text', 'View Scale Bar')
            uimenu(mView, 'Text', 'View Time')
            uimenu(mView, 'Text', 'View AOIs')
            
            % Export ------------------------------------------------------
            mExport = uimenu(cm, 'Text', 'Export');
            uimenu(mExport,"Text", "Export Frame");
            uimenu(mExport,"Text", "Export Video");
            
        end
        
        % Frames & Slider--------------------------------------------------
        function f = get.CurrentFrameIdx(obj)
            if ~isempty(obj.hImageStack)
                f = obj.hSlider.Value();
            end
        end
        
        function set.CurrentFrameIdx(obj, f)
            obj.CurrentFrameIdx = f;
        end
        
        function frame = get.CurrentFrame(obj)
            if ~isempty(obj.hImageStack)
                frame = obj.hImageStack.getFrame(obj.CurrentFrameIdx);
            end
        end
        
        function sliderMoved(obj)
            f = round(obj.hSlider.Value);
            if f < 1; f = 1; end
            obj.hSlider.Value = f;
            obj.CurrentFrameIdx = f;
            obj.CurrentFrame = obj.hImageStack.getFrame(obj.CurrentFrameIdx);
            
            updateImage(obj);
            obj.hText.String = obj.CurrentString;
        end
        
        % Name Text -----------------------------------------------------
        function obj = nameChanged(obj)
            obj.hImageStack.name = obj.hName.String;
        end
        
        % String Text
        function str = get.CurrentString(obj)
            switch obj.MenuDisplayUnits
                case {'f','frames'}
                    str1 = convertCharsToStrings(sprintf('[%d/%d frames]', obj.CurrentFrameIdx, obj.hImageStack.numFrames)); 
                case {'s','sec', 'seconds'}
                   str1 = convertCharsToStrings(sprintf('[%0.2f/%0.2f s]', obj.hImageStack.time_s(obj.CurrentFrameIdx), obj.hImageStack.time_s(end))); 
                case 'ms'
                    str1 = '';
            end
             str = obj.hImageStack.name + ' ' + str1;
        end
        
        % Drawing functions -----------------------------------------------
        function updateImage(obj)
            % need to adjust xlim and ylim based on active pixels (zoom?)
            if ~isempty(obj.hImageStack)
                obj.hImage.CData = obj.CurrentFrame;
                obj.hAxes.CLim = obj.hBC;
                obj.hAxes.XTick = [];
                obj.hAxes.YTick = [];
                % check against activePixels? Or reset prior?
                obj.hAxes.XLim = [obj.CurrentZoomPixels{1}(1),obj.CurrentZoomPixels{1}(2)];
                obj.hAxes.YLim = [obj.CurrentZoomPixels{2}(1),obj.CurrentZoomPixels{2}(2)];
            end
        end
        
        function resetView(obj)
            obj.CurrentZoomPixels = {[1, obj.hImageStack.width], [1, obj.hImageStack.height]};
            obj.updateImage();
            obj.resize();
        end
        
        function resize(obj)
            obj.resetPointer();
            
            % make below into properties (might be easier to determine
            % ismac, ispc, isunix. https://www.mathworks.com/help/matlab/ref/computer.html
            switch obj.OperatingSystem
                case {'MACI64', 'MACI32'}
                    margin = 2;
                    lineh = 20;
                    fontSize = 14;
                    
                case {'PCWIN64', 'PCWIN32'}
                    margin = 2;
                    lineh = 20;
                    fontSize = 14;
                case {'GLNXA64', 'GLNXA32'}
                    margin = 2;
                    lineh = 20;
                    fontSize = 14;
            end
            
            % set hAxes position
            bbox = getpixelposition(obj.hPanel);
            
            x = margin;
            y = margin + lineh + margin;
            w = bbox(3) - margin - x;
            h = bbox(4) - margin - lineh - margin - y;
            if ~isempty(obj.hAxes.YLabel.String)
                x = x + lineh;
                w = w - lineh;
            end
            obj.hAxes.Position = [x y w h];
            
            % get actual displayed image axes position.
            pos = plotboxpos(obj.hAxes);
            x = pos(1); y = pos(2); w = pos(3); h = pos(4);
            
            % slider below image
            obj.hSlider.Visible = 'on';
            obj.hSlider.Position = [x y-margin-lineh w lineh];
            
            % Menu button top right
            by = y + h + margin;
            obj.hMenu.Position = [x+w-lineh, by, lineh, lineh];
            obj.hMenu.String = '<HTML> &#10070 <HTML>'  ;
            obj.hMenu.Visible = 'on';
            obj.hMenu.FontSize = fontSize;
            obj.hMenu.ContextMenu = obj.ContextMenu;
            
            % Reset view button
            obj.hReset.Position = [x+w-2*lineh, by, lineh, lineh];
            obj.hReset.String = '<HTML> &#10530 <HTML>'  ;
            obj.hReset.Visible = 'on';
            obj.hReset.FontSize = fontSize;
            
            % hZoom
            obj.hZoom.Position = [x+w-3*lineh, by, lineh, lineh];
            obj.hZoom.String = '<HTML> &#8981; <HTML>'  ;
            obj.hZoom.Visible = 'on';
            obj.hZoom.FontSize = fontSize;
            
            % hAOI
            obj.hAOI.Position =[x+w-4*lineh, by, lineh, lineh];
            obj.hAOI.String = '<HTML> &#9723; <HTML>'  ; % &#9635 &#9633;
            obj.hAOI.Visible = 'on';
            obj.hAOI.FontSize = fontSize;
            
            % Channel name and frame/time button
            obj.hText.Position =  [x by w-4*lineh lineh];
            obj.hText.String = obj.CurrentString;
            obj.hText.HorizontalAlignment = 'right';
            obj.hText.Visible = 'on';
            obj.hText.FontSize = 10;
            
            % pointer
            iptPointerManager(obj.Parent, 'enable');
            iptSetPointerBehavior(obj.hAxes, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            
            
        end
        
        % Operating system ------------------------------------------------
        function os = get.OperatingSystem(obj)
            % buttons and fonts appear different across OS!
            os = computer;
        end
        
        % Get Brightness and Contrast Limits(e.g., CLim) ------------------
        function bc = get.hBC(obj)
            bc = obj.hBC;
            if isempty(obj.hBC) && ~isempty(obj.CurrentFrame)
                frame = obj.CurrentFrame(:);
                [mu,sd] = normfit(frame(frame>0));
                bc = [mu-2*sd, mu+8*sd];
            end
        end
        
        function set.hBC(obj, bc)
            obj.hBC = bc;
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
        
        % MISC functions --------------------------------------------------
        function menuButtonPushed(obj, event)
            obj.hPanel.Units = 'Pixels';
            x = [obj.hMenu.Position(1)+obj.hMenu.Position(3),obj.hMenu.Position(2)+obj.hMenu.Position(4)] + obj.hPanel.Position(1:2);
            obj.hMenu.ContextMenu.Position = x-[0,10];
            obj.hMenu.ContextMenu.Visible = 1;
            obj.hPanel.Units = 'Normalized';
        end
        
        function drawCustomAOI(obj)
            iptPointerManager(obj.Parent, 'enable');
            iptSetPointerBehavior(obj.hAxes, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'crosshair'));
            roi = getrect(obj.hAxes);
            x1 = round(roi(1))-0.5;
            x2 = round(roi(1)+roi(3))+0.5;
            y1 = round(roi(2))-0.5;
            y2 = round(roi(2)+roi(4))+0.5;
            
            x = [x1, x2, x2, x1, x1];
            y = [y1, y1, y2, y2, y1];
            
            % clear previous
            obj.clearCustomAOI()
            hold on
            plot(x, y, '-y', 'linewidth',1.5);
            hold off
            obj.resetPointer();
            
        end
        
        function clearCustomAOI(obj)
            delete(findobj(obj.hAxes.Children, 'type', 'Line', 'LineWidth', 1.5, 'Color', 'y'));
        end
        
        
        function zoomIn(obj)
            iptPointerManager(obj.Parent, 'enable');
            iptSetPointerBehavior(obj.hAxes, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'crosshair'));
            roi = getrect(obj.hAxes);
            x1 = floor(roi(1));
            x2 = floor(roi(1)+roi(3));
            y1 = floor(roi(2));
            y2 = floor(roi(2)+roi(4));
            if x1 ~= x2 && y1 ~= y2
                obj.CurrentZoomPixels = {[x1, x2], [y1,y2]};
                obj.updateImage();
                obj.resize();
            end
            obj.resetPointer();
        end
        
        function set.CurrentZoomPixels(obj, x)
            obj.CurrentZoomPixels = x;
        end
        
        function menuSetAOIParameters(obj)
            obj.hImageStack.setAOIParameters([]);
        end
        
        function menuFindAOIs(obj)
            obj.hImageStack.findAreasOfInterest();
            obj.showAOIs;
            obj.hText.String = obj.CurrentString;
        end
        
        function menuDeleteAOIs(obj)
            obj.hImageStack.deleteAOIs();
            obj.clearAOIs()
            obj.hText.String = obj.CurrentString;
        end
        
        function menuUpdateShowAOI(obj)
            obj.hMenu.ContextMenu.Children(obj.MenuShowAOIsIdx).Checked =~ obj.hMenu.ContextMenu.Children(obj.MenuShowAOIsIdx).Checked;
            obj.MenuShowAOIs = obj.hMenu.ContextMenu.Children(obj.MenuShowAOIsIdx).Checked;
            if obj.MenuShowAOIs
                obj.showAOIs();
            else
                obj.clearAOIs()
            end
        end
        
        function resetPointer(obj)
            iptSetPointerBehavior(obj.Parent, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            iptSetPointerBehavior(obj.hAxes, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            iptSetPointerBehavior(obj.hZoom, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            iptSetPointerBehavior(obj.hAOI, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            iptSetPointerBehavior(obj.hReset, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
            iptSetPointerBehavior(obj.hMenu, @(hFigure, currentPoint)set(obj.Parent, 'Pointer', 'arrow'));
        end
        
        % Filter AOIs
        function menuFilterAOIs(obj)
            obj.hText.String = obj.CurrentString;
        end
        
        function obj = menuCropToZoom(obj)
            obj.hImageStack.activePixels = obj.CurrentZoomPixels;
            obj = ImageStackViewer(obj.hImageStack, obj.Parent);
        end
        
        function menuFlipVertical(obj)
            obj.hImageStack.flipVertical = ~obj.hImageStack.flipVertical;
            obj.updateImage()
        end
        
        function menuFlipHorizontal(obj)
            obj.hImageStack.flipHorizontal = ~obj.hImageStack.flipHorizontal;
            obj.updateImage();
        end
        
        function menuFlipReset(obj)
            obj.hImageStack.flipHorizontal = false;
            obj.hImageStack.flipVertical = false;
            obj.updateImage();
        end
        
        function menuSubtractBackground(obj)
            % Note, imtophat often making the integreated time series
            % worse!
            obj.hImageStack.setBackgroundSE();
            obj.updateImage();
        end
        
        function menuRestoreBackground(obj)
            obj.hImageStack.backgroundSE = [];
            obj.updateImage();
        end
        
        function menuLoadToMemory(obj)
            obj.hImageStack.loadImagesToMemory();
            obj.hText.String = obj.CurrentString;
        end
        
        function menuClearFromMemory(obj)
            if obj.hImageStack.DataLoadedToMemory
                obj.hImageStack.clearImagesFromMemory();
                obj.hText.String = obj.CurrentString;
            end
        end
        
        function menuDuplicateImageStackViewer(obj)
            % creates a new window of the copied object
            % might need to grab extra information from the obj
            
            % NOT CURRENTLY WORKING
            ImageStackViewer(obj.hImageStack)
        end
        
        % AOI Visualuzation -----------------------------------------------
        function showAOIs(obj)
            % Draw rectangles for each aoi.boundingbox
            % Need to check for drift and remove
            if ~isempty(obj.hImageStack) && ~isempty(obj.hImageStack.AOIs)
                clearAOIs(obj);
                if obj.MenuShowAOIs
                    for i = 1:size(obj.hImageStack.AOIs,1)
                        rectangle(...
                            'Parent',obj.hAxes,...
                            'Position',obj.hImageStack.AOIs(i).boundingBox,...
                            'EdgeColor','r',...
                            'LineWidth', 1);
                    end
                end
            end
        end
        
        function clearAOIs(obj)
            delete(findobj(obj.hAxes.Children, 'type', 'Rectangle'));
        end
        
        function u = get.UserAOIActive(obj)
            u = false;
            if ~isempty(findobj(obj.hAxes.Children, 'type', 'Line', 'LineWidth', 1.5, 'Color', 'y'))
                u = true;
            end
        end
        
        function c = get.CustomAOICoordinates(obj)
            c = [];
            if obj.UserAOIActive
                z = findobj(obj.hAxes.Children, 'type', 'Line', 'LineWidth', 1.5, 'Color', 'y');
                x = [min(z.XData+0.5), max(z.XData-0.5)];
                y = [min(z.YData+0.5), max(z.YData-0.5)];
                c = [x;y];
            end
        end
        
        % this needs to get moved up to the parent?
        
        
        function menuLaunchBC(obj)
            BrightessContrastGUI(obj);
        end
        
        function menuComputeDriftCorrectionVideo(obj)
            obj.hImageStack.computeDriftCorrectionVideo();
        end
        
        function menuApplyDriftCorrectionVideo(obj)
            obj.hImageStack.applyDriftCorrectionVideo();
        end
        
        function menuClearDriftCorrectionVideo(obj)
            obj.hImageStack.clearDriftCorrectionVideo();
            obj.menuLoadToMemory()
            obj.updateImage()
        end
        
        function menuColorChanged(obj,newcolor)
            obj.hColor = newcolor;
            colormap(obj.hAxes, obj.ColorMap);
            % should add listener and event...
        end
        
        function menuZProjectSelection(obj)
            if obj.UserAOIActive
                % store the selected area?
                timeSeries = obj.hImageStack.intergrateAOI(obj.CustomAOICoordinates);
                str = sprintf('Custom AOI | (%d,%d), (%d,%d)',...
                    obj.CustomAOICoordinates(1,1), obj.CustomAOICoordinates(1,2),...
                    obj.CustomAOICoordinates(2,1), obj.CustomAOICoordinates(2,2));
                img = figure(...
                    'Name', str,...
                    'NumberTitle', 'off',...
                    'Units', 'Pixels',...
                    'MenuBar','none');
                if isempty(obj.hImageStack.time_s)
                    plot(timeSeries, '-k');
                    xlabel('Frames')
                    img.Children(1).XLim = [0, obj.hImageStack.numFrames];
                    grid('on')
                else
                    plot(obj.hImageStack.time_s, timeSeries, '-k');
                    xlabel('Time (s)')
                    img.Children(1).XLim = [0, obj.hImageStack.time_s(end)];
                    grid('on')
                end
                ylabel('Fluorescence (AU)')
            end
        end
        
        
        % close
        function delete(obj)
            % obj.deleteListeners();
            delete(obj.hPanel); % will delete all other child graphics objects
        end
        
    end
end
