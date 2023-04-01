function plotSpot(data, indices)
if isfield(data.rois(indices(1), indices(2)), 'spot')
    spots = data.rois(indices(1), indices(2)).spot;
    % spots = data.rois(indices(1), indices(2)).spotInt;
    [x,y, nSpots] = size(spots);
    
    
    width = 100;
    nSpotsTemp = nSpots;
    while rem(nSpotsTemp,width)
        nSpotsTemp = nSpotsTemp+1;
    end
    % nBuffer = nSpotsTemp - nSpots;
    % spotsTemp = cat(3, spots, zeros(x,y,nBuffer));
    
    [mu, sigma] = normfit(spots(:));
    %xx = vertcat(data.rois(:,indices(2)).spot);
    %xx = xx(:);
    %[mu,sigma] = normfit(xx);
    
    figExist = findobj('type','figure','name','spot');
    if ~isempty(figExist)
        close('spot');
    end
    figure('Name', 'spot')
    
    mag = 5;
    out = imtile(spots, 'GridSize',[nSpotsTemp/width width], 'thumbnailSize', [x*mag, y*mag]);
    imshow(out,  'DisplayRange', [mu-sigma, mu+5*sigma]);
    
    
    if ~isempty(data.rois(indices(1), indices(2)).disc_fit)
        hold on
        arrayMap = reshape(1:nSpotsTemp, [width, round(nSpotsTemp)/width ]);
        arrayMap = arrayMap';
        ss = data.rois(indices(1), indices(2)).disc_fit.ideal;
        boundIdx = find(ss>min(ss));
        nX = zeros(length(boundIdx),2);
        for i = 1:length(boundIdx)
            j = boundIdx(i);
            [jy, jx] = find(arrayMap==j);
            nX(i,1) = jx;
            nX(i,2) = jy;
        end
        for i = 1:length(boundIdx)
            rectangle('Position', [nX(i,1)*x*mag-x*mag, nX(i,2)*y*mag-y*mag, (x)*mag, (y)*mag], 'EdgeColor', 'r'); hold on
        end
    end
end
end