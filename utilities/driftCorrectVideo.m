function [newVideo, allTForm] = driftCorrectVideo(video, allTForm, frameIdx)
%% Apply computed drift correction to the raw video images ----------------
%
% input
%   video = [x, y, z] stack
%   frameIdx = spacing between frames for correction
%
% output
%   newVideo = [x, y, z] stack of corrected video
%
% Author: David S. White
% Date: 2022-01-32
% License: MIT
% -------------------------------------------------------------------------
if ~exist('allTForm', 'var') || isempty(allTForm)
    computeTform = 1;
else
    computeTform = 0;
end

if ~exist('frameIdx', 'var') || isempty(frameIdx)
    frameIdx = 1;
end

[x,y,nFrames] = size(video);
nFramesTemp = nFrames;
while rem(nFramesTemp, frameIdx)
    nFramesTemp = nFramesTemp-1;
end
vidIndex = [1:frameIdx:nFramesTemp; frameIdx:frameIdx:nFramesTemp];
vidIndex = vidIndex';
vidIndex(end,2) = nFrames;
nIdx = length(vidIndex);

newVideo = video*0;
newVideo(:,:,vidIndex(1,1): vidIndex(1,2)) = video(:,:, vidIndex(1,1): vidIndex(1,2));

refObj = imref2d(size(video(:,:,1)));
if computeTform
    
    scaleMethod = 'zscore';
    image1 = im2single(scaleFeature(video(:,:,1),scaleMethod));
    allTForm = cell(nIdx,1); % can break code if lengths are not same
    driftList = zeros(nIdx, 2);
    
    wb1 = waitbar(0, 'Computing Transform');
    for i = 2:nIdx
        lastwarn('');
        ii = vidIndex(i,1);
        image2 = im2single(scaleFeature(video(:,:,ii), scaleMethod));
        allTForm{i} = imregcorr(image2, refObj, image1, refObj, 'transformType', 'similarity', 'Window', false);
        msg = lastwarn;
        if ~isempty(msg)
            % Correction for most common error: Warning: Phase correlation did not result in a strong peak. Resulting registration could be poor.
            allTForm{i} = allTForm{i-1};
        end
        
        % common error check.
        if i > 2
            if abs(allTForm{i}.T(3,1)) >= abs(x/2) || abs(allTForm{i}.T(3,2)) >= abs(y/2)
                allTForm{i} = allTForm{i-1};
            end
        end
        
        driftList(i,1:2) = allTForm{i}.T(3,1:2); % xshift, yshift
        waitbar(i/nIdx, wb1);
    end
    
    % check for outliers
    figure;
    xx = 1:nIdx;
    driftList2 = driftList; 
    for k = 1:2
        z = filloutliers(driftList(:, k),'nearest','mean');
        zz = smooth(xx, z, 0.2, 'rloess');
        % zz = smooth(xx, z, frameIdx, 'rloess');
        %p = pchip(xx, z);
        %zz = ppval(p, xx);
        
        driftList2(:,k) = zz;
        driftList2(1,k) = 0; 
        
        subplot(1,2,k); hold on; 
        scatter(xx, z, 10, 'MarkerFaceColor', [0.8, 0.8, 0.8], 'MarkerEdgeColor', 'k');
        plot(xx, zz,'-r', 'linewidth',1)
    end
    for i = 1:nIdx
        allTForm{i}.T(3,1:2) = driftList2(i,:);
    end
    close(wb1)
end

% apply the drift correction
wb2 = waitbar(0, 'Applying Transform');
for i = 1:nIdx
    for j = vidIndex(i,1): vidIndex(i,2)
        if i > 1
            
        newVideo(:,:,j) = imwarp(video(:,:,j), refObj, allTForm{i}, 'OutputView', refObj, 'SmoothEdges', false);
        else
             newVideo(:,:,j) = video(:,:,j);
        end
    end
    waitbar(i/nIdx, wb2);
end
close(wb2)

end


