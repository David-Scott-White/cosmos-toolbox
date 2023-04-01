function aois = findAreasOfInterest(image, parms, showResult)
% -------------------------------------------------------------------------
% Find Areas of Interst (aois) in image. Variety of options
% -------------------------------------------------------------------------
% 
%
%
% Requires MATLAB Image Processing Toolbox
%
% David S. White 
% 2022-04-20 
% License: GPL GNU v3
% -------------------------------------------------------------------------

% check for input (rewrite to be consistent with smVideoProcessing)
% Default settings that work well for DSW on 60X objective w/ 512 x 512 sCMOS.  
if nargin < 2
    parms = struct; 
    parms.method = 'GLRT'; 
    parms.radius = 2; 
    parms.falsePositive = 20; 
    parms.gaussBool = 0; 
    parms.gaussTol = 1e-5; 
    showResult = 0; 
end

if nargin < 3 || isempty(showResult)
    showResult = 0;
end

if parms.radius < 2
    parms.radius = 2; 
    disp('>> findAreasOfInterest: AOI radius increased to 2 pixels ');
end

% assert image type 
image = double(image);

switch parms.method
    case {'GLLRT', 'GLRT'}
        BW = GLRTfiltering (image, parms.radius+1, parms.radius, parms.falsePositive);
        BW = bwareaopen(BW, parms.radius, 8);
        BW = bwareafilt(BW, [2, parms.radius*5]);
        
    case 'Otsu'
        % would not use for now, removing all spots except beads - DSW, 2022-04-25
        se = strel('disk', parms.radius);
        image_denoised = imtophat(mat2gray(image), se);
        BW = imbinarize(image_denoised,'global');
        BW = bwareaopen(BW, parms.radius, 8);
        BW = bwareafilt(BW, [parms.radius, parms.radius*5]);
end

% since renaming values in fields is oddly difficult...
temp = regionprops(BW, image, 'WeightedCentroid');
centroids = cat(1, temp.WeightedCentroid);

numAOIs = size(centroids,1); 
disp(['>> aois found: ', num2str(numAOIs)]);

% Remove overlapping aois (as defined by aoi radius). 
minDist = parms.radius*2+1;
removeSpot = zeros(numAOIs,1); 
for i = 1:numAOIs
    dist = sqrt((centroids(i,1) - centroids(:,1)).^2 + (centroids(i,2) - centroids(:,2)).^2);
    removeIndex = find(dist < minDist);
    if length(removeIndex) > 1
        removeSpot(i) = 1;
    end
end
spotsRemoved = sum(removeSpot); 
centroids(removeSpot==1,:) = []; 
numAOIs = length(centroids); 
disp(['>> aois removed: ', num2str(spotsRemoved)]);

% make a bounding box for the aois
boundingBox = makeBoundingBox(centroids, parms.radius*2);

% Gaussian fit the aois ---------------------------------------------------
gaussSigma = nan(numAOIs,2); 
if parms.gaussBool
    aoiDiameter = parms.radius*2;
    removeSpot = zeros(numAOIs,1); 
    wbGauss = waitbar(0, ['Gaussian Refinement | ', num2str(numAOIs), ' AOIs']);
    for i = 1:numAOIs
        aoiCenter = centroids(i,:) - boundingBox(i, 1:2) +1;
        imageTemp = imcrop(image, boundingBox(i,:));
        
        % guess parameters; X, Y, sigma, sigma, etc...
         gaussFit0 = [aoiCenter(1), aoiCenter(2), parms.radius-1, parms.radius-1, imageTemp(round(aoiCenter(1)), round(aoiCenter(2))), 0];
         gaussFit = fitgaussian2d(imageTemp, gaussFit0, 2, parms.gaussTol);
         
         % make sure the fit is resonable (e.g, center in bounding box)
         dist = calculateEuclideanDistance(aoiCenter, gaussFit(1:2));
         if dist <= parms.radius
             centroids(i,1)= gaussFit(1) + boundingBox(i,1)-1;
             centroids(i,2)= gaussFit(2) + boundingBox(i,2)-1;
             boundingBox(i,:) = makeBoundingBox(centroids(i,:), aoiDiameter);
             gaussSigma(i,:) = gaussFit(3:4);
         else
             removeSpot(i) = 1; 
         end
         waitbar(i/numAOIs, wbGauss); 
    end
    centroids(removeSpot==1,:) = [];
    boundingBox(removeSpot==1,:) = [];
    gaussSigma(removeSpot==1,:) = [];
    numAOIs = size(centroids,1);
    close(wbGauss);
end

% store final information in AOI struct (centroidss already stored) -------
aois = struct;
for i = 1:numAOIs
    aois(i,1).centroid = centroids(i,:);
    aois(i,1).gaussSigma = gaussSigma(i,1);
    aois(i,1).boundingBox = boundingBox(i,:);
    aois(i,1).pixelList = boundingBoxToPixels(boundingBox(i,:));
    
    % store common features for filtering (just average intensity for now)
    aois(i,1).avgMaskIntensity = 0; 
    aois(i,1).maxMaskIntensity = 0; 
    aois(i,1).sumMaskIntensity = 0; 
    nPixels = size(aois(i,1).pixelList, 1); 
    tmp = zeros(nPixels,1); 
    for j = 1:nPixels
        tmp(i) = image(aois(i,1).pixelList(j,2), aois(i,1).pixelList(j,1));  % X and Y values are inverted.
    end
    aois(i,1).sumMaskIntensity = sum(tmp);
    aois(i,1).maxMaskIntensity = max(tmp);
    aois(i,1).avgMaskIntensity =  aois(i,1).sumMaskIntensity / nPixels; 
end

% display found aois on image? --------------------------------------------
if showResult
    autoImageBC(image, 1); hold on
    for i = 1:numAOIs
        rectangle('Position', aois(i).boundingBox(1,:),...
            'EdgeColor','r', 'LineWidth', 1, 'Curvature', [0 0]);
    end
end

end






