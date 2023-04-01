function AOIs = integrateAOIs(AOIs, imageStack)
% -------------------------------------------------------------------------
% Integrate AOIs
% -------------------------------------------------------------------------

% input is AOIs as class AOI
% imageStack = [N,M,K]

numAOIs = numel(AOIs);
numFrames = size(imageStack,3);
modArea = 2; % if [3,3], 1 makes 5x5. 2 makes 7x7  % Make variable input
removeIdx = zeros(numFrames,1); 

% store cropped image gallery
wb = waitbar(0, sprintf('Integrating %d AOIs...', numAOIs));
for i = 1:numAOIs
    % integate fluorescence intensity 
    numPixels = size(AOIs(i).pixelList,1);
    AOIs(i).timeSeries = zeros(numFrames,1);
    for k = 1:numPixels
        col = AOIs(i).pixelList(k,1);
        row = AOIs(i).pixelList(k,2);
        AOIs(i).timeSeries = AOIs(i).timeSeries + double(squeeze(imageStack(row,col,:)));
    end
    
    % store cropped image gallery
    bb = AOIs(i).boundingBox;
    bb(1) = bb(1)-modArea;
    bb(2) = bb(2)-modArea;
    bb(3:4) = bb(3:4)+modArea*2;
    pixelList = boundingBoxToPixels(bb); % need var option to control for area size
    nPixelList = size(pixelList,1)^0.5;
    pixelValues = zeros(length(pixelList), numFrames);
    if sum(sum(pixelList<=0)) || sum(sum(pixelList> 512))
        removeIdx(i) = 1;
    else
        for c = 1:length(pixelList)
            pixelValues(c,:) = imageStack(pixelList(c,2), pixelList(c,1), :);
        end
        AOIs(i).gallery = reshape(pixelValues,[nPixelList, nPixelList, numFrames]);
    end
    
    % Time_s (from input of clas ImageStack)
    % AOIs(i).time_s = time_s; 
    
    % update waitbar
    waitbar(i/numAOIs, wb);
end
AOIs(removeIdx==1) = []; 
close(wb)

end