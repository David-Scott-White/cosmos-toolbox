function imageData = loadImageStackToClass(filePath, loadImagesToMemory)
% -------------------------------------------------------------------------
% Gather information about an image stack for loading
%
% Input:
%   filePath = str. [path, file, ext] of source to load
%   loadImagesToMemory = boolean.
%
% Output:
%   imageData = class.
%
% Notes on use:
% > Intended for use in smtoolbox by DSW
% > Currently supports .tif, .ome.tif (recommended), and .glimpse
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

imageData = {};

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
        N = size(imageInfo,1);
        if ~strcmp(imageInfo(1).ColorType, 'grayscale')
            disp('>> ERROR in loadImageStackInformation: Only grayscale images supported');
            return
        end
        if contains(file, '.ome')
            disp('>> Extracting metadata...')
            tic
            % Extract metadata (sort of ad hoc but works from MicroManager
            % Images) 
            fieldInfo = readImageInfoUnknownTags(imageInfo, 'ChannelIndex', 'Exposure-ms', 'ElapsedTime-ms'); 
            
            % 0 to 1 index
            fieldInfo(:,1) = fieldInfo(:,1)+1;
            
            % adjust time to s from ms
            fieldInfo(:,2) = fieldInfo(:,2)/1000;
            fieldInfo(:,3) = fieldInfo(:,3)/1000;
            
            % Get channel names
            reader = bfGetReader(filePath);
            omeMeta = reader.getMetadataStore();
            numChannels = omeMeta.getChannelCount(0);
            % loop through all channels. JAVA is zero index
            channelNames = cell(numChannels,1);
            for k = 1:numChannels
                channelNames{k} = convertCharsToStrings(char(omeMeta.getChannelName(0,k-1)));
                channelNames{k} = strrep(channelNames{k}, ' ', '');
                channelNames{k} = strrep(channelNames{k}, '_', '-');
            end
            
            % this could be much smarter, partion by structure? 
            
            frameInfo = zeros(N,4);
            frameInfo(:,1) = 1:N;
            frameInfo(:,2) = fieldInfo(:,1);
            frameInfo(:,3) = fieldInfo(:,3);
            frameInfo(:,4) = fieldInfo(:,2);
            
            % STORE metadata for .ome.tif
            imageData = cell(numChannels, 1);
            
            for k = 1:numChannels
                img = ImageStack();
                if loadImagesToMemory
                    img.loadDataToMemory = 1;
                end
                channelIndex = find(frameInfo(:,2)==k);
                
                img.filePath = filePath; 
                img.fileInfo = imageInfo(channelIndex,:);
                img.type = '.ome.tif'; 
                img.fileFrameIndex = channelIndex;
                img.fileChannelIndex = 1;
                img.name = channelNames{k};
                img.time_s = frameInfo(channelIndex, 3);
                img.exposure_s = frameInfo(channelIndex(1), 4);
                
                if loadImagesToMemory
                    fprintf('>> Loading channel %d %dx%dx%d @ %s...\n', k, img.width, img.height, img.numFrames, file)
                    img.data = zeros(img.width, img.height, img.numFrames);
                    for n = 1:img.numFrames
                        img.data(:,:,n) = imread(img.fileInfo(n).Filename, 'Info', img.fileInfo(n));
                    end
                end
                % store as cell for output
                imageData{k} = img;
            end
            time1 = toc;
            disp(['>> Image Processing Time: ', num2str(time1)])
            
        else
            % PROCESS regular .tif (no information, need to manually enter)
            img = ImageStack; 
            img.filePath = filePath; 
            img.fileInfo = imageInfo;
            img.type = '.tif';
            img.fileFrameIndex = [1:img.numFrames]';
            img.fileChannelIndex = 1;
            img.name = '';
            img.time_s = [];
            img.exposure_s = imageInfo(1, 4);
               
            % load to memory?
            if loadImagesToMemory
                fprintf('>> Loading channel %d %dx%dx%d @ %s...\n', 1, img.width, img.height, img.numFrames, file)
                img.data = zeros(img.width, img.height, img.numFrames);
                for n = 1:img.numFrames
                    img.data(:,:,n) = imread(img.fileInfo(n).Filename, 'Info', img.fileInfo(n));
                end
            end
            % store as cell for output
            imageData{1} = img;
            
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
        
        % store in imageDataClass
        img = ImageStack();
        img.filePath = filePath;
        img.fileInfo = [];
        img.type = '.glimpse';
        img.fileFrameIndex = time_s(:,1);
        img.fileChannelIndex = 1;
        img.name = convertCharsToStrings(vid.description);
        img.time_s = time_s(:,3);
        img.exposure_s = [];
        img.data = images;
        img.loadDataToMemory = true;  
        
        imageData{1} = img;

    otherwise
        disp(['ERROR in loadImageStackInformation: Filetype selected not supported. ', ext]);
end
end

