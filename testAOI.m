%% test AOI class and AOIViewer
imageData = loadImageStackToClass([], 1)

%%
imageMu = mean(imageData{1}.data(:,:,1:5),3); 
X = imageData{1};
X.findAreasOfInterest();
X.integrateAOIs();

%% 
% AOIs(1).viewAOI(imageData{1}.time_s);


%% 
% close all 
% AOIs(101).viewAOI();

%%
close all 
y = AOIViewer(X);

%%
y.hidden