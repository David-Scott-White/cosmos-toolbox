classdef ImageStack < handle
    % ----------------------------------------------------------------------
    % ImageStack Class
    % ----------------------------------------------------------------------
    %
    % Supports 2D and 3D image stacks. 8-bit, 16-bit, or floating
    % Can load image stack to memory or call frames as needed.
    %
    % Contains multiple instances of AOI class
    % Can be contained in an Experiment class (future)
    %å
    % Requirements:
    %   Image Processing Toolbox
    %   bfmatlab
    %
    % David S. White
    % dwhite7@wisc.edu
    %
    % License: GNU General Public License v3.0
    % Copyright (C) 2023 David S. White
    %
    % This program is free software: you can redistribute it and/or modify
    % it under the terms of the GNU General Public License as published by
    % the Free Software Foundation, either version 3 of the License, or
    % (at your option) any later version.
    %
    % This program is distributed in the hope that it will be useful,
    % but WITHOUT ANY WARRANTY; without even the implied warranty of
    % MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    % GNU General Public License for more details.
    %
    % You should have received a copy of the GNU General Public License
    % along with this program.  If not, see <https://www.gnu.org/licenses/>.
    % ---------------------------------------------------------------------
    
    
    % functions to add 
    % IdealizeThis
    % IdelizeAll
    % removeOutOfBoundAOIs
    % alignAllChannels
    
    properties
        
        % General image stack information
        filePath = [];
        fileInfo = [];
        type = [];
        fileFrameIndex = [];
        fileChannelIndex = [];
        name = '';
        time_s = [];
        exposure_s = [];
        data =  [];
        
        activeFrames % User Selected Frames to Navigate
        activePixels % Cropped
        backgroundSE = [];
        driftList = [];
        driftApplied = false
        flipVertical = false
        flipHorizontal = false
        loadDataToMemory = false
        aoiParameters
        channelTform % similarity transform 
        aoiTform % affine transform of points
        % need a prompt for setting concentration... (2x)
        
    end
    
    properties (SetObservable)
        AOIs
        AOIsIntegrated = 0;
        % AOIViewer = AOIViewer.empty();
    end
    
    properties (Dependent)
        width
        height
        numFrames
        totalTime_s
        numberOfAOIs
        DataLoadedToMemory
        BrightnessContrast
    end
    
    
    events
        
    end
    
    methods
        % Constructor -----------------------------------------------------
        function obj = ImageStack()
            % should have ability to add information 
        end
        
        % -----------------------------------------------------------------
        % Dependent Properties
        % -----------------------------------------------------------------
        
        % width (pixels)
        function w = get.width(obj)
            w = [];
            if ~isempty(obj.fileInfo)
                w = obj.fileInfo(1).Width;
            elseif ~isempty(obj.data)
                w = size(obj.data,2);
            end
        end
        
        % height (pixels)
        function h = get.height(obj)
            h = [];
            if ~isempty(obj.fileInfo)
                h = obj.fileInfo(1).Height;
            elseif ~isempty(obj.data)
                h = size(obj.data,1);
            end
        end
        
        % Active Pixels
        function x = get.activePixels(obj)
            x = obj.activePixels;
            if isempty(obj.activePixels)
                x = cell(1,2);
                x{1} = [1, obj.height];
                x{2} = [1, obj.width];
            end
        end
        
        % Number of frames (in case truncated?)
        function n = get.numFrames(obj)
            n = [];
            if ~isempty(obj.fileInfo)
                n = length(obj.fileInfo);
            elseif ~isempty(obj.data)
                n = size(obj.data,3);
            end
        end
        
        % Total time (s)
        function t = get.totalTime_s(obj)
            t = [];
            if ~isempty(obj.time_s)
                t = obj.time_s(end);
            end
        end
        
        % number of AOIs
        function n = get.numberOfAOIs(obj)
            n = [];
            if ~isempty(obj.AOIs)
                n = length(obj.AOIs);
            end
        end
        
        % Data loaded to memory
        function bool = get.DataLoadedToMemory(obj)
            bool = false;
            if ~isempty(obj.data)
                bool = true;
            end
        end
        
        % Set properties
        function set.name(obj, n)
            obj.name = n;
        end
        
        % Reset active pixels
        function resetActivePixels(obj)
            obj.activePixels = {[1, obj.height], [1,obj.width]};
        end
        
        function setBackgroundSE(obj)
            prompt = {'Enter radius size (''disk''):'};
            dlgtitle = 'SE Input';
            dims = [1 35];
            definput = {'2'};
            answer = inputdlg(prompt,dlgtitle,dims,definput);
            obj.backgroundSE = strel('disk', round(str2double(answer{1})));
        end
        
        % -----------------------------------------------------------------
        % Set Active Pixel Region
        % -----------------------------------------------------------------
        function setActivePixels(obj, fpr)
            if ~exist('fpr', 'var') || isempty(fpr)
                prompt = {'Row Start','Row End', 'Column Start', 'Column End'};
                dlgtitle = 'Pixel Region';
                dims = [1 35];
                if isempty(obj.activePixels)
                    definput = {'1', num2str(obj.width),'1', num2str(obj.height)};
                else
                    definput = {num2str(obj.activePixels{1}(1)), num2str(obj.activePixels{1}(2)),...
                        num2str(obj.activePixels{2}(1)), num2str(obj.activePixels{2}(2))};
                end
                answer = inputdlg(prompt,dlgtitle,dims,definput);
                if ~isempty(answer)
                    fpr = {[str2double(answer{1}), str2double(answer{2})],...
                        [str2double(answer{3}), str2double(answer{4})]};
                    
                    % check for possible errors
                    if fpr{1}(1) < 1; fpr{1}(1) = 1; end
                    if fpr{1}(2) > obj.width; fpr{1}(2) = obj.width; end
                    if fpr{1}(1) > fpr{1}(2); fpr{1}(1) = fpr{1}(2); end
                    if fpr{2}(1) < 1; fpr{2}(1) = 1; end
                    if fpr{2}(2) > obj.height; fpr{2}(2) = obj.height; end
                    if fpr{2}(1) > fpr{2}(2); fpr{2}(1) = fpr{2}(2); end
                    obj.activePixels = fpr;
                end
            else
                obj.activePixels = fpr;
            end
        end
        
        function set.activePixels(obj, fpr)
            obj.activePixels = fpr;
        end
        
        % Load an Image ---------------------------------------------------
        function obj = load(obj)
            if isempty(obj.fileInfo)
                output = loadImageStack([], obj.loadDataToMemory);
            else
                output = loadImageStack(obj.fileInfo, obj.loadDataToMemory);
            end
            % need warning form multiple instances;
            if length(output) > 1
                % warning dialog. select desired channel
            end
        end
        
        % -----------------------------------------------------------------
        % Return a Specified Frame.
        % -----------------------------------------------------------------
        function frame = getFrame(obj, i)
            frame = [];
            if i <= obj.numFrames && i > 0
                if ~isempty(obj.data)
                    frame = obj.data(:,:,i);
                    frame = uint16(frame(obj.activePixels{1}(1):obj.activePixels{1}(2), obj.activePixels{2}(1):obj.activePixels{2}(2)));
                elseif ~isempty(obj.fileInfo)
                    frame = imread(obj.fileInfo(i).Filename, 'Info', obj.fileInfo(i),...
                        'PixelRegion', obj.activePixels);
                else
                    disp('ERROR: image stack is empty')
                end
            else
                disp('ERROR: image index (i) is outside of frame index')
            end
            if obj.flipVertical
                frame = flip(frame,1);
            end
            if obj.flipHorizontal
                frame = flip(frame,2);
            end
            if ~isempty(obj.backgroundSE)
                frame = imtophat(frame, obj.backgroundSE);
            end
        end
        
        % Preview a frame. Auto image brightness/contrast -----------------
        function showFrame(obj, i)
            frame = getFrame(obj,i);
            if ~isempty(frame)
                [mu,sd] = normfit(frame(:));
                figure;
                imshow(frame, [mu-2*sd, mu+8*sd]);
            end
        end
        
        % -----------------------------------------------------------------
        % Load all images to memory
        % -----------------------------------------------------------------
        function loadImagesToMemory(obj)
            str =  sprintf('Loading Images To Memory %dx%dx%d', obj.width, obj.height, obj.numFrames);
            wb = waitbar(0, str);
            obj.data = [];
            images = zeros(obj.height, obj.width, obj.numFrames);
            for i = 1:obj.numFrames
                images(:,:,i) = obj.getFrame(i);
                waitbar(i/obj.numFrames, wb)
            end
            obj.data = images;
            close(wb)
        end
        
        function clearImagesFromMemory(obj)
            if obj.DataLoadedToMemory
                obj.data = [];
            end
        end
        
        % -----------------------------------------------------------------
        % Set Detection AOI paramters
        % -----------------------------------------------------------------
        function setAOIParameters(obj, params)
            if ~exist('params', 'var') || isempty(params)
                % radius, gaussian tolerance, frame1, frame2
                prompt = {'Frame 1', 'Frame 2', 'Radius', 'False Positive', 'Gaussian Tolerance'};
                dlgtitle = 'AOI params.';
                dims = [1 35];
                if isempty(obj.aoiParameters)
                    definput = {'1', '5', '2', '20', '1e-5'};
                else
                    definput = {num2str(obj.aoiParameters.refImageIdx(1)), num2str(obj.aoiParameters.refImageIdx(2)),...
                        num2str(obj.aoiParameters.radius), num2str(obj.aoiParameters.falsePositive), num2str(obj.aoiParameters.gaussTol)};
                end
                
                % might be easier to store all as a struct (readability)
                answer = inputdlg(prompt,dlgtitle,dims,definput);
                if ~isempty(answer)
                    params = zeros(1,5);
                    for i = 1:5
                        params(i) = str2double(answer{i});
                    end
                end
            end
            temp = struct;
            temp.method = 'GLRT';
            temp.refImageIdx = [params(1), params(2)];
            temp.radius = params(3);
            temp.falsePositive = params(4);
            if params(5) > 0
                temp.gaussBool = 1;
            else
                temp.gaussBool = 0;
            end
            temp.gaussTol = params(5);
            obj.aoiParameters = temp;
        end
        
        function set.aoiParameters(obj, params)
            obj.aoiParameters = params;
        end
        
        % -----------------------------------------------------------------
        % Find Areas of interest (call external function)
        % -----------------------------------------------------------------
        function findAreasOfInterest(obj, showResult)
            % find and integrate AOIs
            if nargin < 2
                showResult = 0;
            end
            % see if there are paramters, if not set
            if isempty(obj.aoiParameters)
                setAOIParameters(obj, [])
            end
            referenceImage = 0;
            for i = obj.aoiParameters.refImageIdx(1):obj.aoiParameters.refImageIdx(2)
                referenceImage = referenceImage + getFrame(obj,i);
            end
            % add in AOI parameters
            obj.AOIs = findAOIs(referenceImage,...
                'radius', obj.aoiParameters.radius,...
                'gaussianTolerance', obj.aoiParameters.gaussTol,...
                'falsePositive', obj.aoiParameters.falsePositive);
            
            % remove out of frame AOIs (from drift, alignment)
            if obj.driftApplied
                obj.removeOutOfBoundAOIs
            end
        end
        
        function integrateAOIs(obj)
            if ~isempty(obj.AOIs)
                obj.AOIs = integrateAOIs(obj.AOIs, obj.data);
                obj.AOIsIntegrated = 1;
            end
        end
        
        function applyChannelTransform(obj)
            
        end
        
        function applyAOITransform(obj)
        end
        
        
        function mapAOIs(obj, centroids, bbdiameter)
            % centroids come from another channel. 
            % make AOI class here
            % should already be mapped from
            % smExperimentViewer.findAOIsInReference
            obj.AOIs = [];
            boundingBox = makeBoundingBox(centroids, bbdiameter);
            newAOIs = [];
            for k = 1:size(centroids,1)
                if k == 1
                    newAOIs = AOI(centroids(k,:), [], boundingBox(k,:), []);
                else
                    newAOIs = [newAOIs; AOI(centroids(k,:), [], boundingBox(k,:), [])];
                end
                
            end
            obj.integrateAOIs();
        end
        
        function set.AOIs(obj, aois)
            obj.AOIs = aois;
        end
        
        function deleteAOIs(obj)
            obj.AOIs = [];
            obj.AOIsIntegrated = 0;
        end
        
        
        % -----------------------------------------------------------------
        % Out of Bound AOIs
        % -----------------------------------------------------------------
        function removeOutOfBoundAOIs(obj)
            % check if drift has been applied...
            xBound = ceil(obj.width + obj.driftList(:,2));
            yBound = ceil(obj.width + obj.driftList(:,1));
            keep = ones(obj.numberOfAOIs,1);
            for i = 1:obj.numberOfAOIs
                pixelList = obj.AOIs(i).pixelList;
                for k = 1:2
                    if k == 1
                        z = intersect(pixelList(:,k), xBound);
                    else
                        z = intersect(pixelList(:,k), yBound);
                    end
                    if ~isempty(z)
                        keep(i) = 0;
                    end
                end
            end
            obj.AOIs = obj.AOIs(find(keep==1));
        end
        
        
        % -----------------------------------------------------------------
        % Integrate across all frames within specific coordinates
        % -----------------------------------------------------------------
        function timeSeries = intergrateAOI(obj, coordinates)
            % coordindates are [x1, x2; y1, y2]
            timeSeries = [];
            if nargin > 1
                timeSeries = zeros(obj.numFrames, 1);
                pixelList = pixelIndextoList(coordinates(1,1), coordinates(1,2), coordinates(2,1), coordinates(2,2));
                
                % Faster if loaded locally
                if obj.DataLoadedToMemory
                    for i = 1:size(pixelList,1)
                        col = pixelList(i,1);
                        row = pixelList(i,2);
                        timeSeries = timeSeries + double(squeeze(obj.data(row,col,:)));
                    end
                else
                    for i = 1:obj.numFrames
                        frame = obj.getFrame(i);
                        x = 0;
                        for j = 1:size(pixelList,1)
                            col = pixelList(j,1);
                            row = pixelList(j,2);
                            x = x + double(squeeze(frame(row,col,:)));
                        end
                        timeSeries(i) = x;
                    end
                end
            end
        end
        
        % -----------------------------------------------------------------
        % Drift Correction (frame-wise)
        % -----------------------------------------------------------------
        function computeDriftCorrectionVideo(obj, prompt)
            if nargin < 2
                prompt = 1;
            end
            % UI dialouge to check number of frames
            answer = inputdlg( {'Check every X Frames'}, 'Drift Corr.',[1,35],{'10'});
            if ~isempty(answer)
                frameIdx = round(str2double(answer{1}));
                idx = unique([1:frameIdx:obj.numFrames, obj.numFrames])';
                nIdx = length(idx);
                driftListSample = zeros(nIdx, 2);
                wb1 = waitbar(0, 'Computing Transform');
                for i = 2:nIdx
                    [dx,dy] = fastreg(obj.getFrame(idx(i-1)), obj.getFrame(idx(i)));
                    driftListSample(i,1:2) = [dx, dy];
                    waitbar(i/nIdx, wb1);
                end
                driftListSample= cumsum(driftListSample);
                
                waitbar(1, wb1, 'Per Frame Drift Computation...')
                obj.driftList = zeros(obj.numFrames,2);
                h2 = figure('Name', 'Drift Correction Result', 'NumberTitle', 'off');
                for k = 1:2
                    z = filloutliers(driftListSample(:, k),'nearest','mean');
                    % obj.driftList(:,k) = pchip(idx(:,1), z, 1:obj.numFrames);
                    
                    zz = smooth(driftListSample(:, k), 'loess');
                    % extrapolate for each frame
                    for i = 1:nIdx-1
                        n1 = idx(i);
                        n2 = idx(i+1)-1;
                        obj.driftList(n1:n2,k) = linspace(zz(i),zz(i+1),n2-n1+1);
                    end
                    obj.driftList(end,k) = zz(end);
                    
                    subplot(1,2,k); hold on;
                    scatter(idx, z, 10, 'MarkerFaceColor', [0.8, 0.8, 0.8], 'MarkerEdgeColor', 'k');
                    plot(1:obj.numFrames,  obj.driftList(:,k), '-r', 'linewidth',1)
                    xlabel('Frame');
                    ylabel('Drift (pixels)');
                    if i == 1; title('X'); else; title('Y'); end
                end
                waitbar(1, wb1, 'Done.')
                close(wb1);
                
                % apply drift correction?
                if prompt
                    answer = questdlg('Apply Drift Correction', ...
                        'Drift Corr', ...
                        'Yes', 'No', 'No');
                    switch answer
                        case 'Yes'
                            close(h2);
                            obj.applyDriftCorrectionVideo
                            
                        case 'No'
                            close(h2);
                    end
                end
            else
                
                % say something mean
            end
            
            
        end
        
        function applyDriftCorrectionVideo(obj, driftList)
            % input optional to share across objects
            if ~exist('driftMatrix', 'var') || isempty(driftList)
                % assume from self
                driftList = obj.driftList;
            end
            
            % Apply
            if ~isempty(driftList) && ~obj.driftApplied
                wb2 = waitbar(0, ['Applying Drift Correction | ', obj.name]);
                for i = 1:obj.numFrames
                    obj.data(:,:,i) = immove(obj.data(:,:,i),driftList(i,1), driftList(i,2));
                    waitbar(i/obj.numFrames, wb2);
                end
                obj.driftApplied = true;
                close(wb2);
            else
                % Give error message
            end
            
        end
        
        function clearDriftCorrectionVideo(obj)
            obj.driftList = [];
            obj.driftApplied = false;
        end
        
        
        % Save ------------------------------------------------------------
        function save(obj, filePath)
            % not sure if this is behaving as intended yet
            if ~exist('filepath', 'var') || isempty(filePath)
                [file, path] = uiputfile('ImageStack.mat', 'Save obj to file');
                if isequal(file, 0)
                    return
                end
                x = obj;
                save([path,file], 'x');
                disp(['Saved: ', [path,file]]);
            end
        end
        
        % Write image stack to video --------------------------------------
        function makeVideo(obj, videoFrameRate_s, filePath)
        end
        
    end
    
    
    
    
end