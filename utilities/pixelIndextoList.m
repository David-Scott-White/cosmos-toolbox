function pixelList = pixelIndextoList(rowStart, rowStop, columnStart, columnStop)
pixelList = []; 
if nargin < 4
    disp('Error in pixelIndextoList: Requires 4 variables');
    return
end

x = rowStart:rowStop;
y = columnStart:columnStop;
pixelList = zeros(length(x)*length(y), 2);
p = 1; 
for i = 1:length(x)
    for j = 1:length(y)
        pixelList(p,:) = [x(i),y(j)]; 
        p = p + 1;
    end
end

end