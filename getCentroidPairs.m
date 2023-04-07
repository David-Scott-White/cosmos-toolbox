function [centroids1, centroids2, pairs] = getCentroidPairs(centroids1, centroids2, maxDist)
% Return pairs of centroids within maxDist
% David S. White
% 2022-02-07

pairs = centroids1*0;
keep = ones(length(centroids1),1);
for i = 1:length(centroids1)
    dist = sqrt((centroids1(i,1) - centroids2(:,1)).^2 + (centroids1(i,2) - centroids2(:,2)).^2);
    [minDist, j] = min(dist);
    if minDist > maxDist
        keep(i) = 0;
    end
    if sum(pairs(:,2)==j)
        keep(i) = 0;
    else
        pairs(i,1) = i;
        pairs(i,2) = j;
    end
end
pairs = pairs(keep==1, :);

centroids1 = centroids1(pairs(:,1),:);
centroids2 = centroids2(pairs(:,2),:);
dist = sqrt((centroids1(:,1) - centroids2(:,1)).^2 + (centroids1(:,2) - centroids2(:,2)).^2);

% check for outleirs (e.g., no actually match with the centroid)
outlierPresent = 1;
while outlierPresent
    idx = find(isoutlier(dist)==1);
    if ~isempty(idx)
        centroids1(idx,:) = [];
        centroids2(idx,:) = [];
        pairs(idx,:) = [];
        dist = sqrt((centroids1(:,1) - centroids2(:,1)).^2 + (centroids1(:,2) - centroids2(:,2)).^2);
    else
        outlierPresent = 0;
    end
end

