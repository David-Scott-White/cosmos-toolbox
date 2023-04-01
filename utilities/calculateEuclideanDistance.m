function dist = calculateEuclideanDistance(centroid0, centroid1)
% Euclidean distance between two centroids. 
% Each centroid is [x,y] position; 

% David S. White 
% 2021-10-02
% MIT
% -------------------------------------------------------------------------
dist = sqrt((centroid0(:,1) - centroid1(:,1)).^2 + (centroid0(:,2) - centroid1(:,2)).^2);