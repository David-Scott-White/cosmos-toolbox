function handles = guiEstimateAllSNR(hObject, handles)
% returns snr, snb, and sigma as a field in rois strucutre; 
% 
% 
% David S. White 
% 2022-02-10
% MIT 
% -------------------------------------------------------------------------
[nrois, nchannels] = size(handles.data.rois); 
for j = 1:nchannels
    for i = 1:nrois
        [snr, snb, sigma] = estimateSNR(handles.data.rois(i,j).timeSeries); 
        handles.data.rois(i,j).snr = snr; 
        handles.data.rois(i,j).snb = snb; 
        handles.data.rois(i,j).sigma = sigma; 
    end
end
guidata(hObject, handles); 