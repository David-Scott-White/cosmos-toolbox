function imageData = loadImageStack(filePath, loadImagesToMemory)
% -------------------------------------------------------------------------
% Gather information about an image stack for loading
%
% Input: 
%   filePath = str. [path, file, ext] of source to load
%   loadImagesToMemory = boolean. 
%
% Output: 
%   imageData = struct. 
%
% Notes on use: 
% > Intended for use in smtoolbox by DSW (e.g., smImage.m)
% > Current supports .tif, .ome.tif (recommended), and .glimpse
% > if loading .glimpse format, select or provide [path, header.glimpse]
%
% Requirements:
%   Image Processing Toolbox
%   bfmatlab
%
% Last updated: 
% > 2022-08-25 DSW dwhite7@wisc.edu
% 
% License: GNU General Public License v3.0
% Copyright (C) 2022 David S. White
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
% -------------------------------------------------------------------------
%
% Check inputs
if ~exist('filePath', 'var') || isempty(filePath); filePath = []; end
if ~exist('loadImagesToMemory', 'var') || isempty(loadImagesToMemory); loadImagesToMemory = 0; end

imageData = struct;
imageData.file = [];
imageData.path = [];
imageData.name = [];
imageData.width = [];
imageData.height = [];
imageData.frames = [];
imageData.numFrames = [];
imageData.exposure_s = [];
imageData.time_s = [];
imageData.info = [];
imageData.data = [];

if isempty(filePath)
    [file, path] = uigetfile('*');
    if ~file
        disp('>> WARNING from loadImageStackInformation: No File selected.');
        return
    else
        filePath = [path,file];
    end
end

