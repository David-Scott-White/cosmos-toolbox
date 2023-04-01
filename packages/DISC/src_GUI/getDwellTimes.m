function getDwellTimes(data, ch_idx)
% Fit and plot each dwell times for each state

% note, meant for quick visualization within the GUI and should not replace
% more thorough analysis (eg bootstrap) 

% User window for frame rate and state
prompt = {'State', 'Frame Rate (s):', 'Num Exponents', 'bootStrap (bool)'};
dlgtitle = 'Input';
dims = [1 35];
if isfield(data, 'frameRate_s')
    definput = {'2',num2str(data.frameRate_s(ch_idx)),'2', '0'};
else
    definput = {'2','1','2', '0'};
end
answer = inputdlg(prompt,dlgtitle,dims,definput);

state = str2double(answer{1});
fps = 1/str2double(answer{2});
numExp = str2double(answer{3});
bootStrap = str2double(answer{4});

idx = findSelected(data, ch_idx);
events = cell(1, length(idx));
allEvents = []; 
% use DISC function
for i = idx'
    events{1, i} = findEvents(data.rois(i, ch_idx).disc_fit.class);
    % returns events = [start frame, stop frame, duration, label]
    allEvents = [allEvents; events{1,i}];
end

if ~isempty(allEvents)
    % partion dwells
    dwells = dwellTime(allEvents,fps);
    % fit dwells
    d = dwells{state};
    dtf = fitDwells(d, numExp, bootStrap, []);
    plotDwells(d, dtf);
    xlabel(['State: ', num2str(state), ' (s)']);
else
    msgbox('No Events detected. Try selecting molecules');
end
