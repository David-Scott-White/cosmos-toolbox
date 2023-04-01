function roi = modifyEventsByCentroid(roi, maxdist, showPlot)
 
% maxdist = 0.95; % NEED TO CODE INTO GUI
if showPlot
    maxdist
end

class = roi.disc_fit.class;
events = findEvents(roi.disc_fit.class);
nEvents = size(events,1);
dist = zeros(nEvents,1);
removedEvents = 0;
if showPlot
    k = findobj('type','figure','name','DetectedEvents');
    if ~isempty(k)
        close(k);
    end
    figure('Name', 'DetectedEvents');
end
nBound = sum(events(:,4)>1);
kk = ceil(nBound/5); 

p = 0; 
for i = 1:nEvents
    if events(i,4) > 1
        p = p +1;
        s1 = events(i,1);
        s2 = events(i,2);
        centroid0 = roi.Centroid(s1:s2,:);
        if s1 ~= s2
            centroid0 = mean(centroid0);
        end
        bb = mean(roi.boundingBox(s1:s2,1:2));
        centroid0 = centroid0 - bb + 1;
        muSpot = mean(roi.spot(:,:, s1:s2),3);
        
        % muSpot = subtractBackground(muSpot);
        parms0 = [centroid0(1), centroid0(2), 1, 1, mean(muSpot(:)),0];
        parms1 = fitgaussian2d(muSpot, [], 2, 1e-6);
        
        [xc yc sigma] = radialcenter(muSpot);
        centroid1 = [xc, yc]; 
        centroid1 = [parms1(1), parms1(2)];
        dist(i) = calcDist(centroid0, centroid1);
        
        k =  'Kept';
        if dist(i) > maxdist
           class(s1:s2) = class(s1:s2)-1;  
           removedEvents = removedEvents + 1;
           k = 'Removed';
        end
        
        if showPlot
            subplot(kk,5, p)
            imshow(muSpot, [], 'InitialMagnification', 5e3); hold on;
            scatter(centroid0(1), centroid0(2), 'ro')
            scatter(centroid1(1), centroid1(2), 'b*')
            title([k, ' ', num2str(i)])
        end
    end
end
[comps, ideal, class] = computeCenters(roi.time_series, class);
roi.disc_fit.components = comps; 
roi.disc_fit.ideal = ideal; 
roi.disc_fit.class = class; 
roi.disc_fit.removedEvents = removedEvents;

events = [events, dist]

end