% check file type.
[path,file,ext] = fileparts(filePath);
switch ext
    case '.tif'
        imageInfo = imfinfo(filePath);
        if ~strcmp(imageInfo(1).ColorType, 'grayscale')
            disp('>> ERROR in loadImageStackInformation: Only grayscale images supported');
            return
        end
        if contains(file, '.ome')
            % Extract metadata
            disp('>> NOTICE from loadImageStackInformation. Extracting info via: bioformat (bfmatlab)')
            
            % start timer
            tic
            
            % Call bfmatlab
            reader = bfGetReader(filePath);
            omeMeta = reader.getMetadataStore();
            
            % get general information (already in imageInfo but double
            % check)
            numChannels = omeMeta.getChannelCount(0);
            
            % loop through all channels. JAVA is zero index
            channelNames = cell(numChannels,1);
            for k = 1:numChannels
                channelNames{k} = convertCharsToStrings(char(omeMeta.getChannelName(0,k-1)));
                channelNames{k} = strrep(channelNames{k}, ' ', '');
                channelNames{k} = strrep(channelNames{k}, '_', '-');
            end
            
            % loop through all images to get more information 
            % (zero index in java)
            N = size(imageInfo,1);
            time_s = zeros(N,1);
            exposure_s = zeros(N,1);
            for i = 1:size(imageInfo,1)
                time_s(i,1) = double(omeMeta.getPlaneDeltaT(0,i-1).value) / 1000;
                exposure_s(i,1) = double(omeMeta.getPlaneExposureTime(0,i-1).value) / 1000;
            end
            %  NEED TO UPDATE FOR NON UNIFORM IMAGING OF CHANNELS
            disp('>> WARNING in loadImagStackInformation: Assume channels alternate each image');
            
            frameInfo = zeros(N,4);
            frameInfo(:,1) = 1:N;
            % possible video stoppped and numFrames are not uniform
            channelRemainder = rem(N, numChannels);
            if channelRemainder
                channelIdx = repmat([1:numChannels]', (N-channelRemainder)/numChannels, 1);
                channelIdx = [channelIdx; [1:channelRemainder]'];
            else
                channelIdx = repmat([1:numChannels]', N/numChannels, 1);
            end
            frameInfo(:,2) = channelIdx;
            frameInfo(:,3) = time_s;
            frameInfo(:,4) = exposure_s;
            
            % STORE metadata for .ome.tif 
            if numChannels > 1
                imageData = repmat(imageData, numChannels, 1);
            end
            
            for k = 1:numChannels
                imageData(k).file = [file, ext];
                imageData(k).path = path;
                imageData(k).name = channelNames{k};
                channelIndex = find(frameInfo(:,2)==k);
                imageData(k).frames = channelIndex;
                imageData(k).numFrames = length(channelIndex);
                imageData(k).exposure_s = frameInfo(channelIndex(), 4);
                imageData(k).time_s = frameInfo(channelIndex, 3);
                imageData(k).info = imageInfo(channelIndex, :);
                imageData(k).width = imageData(k).info(1).Width;
                imageData(k).height = imageData(k).info(1).Height;
                
                if loadImagesToMemory
                    fprintf('>> Loading channel %d %dx%dx%d @ %s...\n', k, imageData(k).width, imageData(k).height, imageData(k).numFrames, file)
                    imageData(k).data = zeros(imageData(k).width, imageData(k).height, imageData(k).numFrames);
                    for n = 1:imageData(k).numFrames
                        imageData(k).data(:,:,n) = imread(imageData(k).info(n).Filename, 'Info', imageData(k).info);
                    end
                end
            end
            time1 = toc;
            disp(['>> Image Processing Time: ', num2str(time1)])
            
        else
            
            % PROCESS regular .tif (no information, need to manually enter)
            imageData.file = [file, ext];
            imageData.path = path;
            imageData.name = '';
            imageData.frames = 1:length(imageInfo); 
            imageData.frames = imageData.frames(:);
            imageData.numFrames = length(imageInfo);
            imageData.exposure_s = [];
            imageData.time_s = [];
            imageData.info = imageInfo;
            imageData.width = imageInfo(1).Width;
            imageData.height = imageInfo(1).Height;
            
        end
        
    case '.glimpse'
        % check that the header file was selected, and not a number file 
        if ~strcmp(file, 'header')
            if isfile([path,'/header.glimpse'])
                file = 'header'; 
            else
                disp('ERROR in loadImageStackInformation: header.glimpse not found');
                return
            end
        end
        disp('>> WARNING from loadImageStackInformation: GLIMPSE format must load all images to memory.')
        foldstruc.gfolder = [path, '/'];
        loadedGlimpseFile = load([path,'/header.mat']);
        vid = loadedGlimpseFile.vid;
        
        if vid.nframes > 6500
            disp('WARNING from loadImageStackInformation: Max Frames exceeds. Cut off at 6500 [fix in later version]');
            numFrames = 6500;
        else
            numFrames = vid.nframes;
        end
        
        % --- Process the glimpse file
        images = zeros(vid.width,vid.height, numFrames);
        time_s = zeros(numFrames, 3);
        for i = 1:numFrames
            fid=fopen([foldstruc.gfolder, num2str(vid.filenumber(i)),'.glimpse'],'r','b');
            fseek(fid,vid.offset(i),'bof');
            pc=fread(fid,[vid.width,vid.height],'int16=>int16');
            images(:,:,i) = uint16(pc+32768);  % <- int16 to unint16
            fclose(fid);
        end
        fclose('all');
        time_s(:,1) = 1:numFrames;
        time_s(:,2) = vid.ttb(1:numFrames)';
        time_s(:,3) = (time_s(:,2) - time_s(1,2))/ 1e3; % ms to seconds
        
        % store in imageData
        imageData.file = [file, ext];
        imageData.path = path;
        imageData.name = convertCharsToStrings(vid.description);
        imageData.frames = 1:numFrames;
        imageData.frames = imageData.frames(:);
        imageData.numFrames = numFrames;
        imageData.exposure_s = [];
        imageData.time_s = time_s(:,3);
        imageData.info = [];
        imageData.width = vid.width;
        imageData.height = vid.height;
        imageData.data = images; 
        
    otherwise
        disp(['ERROR in loadImageStackInformation: Filetype selected not supported. ', ext]);
end
end

