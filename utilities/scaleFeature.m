function xScaled = scaleFeature(X, method)
% David S. White 
% 2021-10-02

% X  = matrix
% method = options below. 

minX = min(X(:));
maxX = max(X(:));
[muX, sdX] = normfit(X(:));

switch method
    case 'minmax'
        xScaled = (X-minX)./(maxX-minX);
        
    case 'mean'
        xScaled = (X-muX)./(maxX-minX);
        
    case 'zscore'
        xScaled = (X-muX)./sdX;
        
end