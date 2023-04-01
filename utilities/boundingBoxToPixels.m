function pixelList = boundingBoxToPixels(boundingBox)
% -------------------------------------------------------------------------
% Get pixels in the space of the bounding box 
% 
% Input
%   boundingBox = [N,4] of [left, top, width height] 
% 
% Output
%   pixelList = [N,2] of x,y
%
%
% David S. White 
% 2022-01-25
% License MIT
% -------------------------------------------------------------------------
% Bounding box notation: left top width height
pixelList = zeros(boundingBox(3)*boundingBox(4),2);
xx = boundingBox(1);
ii = 1;
for i = 1:boundingBox(3)
    yy = boundingBox(2);
    for j = 1:boundingBox(4)
        pixelList(ii,:) = [xx, yy];
        yy = yy+1;
        ii = ii +1;
    end
    xx = xx+1;
end
