function scrollSpot(data, indices)

spots = data.rois(indices(1), indices(2)).spot;
[x,y, nSpots] = size(spots);

width = 100;
nSpotsTemp = nSpots; 
while rem(nSpotsTemp,width)
    nSpotsTemp = nSpotsTemp+1;
end
[mu,sigma] = normfit(spots(:));

figExist = findobj('type','figure','name','scroll spot');
if ~isempty(figExist)
    close('scroll spot');
end

plotScrollSpot(spots);

end