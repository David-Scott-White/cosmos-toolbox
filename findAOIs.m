function AOIs = findAOIs(image, varargin)
% -------------------------------------------------------------------------
% Find Areas Of Interest (AOIs)
% -------------------------------------------------------------------------



% -------------------------------------------------------------------------

% Check inputs & set defaults
radius = 2; 
boundingBoxDiamater = radius*2; 
gaussTol = 1e-5; 
falsePositive = 20; 
minDist = 5; 
for i = 1:2:length(varargin)-1
      switch varargin{i}
          case {'r', 'radius'}
              radius = varargin{i+1};
              if radius < 2
                  radius = 2; 
              end
          case {'tol', 'gaussianTolerance'}
              gaussTol = varargin{i+1};
              if gaussTol < 0
                  gaussTol = 0;
              end
          case {'fp', 'falsePositive'}
              falsePositive = varargin{i+1};
              if falsePositive < 0
                  falsePositive = 0;
              end
          case {'dist', 'minDist', 'spacing'}
              minDist = varargin{i+1};
              if minDist < 0
                  minDist = 0;
              end
          case {'bb', 'boundingBox', 'boundingBoxDiameter'}
              boundingBoxDiamater = varargin{i+1};
              if boundingBoxDiamater < radius
                  boundingBoxDiamater = radius;
              end
      end
end
% Make sure image is double 
image = double(image);

% Find AOIs in the Image --------------------------------------------------
BW = GLRTfiltering(image,radius+1, radius, falsePositive);
BW = bwareaopen(BW, radius, 8);
BW = bwareafilt(BW, [2, radius*5]);

% Generate structure using regionprops ------------------------------------
temp = regionprops(BW, image, 'WeightedCentroid');
centroids = cat(1, temp.WeightedCentroid);
numAOIs = size(centroids,1); 
disp(['>> AOIs found: ', num2str(numAOIs)]);

% Remove overlapping AOIs based on minDist --------------------------------
removeSpot = zeros(numAOIs,1);
for i = 1:numAOIs
    % Euclidean distance between AOIs
    dist = sqrt((centroids(i,1) - centroids(:,1)).^2 + (centroids(i,2) - centroids(:,2)).^2);
    % just call function?
    removeIndex = find(dist < minDist);
    if length(removeIndex) > 1
        removeSpot(i) = 1;
    end
end
spotsRemoved = sum(removeSpot);
centroids(removeSpot==1,:) = [];
numAOIs = length(centroids);
disp(['>> AOIs removed: ', num2str(spotsRemoved), newline, ...
    '>> Total AOIs: ', num2str(numAOIs)]);

% Make Bound Boxes for the AOIs --------------------------------------------
boundingBox = makeBoundingBox(centroids, boundingBoxDiamater);

% Fit each AOI to 2D Gaussian ---------------------------------------------
removeSpot = zeros(numAOIs,1);
gaussSigma = nan(numAOIs,2);
imageMask = [];
if gaussTol > 0
    wbGauss = waitbar(0, ['2D Gaussian Refinement | ', num2str(numAOIs), ' AOIs']);
    imageMask = cell(numAOIs,1); 
    for i = 1:numAOIs
        if gaussTol > 0
            aoiCenter = centroids(i,:) - boundingBox(i, 1:2)+1;
            imageMask{i} = imcrop(image, boundingBox(i,:));
            
            % guess parameters; X, Y, sigma, sigma, etc...
            gaussFit0 = [aoiCenter(1), aoiCenter(2), radius-1, radius-1, imageMask{i}(round(aoiCenter(1)), round(aoiCenter(2))), 0];
            gaussFit = fitgaussian2d(imageMask{i}, gaussFit0, 2, gaussTol);
            
            % make sure the fit is resonable (e.g, center in bounding box)
            dist = calculateEuclideanDistance(aoiCenter, gaussFit(1:2));
            if dist <= radius
                centroids(i,1)= gaussFit(1) + boundingBox(i,1)-1;
                centroids(i,2)= gaussFit(2) + boundingBox(i,2)-1;
                boundingBox(i,:) = makeBoundingBox(centroids(i,:), boundingBoxDiamater);
                gaussSigma(i,:) = gaussFit(3:4);
            else
                removeSpot(i) = 1;
            end
            waitbar(i/numAOIs, wbGauss);
        end
    end
    centroids(removeSpot==1,:) = [];
    boundingBox(removeSpot==1,:) = [];
    gaussSigma(removeSpot==1,:) = [];
    imageMask(removeSpot==1,:) = [];
    numAOIs = size(centroids,1);
    close(wbGauss);
end

% Collect Additional Info on the AOIs for filtering -----------------------
for i = 1:numAOIs
    if isempty(imageMask)
        im = imcrop(image, boundingBox(i,:));
    else
        im = imageMask{i};
    end
    if i == 1
        AOIs = AOI(centroids(i,:), gaussSigma(i,1), boundingBox(i,:), im);
    else
        AOIs = [AOIs; AOI(centroids(i,:), gaussSigma(i,1), boundingBox(i,:), im)];
    end
end

end
