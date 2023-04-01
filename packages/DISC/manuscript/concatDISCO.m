function data = concatDISCO()
% -------------------------------------------------------------------------
% Combine DISCO.mat files into a single structure
% -------------------------------------------------------------------------
% Input:
%    N/A. prompts files to load
% 
% Output: 
%   combined "data" structure read by DISCO
% 
% Author: David S. White 
% Updated: 2021-10-07
% License: MIT
% -------------------------------------------------------------------------

% Assume they could be in different folders. 
[files, paths] = getMultipleFiles();
nFiles = length(files); 

% Load each file
tempData = cell(nFiles,1); 
disp('Files selected: ')
for i = 1:nFiles
    temp = load([paths{i}, files{i}]); 
    tempData{i} = temp.data; 
end

% Combine
data = struct; 
data.files = files; 
data.paths = paths; 
data.rois = []; 
for i =  1:nFiles
    data.rois = [data.rois; tempData{i}.rois];
end

% Save (need to debug this, giving weird file extensions)
[saveFile, savePath] = uiputfile('DISCO.mat');
save([savePath, saveFile], 'data','-v7.3')
