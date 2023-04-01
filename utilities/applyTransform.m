function centroids2 = applyTransform(centroids1, transformParameters)
% -------------------------------------------------------------------------
% Apply transform to centroid locations
% -------------------------------------------------------------------------
%
%
%
%
%
% -------------------------------------------------------------------------

% option to switch direct of transformation?
centroids2 = centroids1;

switch class(transformParameters)
    case 'images.geotrans.LocalWeightedMeanTransformation2D'
        centroids2 =  transformPointsInverse(transformParameters, centroids1); 
        
    case 'struct'
        if isfield(transformParameters, 'tform')
            [centroids2(:,1), centroids2(:,2)]= transformPointsInverse(transformParameters.tform,...
                centroids1(:,1),centroids1(:,2));
        end
        
        if isfield(transformParameters, 'X')
            centroids2(:,1) = centroids2(:,1)...
                + (centroids2(:,1)*transformParameters.X(2))+transformParameters.X(1);
        end
        
        if isfield(transformParameters, 'Y')
            centroids2(:,2) = centroids2(:,2)...
                + (centroids2(:,2)*transformParameters.Y(2))+transformParameters.Y(1);
        end
        
end
end