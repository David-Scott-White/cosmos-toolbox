function [tform, image3, refObj1, refObj2] = alignImages(image1, image2, showPlot)
% Align image2 to image1 using Image Processing Toolbox
%
%

% Input

% ouput

% David S. White
% 2022-02-07
% -------------------------------------------------------------------------

refObj1 = imref2d(size(image1));
if size(image1,3) == size(image2, 3)
    refObj2 = refObj1;
else
    refObj2 = imref2d(size(image2));
end
method = 'zscore';
image1s = im2single(scaleFeature(image1, method));
image2s = im2single(scaleFeature(image2, method));

tform = imregcorr(image2s,refObj2,image1s,refObj1,...
    'transformType', 'similarity', 'Window',false); 
image3 = imwarp(image2, refObj2, tform, 'OutputView', refObj1, 'SmoothEdges', true);

if showPlot
    figure('Name', 'Image Alignment')
    
    subplot(1,2,1)
    imshowpair(imadjust(mat2gray(image1s)), imadjust(mat2gray(image2s)),'Scaling', 'independent');
    title('Original')
    
    subplot(1,2,2);
    image3s = im2single(scaleFeature(image3, method));
    imshowpair(imadjust(mat2gray(image1s)), imadjust(mat2gray(image3s)),'Scaling', 'independent');
    title('Aligned')
    
end