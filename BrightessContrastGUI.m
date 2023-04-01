classdef BrightessContrastGUI < handle
    properties
        
        hImageStackViewer = ImageStackViewer.empty();
        hParent
        hAxes
        hSliderBarMin
        hSliderBarMax
        hTextMin
        hTextMax
        hEditMin
        hEditMax
        hButtonAutomatic
        hButtonApplyToAll
    end
    
    properties (Dependent)
        CurrentFrame
    end
    
     properties (Access = private)
        listenerSliderMin = event.listener.empty
        listenerSliderMax = event.listener.empty
    end
    
    methods
        % constructor
        function obj = BrightessContrastGUI(data, objPosition)
            
            if ~isempty(data) && isa(data, 'ImageStackViewer')
                % close existing windows
                delete(findobj('Name', 'B&C'));
                
                % Get data.
                obj.hImageStackViewer = data;
                bc = obj.hImageStackViewer.hBC;
                
                % Set some default values so easier to change
                sliderHeight = 10; 
                buttonHeight = 20; 
                fontSize = 10; 
                buffer = 10; 
                parentWidth = 150;
                parentHeight = 230; 
                objWidth = parentWidth-2*buffer;
                
                 % for now set position based on single parent, will need
                 % to change to how positon is found in context menu
                 if ~exist('objPosition', 'var') || isempty(objPosition)
                     pos = obj.hImageStackViewer.Parent.Position;
                     objPosition = [pos(1)+pos(3)+5, pos(2)+pos(4)+5-parentHeight];
                 end
                 position = [objPosition(1), objPosition(2), parentWidth, parentHeight];
                
                % check type of data. set values
                minValue = 1; 
                maxValue = 65535;
                
                obj.hParent = figure(...
                    'Name', 'B&C',...
                    'Visible', 'on',...
                    'Units', 'pixels',...
                    'MenuBar', 'None',...
                    'resize','off', ...
                    'NumberTitle', 'off',...
                    'Position', position);
                
                hAxesHeight = 80;
                obj.hAxes = axes(obj.hParent,...
                    'XTick', [],...
                    'YTick', [],...
                    'box', 'on',...
                    'Units', 'Pixels',...
                    'Position', [buffer, parentHeight-buffer-hAxesHeight, objWidth, hAxesHeight]);
                
                pos = plotboxpos(obj.hAxes);
                
                L1 = pos(2)-buffer-sliderHeight;
                obj.hSliderBarMin = uicontrol(obj.hParent, ...
                    'Style', 'slider', ...
                    'Min', minValue,...
                    'Max',  bc(2)-1,...
                    'Value', bc(1),...
                    'SliderStep', [1/(bc(2)-1), 1/(bc(2)-1)*10], ...
                    'Units', 'pixels', ...
                    'Position', [pos(1), L1, objWidth, sliderHeight],...
                    'Visible', 'on');
                % 'Callback', @(varargin)obj.sliderChangedMin());
                
                L2 = L1 - buttonHeight-buffer/2; 
                 obj.hTextMin = uicontrol(obj.hParent, ...
                    'Style', 'Text', ...
                    'String', 'Minimum',...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1), L2, objWidth/2, buttonHeight],...
                    'Visible', 'on');
                
                 obj.hEditMin = uicontrol(obj.hParent, ...
                    'Style', 'Edit', ...
                    'String', num2str(bc(1)),...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1)+objWidth/2, L2, objWidth/2, buttonHeight],...
                    'Visible', 'on',...
                    'Callback',  @(varargin)obj.editTextMin());
                
                % -----------------
                L3 = L2 - buffer - sliderHeight;
                obj.hSliderBarMax = uicontrol(obj.hParent, ...
                    'Style', 'slider', ...
                    'Min', bc(1)+1,...
                    'Max', maxValue,...
                    'Value', bc(2),...
                    'SliderStep', [1/(maxValue-bc(1)+1), 1/(maxValue-bc(1)+1)*10], ...
                    'Units', 'pixels', ...
                    'Position', [pos(1), L3, objWidth, sliderHeight],...
                    'Visible', 'on');
                % 'Callback', @(varargin)obj.sliderChangedMax());
                
                L4 = L3 - buffer/2 - buttonHeight; 
                 obj.hTextMax = uicontrol(obj.hParent, ...
                    'Style', 'Text', ...
                    'String', 'Maximum',...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1), L4, objWidth/2, buttonHeight],...
                    'Visible', 'on');
                
                 obj.hEditMax = uicontrol(obj.hParent, ...
                    'Style', 'Edit', ...
                    'String', num2str(bc(2)),...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1)+objWidth/2, L4, objWidth/2, buttonHeight],...
                    'Visible', 'on',...
                    'Callback',  @(varargin)obj.editTextMax());
                

                L5 = L4 - buttonHeight - buffer;
                buttonWidth = pos(3)/2-buffer/2;
                obj.hButtonAutomatic = uicontrol(obj.hParent,...
                    'Style', 'pushbutton',...
                    'String', 'Auto',...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1), L5, buttonWidth, buttonHeight],...
                    'FontSize', fontSize,...
                    'Visible', 'on',...
                    'Callback', @(varargin)obj.automaticBC());
                
                obj.hButtonApplyToAll = uicontrol(obj.hParent,...
                    'Style', 'pushbutton',...
                    'String', 'Apply To All',...
                    'Units', 'pixels', ...
                    'FontSize', fontSize,...
                    'Position', [pos(1)+buffer/2+buttonWidth, L5, buttonWidth, buttonHeight],...
                    'FontSize', fontSize,...
                    'Visible', 'on',...
                    'Callback', @(varargin)obj.applyToAll());
                
                obj.updateListeners();
                obj.plotFrameHist();
            end
        end

        function updateListeners(obj)
            obj.listenerSliderMin = ...
            addlistener(obj.hSliderBarMin, 'Value', 'PostSet', @(varargin)obj.sliderChangedMin());
        
            obj.listenerSliderMax = ...
            addlistener(obj.hSliderBarMax, 'Value', 'PostSet', @(varargin)obj.sliderChangedMax());
        end
        
        function f = get.CurrentFrame(obj)
            f = obj.hImageStackViewer.CurrentFrame;
        end
        
        function CurrentFrameChanged(obj)
            obj.plotFrameHist()
        end
        
        function plotFrameHist(obj)
            histogram(obj.hImageStackViewer.CurrentFrame(:), ...
                'Parent', obj.hAxes,...
                'EdgeColor', [0.5,0.5,0.5],...
                'FaceColor', [0.5,0.5,0.5])
            obj.hAxes.XTick = [];
            obj.hAxes.YTick = [];
            obj.hAxes.XLim =  obj.hImageStackViewer.hBC;
        end
        
        function sliderChangedMin(obj)
            obj.updateMinMax([obj.hSliderBarMin.Value, obj.hSliderBarMax.Value]);
        end
        
        function sliderChangedMax(obj)
            obj.updateMinMax([obj.hSliderBarMin.Value, obj.hSliderBarMax.Value]);
        end
        
        function editTextMin(obj)
            obj.hSliderBarMin.Value = str2double(obj.hEditMin.String);
            obj.updateMinMax([obj.hSliderBarMin.Value, obj.hSliderBarMax.Value]);
        end
        
        function editTextMax(obj)
            obj.hSliderBarMax.Value = str2double(obj.hEditMax.String);
            obj.updateMinMax([obj.hSliderBarMin.Value, obj.hSliderBarMax.Value]);
        end
        
        function automaticBC(obj)
            [mu,sigma] = normfit(obj.hImageStackViewer.CurrentFrame(:));
            minbc = mu-2*sigma;
            maxbc = mu+8*sigma;
            obj.updateMinMax([minbc,maxbc]);
        end
        
        function updateMinMax(obj, bc)
            obj.hSliderBarMin.Value = bc(1); 
            obj.hEditMin.String = num2str(bc(1)); 
            obj.hSliderBarMax.Value = bc(2); 
            obj.hEditMax.String = num2str(bc(2)); 
            obj.hSliderBarMax.Min = bc(1)+1; 
            obj.hSliderBarMin.Max = bc(2)-1; 
            obj.hImageStackViewer.hBC(1) = bc(1);
            obj.hImageStackViewer.hBC(2) = bc(2);
            plotFrameHist(obj)
        end
        
        function applyToAll(obj)
            % find all open objects
            % could be in parent, or in seperate windows
            
            % check for multiple ImageStackViewer
            x = findall(groot,'Type','figure');
            % will return BC and all ImageStackViewer
            if length(x) > 2 
                for i = 1:length(x)
                    if strcmp(x(i).Name, 'ImageStackViewer')
                        x(i).UserData.hBC = obj.hImageStackViewer.hBC; 
                        % need a notify funciton?
                    end
                end
            else 
                % check in parent of obj, might have multiple user data
            end
        end
        
        function deleteListeners(obj)
            delete(obj.listenerSliderMin);
            obj.listenerSliderMin = event.listener.empty;
            delete(obj.listenerSliderMax);
            obj.listenerSliderMax = event.listener.empty;
        end
        
        function delete(obj)
            obj.deleteListeners();
             delete(obj.hParent);
        end
    end
end