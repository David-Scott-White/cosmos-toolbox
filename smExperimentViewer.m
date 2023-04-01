classdef smExperimentViewer < handle
    % GUI for video processing
    % Embed ImageStackViewerClass into Panels
    % Workflow panel on left
    % menubar on top
    
    % David S. White
    % 2023-03-21
    
    
    % note, handle view channel via dynamic menu building rather than the
    % list box
    
    properties
        
        hFigure
        hImageStack = ImageStack.empty()
        hImageStackViewer = {};
        hAOIViewer = {}; % temporary to handle non populated AOIs
        
        % Layout
        hShowButtonGroup
        hShowImagesOnlyBtn
        hShowTracesOnlyBtn
        hShowImagesTracesBtn
        
        % Channels
        hChannelPanel
        hChannelsListBox
        hAddChannelBtn
        hRemoveChannelsBtn
        hMoveChannelUpBtn
        hMoveChannelDownBtn
        hReferenceChannelText
        hReferenceChannelPopup

        % CoSMoS Workflow Panels
        hAlignPanel
        hAlignLoadBtn
        hAlignComputeBtn
        hAlignSaveBtn
        
        hDriftPanel
        hDriftText
        hDriftRefBtn
        hDriftAllBtn
        
        hFindAOIPanel
        hFindAOIRefBtn
        hFindAOIOutlierBtn
        hFindAOIsClearBtn
        
        hNavigationPanel
        hNavigationPrevBtn
        hNavigationPrevSelBtn
        hNavigationNextBtn
        hNavigationNextSelBtn
        hNavigationEdit
        
        
        % AOI Panels
        
        % Idealization
        hIdealizationPanel
        hCurrentChannelText
        hCurrentChannelPopup
        hIdealizationText
        hIdealizationPopup
        hIdealizationOptions
        hApplyToAllCheckBox
        hIdealizeBtn
        hClearIdealBtn
        
        % Manual Adjustent
        hManualAdjustPanel
        hNumberOfStatesBtn
        
        hManualEventBtn  %toggle
        hManualEventLeftBtn
        hManualEventRightBtn
        hManualEventUpBtn
        hManualEventDownBtn
        
        % AOI Information 
        hAOIInfoPanel
        hAOIStatusText
        hAOIStatusCheckbox
        hAOISNBText
        hAOISNBValText
        hAOINStatesText
        hAOINStatesValText
        hAOINEventsText
        hAOINEventsValText

        hLayout = '3'
        hAlignment
        
    end
    
    properties (SetObservable)
        hAOIIdx
        AOIChannel
        hPanelBorderColor = [0.7 0.7 0.7]
    end
    
    properties (Dependent)
        numImageStacks
        CurrentDataShown
        ReferenceIdx
    end
    
    properties (Access = private)
        TraceColors % so each AOIViewer loaded can have a differnt color
        BoxColor
    end
    
    methods
        
        % constructor
        function obj = smExperimentViewer()
            % Window ------------------------------------------------------
            obj.hFigure = figure('Name', 'smExperimentViewer', ...
                'Units', 'normalized', 'Position', [0.25 0.2 0.5 0.6], ...
                'MenuBar', 'none', 'ToolBar', 'none', 'numbertitle', 'off', ...
                'UserData', obj ... % ref this object
                );           % custom resize function
            obj.hFigure.Units = 'pixels';
            
            % Menu Bar ----------------------------------------------------
            hMenuFile = uimenu(obj.hFigure, 'Text', 'File');
            uimenu(hMenuFile, 'Text', 'Load Experiment');
            uimenu(hMenuFile, 'Text', 'Save Experiment');
            
            hMenuImages = uimenu(obj.hFigure, 'Text', 'Images');
            hMenuImagesLayout = uimenu(hMenuImages, 'Text', 'Layout');
            uimenu(hMenuImagesLayout, 'Text', '1xN',  'Callback', @(varargin) obj.adjustView1xN());
            uimenu(hMenuImagesLayout, 'Text', 'Nx1',  'Callback', @(varargin) obj.adjustViewNx1());
            uimenu(hMenuImagesLayout, 'Text', 'NxN',  'Callback', @(varargin) obj.adjustViewNxN());
            
            hMenuImagesPlot = uimenu(hMenuImages, 'Text', 'Plots');
            uimenu(hMenuImagesPlot, 'Text', 'AOI Intensity (ref)',  'Callback', @(varargin) obj.plotRefAOISum());
            uimenu(hMenuImagesPlot, 'Text', 'AOI Sigma (ref)',  'Callback', @(varargin) obj.plotRefAOIISigma());
            
            hMenuTraces = uimenu(obj.hFigure, 'Text', 'Traces');
            hMenuTracesPlot = uimenu(hMenuTraces, 'Text', 'Plots');
            uimenu(hMenuTracesPlot, 'Text', 'Signal to Background (SNB)',  'Callback', @(varargin) obj.plotAOISNB());
            uimenu(hMenuTracesPlot, 'Text', 'Signal to Noise (SNR)',  'Callback', @(varargin) obj.plotAOISNR());
            
            %  Channel list -----------------------------------------------
            obj.hChannelPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'Channels',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hAddChannelBtn = uicontrol(obj.hChannelPanel, 'Style', 'pushbutton', ...
                'String', '+', ...
                'Tooltip', 'Add Channel', ...
                'Callback', @(varargin) obj.addChannel()); % [0.6 0.9 0.6]
            obj.hRemoveChannelsBtn = uicontrol(obj.hChannelPanel, 'Style', 'pushbutton', ...
                'String', '-', ...
                'Tooltip', 'Remove Selected Channels', ...
                'Callback', @(varargin) obj.removeChannel()); % [1 .6 .6]
             obj.hMoveChannelUpBtn = uicontrol(obj.hChannelPanel, 'Style', 'pushbutton', ...
                'String', '^', ...
                'Tooltip', 'Add Channel', ...
                'Callback', @(varargin) obj.moveChannelUp());
            obj.hMoveChannelDownBtn = uicontrol(obj.hChannelPanel, 'Style', 'pushbutton', ...
                'String', 'v', ...
                'Tooltip', 'Remove Selected Channels', ...
                'Callback', @(varargin) obj.moveChannelDown());
            obj.hChannelsListBox = uicontrol(obj.hChannelPanel, 'Style', 'listbox', ...
                'Callback', @(varargin) obj.refresh());
            obj.hReferenceChannelText = uicontrol(obj.hChannelPanel, 'Style', 'text',...
                'String', 'Reference', 'HorizontalAlignment', 'left',...
                'FontSize', 12);
            obj.hReferenceChannelPopup = uicontrol(obj.hChannelPanel, 'Style', 'popupmenu', ...
                'String', {''}, ...
                'Tooltip', 'Surface AOIs');
            
            % Buttons for layout ------------------------------------------
            obj.hShowButtonGroup = uibuttongroup(obj.hFigure,...
                'BorderType', 'none', 'Units', 'pixels');
            obj.hShowImagesOnlyBtn = uicontrol(obj.hShowButtonGroup, 'Style', 'togglebutton', ...
                'String', 'Images', 'Value', 1, ...
                'Tooltip', 'Show Images Only', ...
                'Callback', @(varargin) obj.resize());
            obj.hShowTracesOnlyBtn = uicontrol(obj.hShowButtonGroup, 'Style', 'togglebutton', ...
                'String', 'Traces', 'Value', 0, ...
                'Tooltip', 'Show Spot Traces Only', ...
                'Callback', @(varargin) obj.resize());
             obj.hShowImagesTracesBtn = uicontrol(obj.hShowButtonGroup, 'Style', 'togglebutton', ...
                'String', 'Both', 'Value', 0, ...
                'Tooltip', 'Show Spot Traces Only', ...
                'Callback', @(varargin) obj.resize());
            
            % IMAGE ALIGNMENT ---------------------------------------------
            obj.hAlignPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'Channel Alignment',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hAlignLoadBtn = uicontrol(obj.hAlignPanel, 'Style', 'pushbutton', ...
                'String', 'Load',...
                'Callback', @(varargin) obj.loadAlignment());
            obj.hAlignComputeBtn = uicontrol(obj.hAlignPanel, 'Style', 'pushbutton', ...
                'String', 'Compute',...
                'Callback', @(varargin) obj.alignAllToReference());
            obj.hAlignSaveBtn = uicontrol(obj.hAlignPanel, 'Style', 'pushbutton', ...
                'String', 'Save',...
                'Callback', @(varargin) obj.saveAlignment());
            
            % DRIFT CORRECTION --------------------------------------------
            obj.hDriftPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'Drift Correction',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hDriftRefBtn = uicontrol(obj.hDriftPanel, 'Style', 'pushbutton', ...
                'String', 'From Reference',...
                'Callback', @(varargin) obj.driftRef());
            obj.hDriftAllBtn = uicontrol(obj.hDriftPanel, 'Style', 'pushbutton', ...
                'String', 'Seperately',...
                'Callback', @(varargin) obj.driftAll());
            
            % DETECT AOI PANEL --------------------------------------------
            obj.hFindAOIPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'Find AOIs',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hFindAOIRefBtn = uicontrol(obj.hFindAOIPanel, 'Style', 'pushbutton', ...
                'String', 'Find',...
                'Callback', @(varargin) obj.findAOIsInReference());
            obj.hFindAOIOutlierBtn = uicontrol(obj.hFindAOIPanel, 'Style', 'pushbutton', ...
                'String', 'Filter', ...
                'Callback', @(varargin) obj.filterReferenceAOI());
            obj.hFindAOIsClearBtn = uicontrol(obj.hFindAOIPanel, 'Style', 'pushbutton', ...
                'String', 'Clear', ...
                'Callback', @(varargin) obj.clearAllAOIs());
            
            
            % AOI Naviation -----------------------------------------------
            obj.hNavigationPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'AOI Navigation',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hNavigationPrevBtn = uicontrol(obj.hNavigationPanel, 'Style', 'pushbutton', ...
                'String', '<',...
                'Callback', @(varargin) obj.prevAOI());
            obj.hNavigationNextBtn = uicontrol(obj.hNavigationPanel, 'Style', 'pushbutton', ...
                'String', '>',...
                'Callback', @(varargin) obj.nextAOI());
            obj.hNavigationEdit = uicontrol(obj.hNavigationPanel, 'Style', 'Edit', ...
                'String', '0', 'BackgroundColor', 'w', ...
                'Callback', @(varargin) obj.manualAOI());
            obj.hNavigationPrevSelBtn = uicontrol(obj.hNavigationPanel, 'Style', 'pushbutton', ...
                'String', '<<',...
                'Callback', @(varargin) obj.prevSelAOI());
            obj.hNavigationNextSelBtn = uicontrol(obj.hNavigationPanel, 'Style', 'pushbutton', ...
                'String', '>>',...
                'Callback', @(varargin) obj.nextSelAOI());
            
            % IDEALIZATION PANEL ------------------------------------------
            obj.hIdealizationPanel = uipanel(obj.hFigure,...
                'Units', 'pixels',...
                'BorderType', 'line', ...
                'AutoResizeChildren', 'off', ...
                'Visible', 'Off',...
                'Title', 'Idealization',...
                'FontSize', 12,...
                'FontName', 'Helvetica',...
                'BackgroundColor', [0.94 0.94 0.94],...
                'ForegroundColor', [0 0 0 ],...
                'ShadowColor', [0.7 0.7 0.7],...
                'fontweight', 'bold');
            obj.hCurrentChannelText = uicontrol(obj.hIdealizationPanel,...
                'Style', 'text', ...
                'String', 'Channel');
            obj.hCurrentChannelPopup = uicontrol(obj.hIdealizationPanel,...
                'Style', 'popupmenu', ...
                'String', {''}); % populate via add/delete channel
            obj.hIdealizationText = uicontrol(obj.hIdealizationPanel,...
                'Style', 'text', ...
                'String', 'Method');
            obj.hIdealizationPopup = uicontrol(obj.hIdealizationPanel,...
                'Style', 'popupmenu', ...
                'String', {'DISC', 'vbFRET', 'SKM', 'PELT', 'CP-HAC', 'Threshold'}); % populate via detecting that is installed?
            obj.hIdealizationOptions = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', 'Options',...
                'Callback', @(varargin) obj.setIdealParameters());
            obj.hApplyToAllCheckBox = uicontrol(obj.hIdealizationPanel,...
                'Style', 'Checkbox',...
                'String', 'All',...
                'Value', 0); 
            obj.hIdealizeBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', 'Idealize',...
                'Callback', @(varargin) obj.runIdealize());
            obj.hClearIdealBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', 'Clear',...
                'Callback', @(varargin) obj.clearIdeal());
            
            % manul adjustment of idealization
            obj.hNumberOfStatesBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'togglebutton',...
                'String', 'States',...
                'Value', 0);
            obj.hManualEventBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'togglebutton',...
                'Value', 0,...
                'String', 'Events'); % callback or listener needed here --------------------------
            obj.hManualEventLeftBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', '<',...
                'Enable', 'off',...
                'Callback', @(varargin) obj.manualEventPrev());
            obj.hManualEventRightBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', '>',...
                'Enable', 'off',...
                'Callback', @(varargin) obj.manualEventNext());
            obj.hManualEventUpBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', '^',...
                'Enable', 'off',...
                'Callback', @(varargin) obj.manualEventUp());
            obj.hManualEventDownBtn = uicontrol(obj.hIdealizationPanel,...
                'Style', 'pushbutton', ...
                'String', 'v',...
                'Enable', 'off',...
                'Callback', @(varargin) obj.manualEventDown());
            
            % KEYBOARD SHORTCUTS ------------------------------------------
            set(obj.hFigure, 'KeyPressFcn', @keyPressedLocal)
            % addlistener(obj, 'hAOIIdx', 'PostSet', @(varargin) obj.updateAOI());
            
            function keyPressedLocal(obj, event)
                event.Key;
                switch event.Key
                    case {'rightarrow'}
                        obj.UserData.nextAOI;
                        
                    case {'leftarrow'}
                        obj.UserData.prevAOI;
                end
            end
            
            % RESIZE OBJECT -----------------------------------------------
            obj.hFigure.SizeChangedFcn = @(varargin) obj.resize();
            obj.resize(); % update layout
            
        end
        
        function delete(obj)
            %DELETE Delete all graphics objects and listeners.
            obj.deleteListeners();
            for i = 1:numel(obj.hImageStackViewer)
                delete(obj.hImageStackViewer{i});
                 delete(obj.hAOIViewer{i});
            end 
            delete(obj.hFigure); % will delete all other child graphics objects
        end
        
        function deleteListeners(obj)
        end
        
        function n = get.numImageStacks(obj)
            n = length(obj.hImageStack);
            if n == 1 && isempty(obj.hImageStack)
                n = 0;
            end
        end
        
        function nextAOI(obj)
           % which AOI should we be on (min across all AOI viewers)
           idx0 =  min(horzcat(obj.hAOIViewer{1}.idx))+1;
           if idx0 <= obj.hImageStack(1).numberOfAOIs
               obj.hAOIIdx = idx0;
               obj.updateAOIText;
               for i = 1:numel(obj.hAOIViewer) % needs to be a better way
                   obj.hAOIViewer{i}.idx = idx0;
               end
           end
        end
        
         function prevAOI(obj)
           % which AOI should we be on (min across all AOI viewers)
           idx0 =  min(horzcat(obj.hAOIViewer{1}.idx))-1;
           if idx0 > 0
               obj.hAOIIdx = idx0;
               obj.updateAOIText;
               for i = 1:numel(obj.hAOIViewer) % needs to be a better way
                   obj.hAOIViewer{i}.idx = idx0;
               end
           end
         end
         
         function updateAOI(obj)
             idx0 = obj.hAOIIdx;
             if idx0 > 0 && idx0 <= obj.hImageStack(1).numberOfAOIs
                 obj.updateAOIText;
                 for i = 1:numel(obj.hAOIViewer) % needs to be a better way
                     obj.hAOIViewer{i}.idx = idx0;
                 end
             end
         end
         
        function updateAOIText(obj)
            obj.hNavigationEdit.String = num2str(obj.hAOIIdx);
            
        end
        
        function refresh(obj)
            % obj.hExperiment = obj.hExperiment;
        end
        
        function addChannel(obj)
            loadImagesToMemory = 1;
            imageDataTemp = loadImageStackToClass([], loadImagesToMemory);
            % check for imageDataTemp empty?
            
            for k = 1:length(imageDataTemp)
                obj.hImageStack = [obj.hImageStack imageDataTemp{k}];
                p = numel(obj.hImageStack);
                obj.hImageStackViewer{p} = ImageStackViewer(imageDataTemp{k}, obj.hFigure);
                obj.hAOIViewer{p} = [];
                addlistener(obj.hImageStack(p), 'AOIsIntegrated', 'PostSet', @(varargin) obj.updateAOIViewers(p));
            end
            obj.updateChannelList();
            obj.resize();
            
        end
        function updateAOIViewers(obj, k)
            if ~isempty(obj.hImageStack(k).AOIs)
                obj.hAOIViewer{k} = AOIViewer(obj.hImageStack(k), obj.hFigure);
                obj.hAOIIdx = 1; 
            else
                obj.hAOIViewer{k}.delete();
                obj.hAOIViewer(k) = [];
            end
            % switch case to detemine if resize
            obj.resize();
        end
        function removeChannel(obj)
            % pop up to confirm
            idx = obj.hChannelsListBox.Value;
            if ~isempty(idx) && obj.numImageStacks > 0
                answer = questdlg('Delete Channel?', ...
                    '', ...
                    'Yes','No','No');
                switch answer
                    case 'Yes'
                        obj.hImageStackViewer{idx}.delete();
                        obj.hImageStackViewer(idx) = [];
                        if isempty(obj.hAOIViewer{idx})
                            obj.hAOIViewer{idx}.delete();
                            obj.hAOIViewer(idx) = [];
                        end
                        obj.hImageStack(idx) = [];
                        obj.updateChannelList();
                        obj.resize();
                    case 'No'
                end
                
            end
        end
        
        function updateChannelList(obj)
            % update channel list box and reference box
            if ~isempty(obj.hImageStack)
                v = obj.hChannelsListBox.Value-1;
                if v == 0
                    v = 1;
                end
                obj.hChannelsListBox.Value = v;
                obj.hChannelsListBox.Max = length(obj.hImageStack);
                obj.hChannelsListBox.String = horzcat(obj.hImageStack.name);
                obj.hReferenceChannelPopup.String = horzcat(obj.hImageStack.name);
                obj.hCurrentChannelPopup.String = horzcat(obj.hImageStack.name);
                if isempty(obj.hReferenceChannelPopup.Value)
                    obj.hReferenceChannelPopup.Value = 1;
                     obj.hCurrentChannelPopup.Value = 1;
                end
                % value will be [1] [1,2] [1,2,3] etc if all are selected
                % can use this as a "selection" tool for visualization?
            else
                obj.hChannelsListBox.String = {};
                obj.hChannelsListBox.Value = 1;
                obj.hChannelsListBox.Max = 1;
                obj.hReferenceChannelPopup.Value = 1;
                obj.hReferenceChannelPopup.String = {''};
                obj.hCurrentChannelPopup.Value = 1;
                obj.hCurrentChannelPopup.String = {''};
            end
        end
        
        % adjust view
        function adjustView1xN(obj)
            obj.hLayout = '1';
            obj.resize();
        end
        function adjustViewNx1(obj)
            obj.hLayout = '2';
            obj.resize();
        end
        function adjustViewNxN(obj)
            obj.hLayout = '3';
            obj.resize(); % or listener?
        end
        
        function c = get.CurrentDataShown(obj)
            showImages = obj.hShowImagesOnlyBtn.Value;
            showTraces = obj.hShowTracesOnlyBtn.Value;
            showImagesTraces = obj.hShowImagesTracesBtn.Value;
            
            if showImages && ~showTraces && ~showImagesTraces
                c = 'images';
            elseif ~showImages && showTraces && ~showImagesTraces
                c = 'traces';
            elseif ~showImages && ~showTraces && showImagesTraces
                c = 'traces&images';
            else
                c = 'none';
            end
        end
        
        function r = get.ReferenceIdx(obj)
            r = 0; 
            if obj.numImageStacks > 0
                r = obj.hReferenceChannelPopup.Value;
            end
        end

        function driftCorrectAll(obj)
        end
        
        function alignAllToReference(obj)
            if obj.numImageStacks > 1
                obj.hAlignment = cell(obj.numImageStacks-1); 
                % for now just storing a similarity transform, in future
                % store infomrationa on channel name and the affine
                % transform
                j = obj.ReferenceIdx;
                if obj.hImageStack(j).numFrames >= 10
                    nf = 10;
                else
                    nf = obj.hImageStack(j).numFrames;
                end
                 image1 = mean(obj.hImageStack(j).data(:,:,1:nf),3);
                for i = 1:obj.numImageStacks
                    if i ~= j
                        % should have something about selecting specific
                        % frames, for now jsut use first 10 frames
                        image2 = mean(obj.hImageStack(i).data(:,:,1:nf),3);
                        obj.hAlignment{i} = alignImages(image1, image2, 1);
                    end
                end
                
            end
        end
        
        function findAOIsInReference(obj)
            % find and intergrate AOIs in the reference channel
            obj.hImageStack(obj.ReferenceIdx).findAOIs;
            bbdiameter = obj.hImageStack(obj.ReferenceIdx).AOIs(1).boundingBox(3);
            for i = 1:obj.numImageStacks
                if i ~=obj.ReferenceIdx
                    
                    tform = obj.hAlignment{i};
                    centroidsA = vertcat( obj.hImageStack(obj.ReferenceIdx).AOIs.centroid);
                    centroidsB = transformPointsInverse(tform, centroidsA);
                    
                    % HARDCODED NEED TO FIX THIS !!!!!
                    idx1 = unique([find(centroidsB(:,1) < 10); find(centroidsB(:,1) > 512-10);...
                        find(centroidsB(:,2) < 10); find(centroidsB(:,2) > 512-10)]);
                    if ~isempty(idx1)
                        centroidsB(idx1,:) = [];
                        obj.hImageStack(obj.ReferenceIdx).AOIs(idx1) = [];
                        % obj.hAOIViewer{obj.ReferenceIdx}.hAOI(idx1) = [];
                        obj.hAOIViewer{obj.ReferenceIdx} = AOIViewer(obj.hImageStack(obj.ReferenceIdx), obj.hFigure);
                        obj.hAOIViewer{obj.ReferenceIdx}.hPanel.Visible = 'off';
                    end
                    
                    % store result 
                    boundingBox = makeBoundingBox(centroidsB, bbdiameter);
                    newAOIs = []; 
                    for k = 1:size(centroidsB,1)
                        if k == 1
                            newAOIs = AOI(centroidsB(k,:), [], boundingBox(k,:), []);
                        else
                            newAOIs = [newAOIs; AOI(centroidsB(k,:), [], boundingBox(k,:), [])];
                        end
                       
                    end
                    obj.hImageStack(i).AOIs = newAOIs; 
                    obj.hImageStack(i).integrateAOIs();
                    
                    % this wont work unless its indexed
                    obj.hAOIViewer{i} = AOIViewer(obj.hImageStack(i), obj.hFigure);
                    obj.hAOIViewer{i}.hPanel.Visible = 'off';
                end
            end
            obj.resize();
        end
        
        function filterReferenceAOI(obj)
        end
        
        function intergrateAllAOI(obj)
        end
        
        function saveAOIs(obj)
        end
        
        function resize(obj)
            % Resize all objects (lots of cases..)
            
            % DRAW LEFT PANEL ()
            
            % Reize all objects
            
            bbox = getpixelposition(obj.hFigure); % [distance from left, distance from bottom, width, height].
            
            if ismac
                margin = 5;         % spacing
                lineh = 20;         % lineheight
                x = margin;         % x start (left to right
                y = bbox(4)-margin; % y start (top to bottom)
                w = 250;            % width of the panel
                w1 = w-2*margin;        % inner panel width
            else
            end
            
            % LAYOUT ------------------------------------------------------
            y = y-margin-lineh;
            obj.hShowButtonGroup.Position = [x y w lineh];
            x1 = 1;
            y1 = 1;
            obj.hShowImagesOnlyBtn.Position = [x1, y1, w/3, lineh];
            obj.hShowTracesOnlyBtn.Position = [x1+w/3, y1, w/3, lineh];
            obj.hShowImagesTracesBtn.Position = [x1+2*w/3, y1, w/3, lineh];

            
            % CHANNEL PANEL -----------------------------------------------
            panelheight = lineh*6+2*margin;
            y = y - panelheight-3*margin;
            obj.hChannelPanel.Position = [x, y, w, panelheight];
            obj.hChannelPanel.Visible = 'on';
            obj.hChannelPanel.BorderType = 'line';
            obj.hChannelPanel.HighlightColor = obj.hPanelBorderColor;
            
            % inside panel
            y1 = panelheight-40; % arbirtray, odd size issue
            obj.hAddChannelBtn.Position = [x+w1-lineh y1 lineh lineh];
            obj.hRemoveChannelsBtn.Position = [x+w1-lineh y1-lineh lineh lineh];
            obj.hMoveChannelUpBtn.Position = [x+w1-lineh y1-2*lineh lineh lineh];
            obj.hMoveChannelDownBtn.Position = [x+w1-lineh y1-3*lineh lineh lineh];

            y1 = y1 - 3*lineh;
            obj.hChannelsListBox.Position = [x y1 w1-lineh 4*lineh];
            
            y1 = y1-margin-lineh;
            obj.hReferenceChannelText.Position = [x y1 w1*0.25 lineh];
            obj.hReferenceChannelPopup.Position = [x + w1*0.25 y1 w1*0.75 lineh];
            
            
            % AOI NAVIGATION PANEL --------------------------------
            panelheight = 2*(lineh+margin);
            
            y = y - panelheight-2*margin;
            obj.hNavigationPanel.Visible = 'on';
            obj.hNavigationPanel.Position = [x, y, w, panelheight];
            obj.hNavigationPanel.BorderType = 'line';
            obj.hNavigationPanel.HighlightColor = obj.hPanelBorderColor;
            
            % inside
            y1 = panelheight-2*lineh;
            w2 = w1/6; 
            obj.hNavigationPrevSelBtn.Position = [x, y1, w2, lineh];
            obj.hNavigationPrevBtn.Position = [x+w2, y1, w2, lineh];
            obj.hNavigationEdit. Position = [x+2*w2, y1, 2*w2, lineh];
            obj.hNavigationNextBtn.Position = [x+4*w2, y1, w2, lineh];
            obj.hNavigationNextSelBtn.Position = [x+5*w2, y1, w2, lineh];
            
            
            % Layout -----------------------------------------------------
            
            switch obj.CurrentDataShown
                % PLOT IMAGES ONLY ----------------------------------------
                case 'images'
                    % switch workflow based on what is visable --------------------
                     obj.hIdealizationPanel.Visible = 'off';
                    
                    % close AOI Viewers 
                    for i = 1:numel(obj.hAOIViewer)
                        obj.hAOIViewer{i}.hPanel.Visible = 'off';
                    end
                    
                    % DRIFT CORRECTION PANEL ------------------------------
                    panelheight = 2*(lineh+margin);
                    
                    y = y - panelheight-2*margin;
                    obj.hDriftPanel.Visible = 'on';
                    obj.hDriftPanel.Position = [x, y, w, panelheight];
                    obj.hDriftPanel.BorderType = 'line';
                    obj.hDriftPanel.HighlightColor = obj.hPanelBorderColor;
                    
                    % inside the panel
                    y1 = panelheight-2*lineh;
                    obj.hDriftRefBtn.Position = [x, y1, w1/2, lineh];
                    obj.hDriftAllBtn.Position = [x+w1/2, y1, w1/2, lineh];
                    
                    % CHANNEL ALIGNMENT PANEL -----------------------------
                    panelheight = 2*(lineh+margin);
                    y = y - panelheight-2*margin;
                    obj.hAlignPanel.Visible = 'on';
                    obj.hAlignPanel.Position = [x, y, w, panelheight];
                    obj.hAlignPanel.BorderType = 'line';
                    obj.hAlignPanel.HighlightColor = obj.hPanelBorderColor;
                    
                    % inside the panel
                    y1 = panelheight-2*lineh;
                    obj.hAlignLoadBtn.Position = [x, y1, w1/3, lineh];
                    obj.hAlignComputeBtn.Position = [x+w1/3, y1, w1/3, lineh];
                    obj.hAlignSaveBtn.Position = [x+2*w1/3, y1, w1/3, lineh];
                   
                    
                    % DETECT AOI PANEL ------------------------------------
                    panelheight = 2*(lineh+margin);
                    
                    y = y - panelheight-2*margin;
                    obj.hFindAOIPanel.Visible = 'on';
                    obj.hFindAOIPanel.Position = [x, y, w, panelheight];
                    obj.hFindAOIPanel.BorderType = 'line';
                    obj.hFindAOIPanel.HighlightColor = obj.hPanelBorderColor;
                    
                    % inside the panel
                    y1 = panelheight-2*lineh;
                    obj.hFindAOIRefBtn.Position = [x, y1, w1/3, lineh];
                    obj.hFindAOIOutlierBtn.Position = [x+w1/3, y1, w1/3, lineh];
                    obj.hFindAOIsClearBtn.Position = [x+2*w1/3, y1, w1/3, lineh];
                    
                    
                    % IMAGE STACK VIEWERS ---------------------------------
                    
                    % [distance from left, distance from bottom, width, height].
                    if ~isempty(obj.hImageStack)
                        
                        bbox = getpixelposition(obj.hFigure);
                        nImageStacks = length(obj.hImageStack);
                        x1 = x+w;
                        ytop = bbox(4)-margin; % align to top panel
                        
                        switch obj.hLayout
                            case {'1', 'Nx1', 'nx1'}
                                maxWidth = bbox(3)-2*margin-x1;
                                panelSize = maxWidth;
                                if panelSize*nImageStacks > panelSize
                                    panelSize = floor(panelSize/(nImageStacks));
                                end
                                for i = 1:nImageStacks
                                    if ~isempty(obj.hImageStackViewer(i))
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Pixels';
                                        obj.hImageStackViewer{i}.Position = [(x1+margin)+(i-1)*(panelSize) ytop-panelSize panelSize panelSize];
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Normalized';
                                        obj.hImageStackViewer{i}.showAOIs();
                                    end
                                end
                            case {'2', '1xN', '1xn'}
                                maxHeight = bbox(4)-2*margin;
                                panelSize = maxHeight;
                                if panelSize*nImageStacks > panelSize
                                    panelSize = floor(panelSize/(nImageStacks));
                                end
                                for i = 1:nImageStacks
                                    if ~isempty(obj.hImageStackViewer{i})
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Pixels';
                                        obj.hImageStackViewer{i}.Position = [x1 (ytop-margin)-(i)*(panelSize) panelSize panelSize];
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Normalized';
                                        obj.hImageStackViewer{i}.showAOIs();
                                    end
                                end
                                
                            case {'3', 'NxM', 'nxm'}
                                % need something for if nchannels > 2
                                if nImageStacks > 2
                                    nrow = ceil(sqrt(nImageStacks));
                                else
                                    nrow = 1;
                                end
                                ncol = ceil(nImageStacks/nrow);
                                maxWidth = (bbox(3)-2*margin-x1) / ncol;
                                maxHeight = (bbox(4)-2*margin) / nrow;
                                if maxWidth >= maxHeight
                                    panelSize = maxHeight;
                                else
                                    panelSize = maxWidth;
                                end
                                
                                % position 1, 2; 3, 4 etc..
                                for i = 1:ncol
                                    y = ytop-panelSize;
                                    if ~isempty(obj.hImageStackViewer{i})
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Pixels';
                                        obj.hImageStackViewer{i}.Position = [(x1+margin)+(i-1)*(panelSize) y panelSize panelSize];
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Normalized';
                                        obj.hImageStackViewer{i}.hPanel.Visible = 'on';
                                        obj.hImageStackViewer{i}.showAOIs();
                                    end
                                end
                                p = 0;
                                for i = ncol+1:nImageStacks
                                    y = ytop-2*(panelSize)-margin;
                                    if ~isempty(obj.hImageStackViewer{i})
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Pixels';
                                        obj.hImageStackViewer{i}.Position = [(x1+margin)+p*(panelSize) y panelSize panelSize];
                                        obj.hImageStackViewer{i}.hPanel.Units = 'Normalized';
                                        obj.hImageStackViewer{i}.hPanel.Visible = 'on';
                                        p = p +1;
                                        obj.hImageStackViewer{i}.showAOIs();
                                    end
                                end
                                
                        end
                    end
                   
                    % Draw AOIViewers Only --------------------------------
                case {'traces'}
                    % workflow panel 
                    obj.hFindAOIPanel.Visible = 'off';
                    obj.hDriftPanel.Visible = 'off';
                    obj.hAlignPanel.Visible = 'off';
                     
                    % hide ImageStackViewers                
                    for i = 1:numel(obj.hImageStackViewer)
                        obj.hImageStackViewer{i}.hPanel.Visible = 'off';
                    end
                    
                    % IDEALIZATION PANEL ----------------------------------
                    panelheight = 6*lineh;
                    y = y - panelheight-2*margin;
                    obj.hIdealizationPanel.Visible = 'on';
                    obj.hIdealizationPanel.Position = [x, y, w, panelheight];
                    obj.hIdealizationPanel.BorderType = 'line';
                    obj.hIdealizationPanel.HighlightColor = obj.hPanelBorderColor;
                    
                    % inside the panel
                    y1 = panelheight-2*lineh;
                    y2 = y1-lineh-margin;
                    y3 = y2 - lineh-margin;
                    y4 = y3-lineh;
                    
                    obj.hCurrentChannelText.Position = [x y1 w1*0.2 lineh];
                    obj.hCurrentChannelPopup.Position = [x + w1*0.2 y1 w1*0.6 lineh];
                    obj.hApplyToAllCheckBox.Position = [x+w1*0.8, y1, w1*0.2, lineh];
                    
                    obj.hIdealizationText.Position = [x y2 w1*0.2 lineh];
                    obj.hIdealizationPopup.Position = [x + w1*0.2 y2 w1*0.6 lineh];
                    obj.hIdealizationOptions.Position = [x+w1*0.8, y2, w1*0.2, lineh];
                    
                    w2 = w1/2;
                    w3 = w2/2;
                    w4 = w3/2;
                    obj.hIdealizeBtn.Position = [x, y3, w2, lineh];
                    obj.hClearIdealBtn.Position = [x, y4, w2, lineh];
                    x1 = x+w2;
                    x2 = x+w2+w1/4;
                    obj.hNumberOfStatesBtn.Position = [x1, y3, w3, lineh];
                    obj.hManualEventBtn.Position = [x2, y3, w3, lineh];
                    
                    obj.hManualEventUpBtn.Position = [x1, y4, w4, lineh];
                    obj.hManualEventDownBtn.Position = [x1+w4, y4, w4, lineh];
                    
                    obj.hManualEventLeftBtn.Position = [x1+2*w4, y4, w4, lineh];
                    obj.hManualEventRightBtn.Position = [x1+3*w4, y4, w4, lineh];
                    
                    % AOI INFO PANEL --------------------------------------
                    
                    
                    % AOIViewers
                    nAOIViewers = numel(obj.hAOIViewer);
                    x1 = x+w+margin;
                    ytop = bbox(4)-margin; % align to top panel
                    panelWidth = bbox(3)-2*margin-x1;
                    panelHeight = floor((bbox(4)-2*margin)/nAOIViewers);

                    for i = 1:nAOIViewers
                        if ~isempty(obj.hAOIViewer{i})
                            obj.hAOIViewer{i}.hPanel.Units = 'Pixels';
                            obj.hAOIViewer{i}.Position = [x1 (ytop-margin)-(i)*(panelHeight) panelWidth panelHeight];
                            obj.hAOIViewer{i}.hPanel.Units = 'Normalized';
                            obj.hAOIViewer{i}.hPanel.Visible = 'on';
                        end
                    end
                    
                case {'traces&images'}
                    obj.hFindAOIPanel.Visible = 'off';
                    obj.hDriftPanel.Visible = 'off';
                    obj.hAlignPanel.Visible = 'off';
                case {'none'}
            end
        end
        
    end
    
end