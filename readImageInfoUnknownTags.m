function fieldInfo = readImageInfoUnknownTags(imageInfo, varargin)
% David S. White
% 2022-10-23
% MIT

% imageInfo = struct retured from imread
% varargin = tags desired in the "UnknownTags" field of imageInfo.
numImages = length(imageInfo);
numFields = length(varargin);
fieldIndex = nan(1, numFields);
fieldInfo = nan(numImages, numFields);
for i = 1:numImages
    tags = split(imageInfo(i).UnknownTags(end).Value(2:end-1),',');
    if i == 1
        % get location of each of the varargin. same for each frame
        numTags = length(tags);
        p = 1;
        k = 1;
        while k <= numFields
            if strfind(tags{p}, varargin{k})
                fieldIndex(k) = p;
                k = k+1;
                p = 0;
            end
            p = p+1;
            if p > numTags
                break
            end
        end
    end
    for j = 1:numFields
        if ~isnan(fieldIndex(j))
            temp = split(tags{fieldIndex(j)}, ':');
            fieldInfo(i,j) = str2double(temp{2});
        end
    end
end

end