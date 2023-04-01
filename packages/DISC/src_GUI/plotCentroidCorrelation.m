function plotCentroidCorrelation(data)
figure; 
% just do 2 channels for now... 
[numROIs, numChannels] = size(data.rois);
centroids = zeros(numROIs,2, numChannels); % x,y,channel
for i = 1:numChannels
    for j = 1:numROIs
        % centroids(j,1:2,i) = data.rois(j,i).image.centroid;
        centroids(j,1:2,i) = data.rois(j,i).Centroid;
    end
end
h = figure; 
subplot(1,2,1); 
title('X correlation'); 
scatter(centroids(:,1,1), centroids(:,1,2)); 
ylabel('Channel 2')
xlabel('Channel 1')

subplot(1,2,2); 
title('Y correlation'); 
scatter(centroids(:,2,2), centroids(:,2,2)); 
ylabel('Channel 2')
xlabel('Channel 1')

end