function [tform, centroidPairs, rmse, rois1, rois2] = alignAOI(image1, image2, aoi, maxDist, showPlot)
% -------------------------------------------------------------------------
% Find and align centroids from image2 to image1 using an affine transform
% 
% Requires: Image Processing Toolbox
% 
% Input: 
%   image1 = [x,y,1] image
%   image2 = [x,y,1] image
%   aoi = struct. Parameters for finding an aoi in findAOI.m 
%   maxDist = double. Max distance between spots to be considered 
%   showPlot. Boolean. Show calibration of points
%
% Output
%   tform = output from fitgeotrans
%   centroidPairs. 2x1 cell. List of centroids (x,y) found in each image. 
%   rmse = root mean square error between the centroids in x and y 
% 
%   (temporary, will be removed in future update) 
%   rois1 = centroidPairs{1} converted to rois
%   rois2 = centroidPairs{2} converted to rois
% 
% Author: David S. White 
% Date: 2022-02-07
% License: MIT
% -------------------------------------------------------------------------

if nargin < 4
    maxDist = 1; 
    showPlot = 1; 
end
if nargin < 5
    showPlot = 1;
end

%% find Centroids in each image seperately
rois1 = findAOI(image1, aoi, 0);
rois2 = findAOI(image2, aoi, 0);
centroids1 = vertcat(rois1.Centroid);
centroids2 = vertcat(rois2.Centroid);

% get pairs
[centroids1, centroids2, pairIdx] = getCentroidPairs(centroids1, centroids2, maxDist); 

rois1 = rois1(pairIdx(:,1)); 
rois2 = rois2(pairIdx(:,2));

%% Align the centroids 
nCentroids = length(centroids1); 
disp(['Number of Centroid Pairs:', num2str(nCentroids)]);

% lwm seems to fit better but does worse job with new data... 
% tform = fitgeotrans(centroids2, centroids1, 'lwm', 6);
tform = fitgeotrans(centroids2, centroids1, 'affine');
centroids3 = transformPointsInverse(tform, centroids1);

rmse = sqrt(sum((centroids3-centroids2).^2)./nCentroids);
disp(['RMSE (x, y): ', num2str(rmse)]);
centroidPairs = cell(2,1);

centroidPairs{1} = centroids1; 
centroidPairs{2} = centroids2;

% disp(['Error (nm): ', num2str(rmse2*260)]); % have an info output when
% building experiments/set ups is an option in the full software

if showPlot
    figure('Name', 'AOI Alignment')
    subplot(2,2,1);
    nx = size(image1,1);
    plot(1:nx, 1:nx, '-r', 'linewidth',1); hold on
    scatter(centroids1(:,1), centroids3(:,1), 10, 'MarkerEdgeColor', [0, 0.4470, 0.7410]);
    title('X Position')
    xlabel('Channel 1 (X, pixels)')
    ylabel('Channel 2 (X, pixels)')
    xlim([1,nx])
    ylim([1,nx])
    
    subplot(2,2,2);
    ny = size(image1,2);
    plot(1:ny, 1:ny, '-r', 'linewidth',1); hold on
    scatter(centroids1(:,2), centroids3(:,2), 10, 'MarkerEdgeColor', [0, 0.4470, 0.7410]);
    xlim([1,ny])
    ylim([1,ny])
    title('Y Position')
    xlabel('Channel 1 (Y, pixels)')
    ylabel('Channel 2 (Y, pixels)')
    
    subplot(2,2,3); 
    scatter(centroids1(:,1), centroids2(:,1)-centroids3(:,1))
    title('X Error')
    xlabel('X Position')
    ylabel('Error (pixels)')
    
    subplot(2,2,4); 
    scatter(centroids1(:,2), centroids2(:,2)-centroids3(:,2))
    title('Y Error')
    xlabel('Y Position')
    ylabel('Error (pixels)')
    
end