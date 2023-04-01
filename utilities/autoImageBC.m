function [x1, x2] = autoImageBC(Image, showImage)
% Auto-adjust Image Range -------------------------------------------------
% Auto determination of brightness/ constrant for display of an image.
% Adapted from emperical results with ImageJ
%
% David S. White 
% 2021-09-19 
% -------------------------------------------------------------------------
if nargin < 2
    showImage = 0;
end
image = Image(:);
image(image==0) = []; 
[mu, sigma]= normfit(image);
x1 = mu-2*sigma; 
x2 = mu+4*sigma;
if x1<0
    x1 = 0;
end
if showImage
    figure;
    imshow(Image, 'DisplayRange', [x1,x2]);
end


