function [all_events] = findEvents(data_fit)
%% Find Events and Dwell Times from sequence of states 
% David S. White
% dwhite7@wisc.edu
%
% Updates:
% --------
% 2018-08-22 DSW wrote the code in this version, not sure when original
% code was written. Added in computing dwell times for convenience
% 2018-10-01 DSW added event_start rate as optional variable
% 2019-02-12 Edited a bug that shortened all dwell times by 1, resulting in
% dwells of 0
% 2019-08-26 DSW Full rewrite of the script to use array indexing rather
% than for loops. This makes the code orders of magnitude faster,
% especially for long data_fit. Changed "event_start" variable to
% "first_and_last" for comprehension. 
% 2019-10-29 DSW fix for first and last event in case of no events 
% 2020-02-11 DSW added "max_state" as variable
% 2022-04-05 DSW speed improvement with help of ChatGPT3.5
%
%
% Input Variables:
% ----------------
% data_fit = data_fit with labels either as states (1,2,3,etc...) or
%       intensity values 
%
% first_and_last = Boolean. Include or exclude first and last events.
%       In dwell time analysis, first and last events must be excluded 
%       since the full event time was not observed. 
%
% Output Variables:
% ----------------
% all_events = [N by 4] matrix of events where N is the number of events
%   [event_start, event_stop, event_duration, state_label ; ...] 
%
% -------------------------------------------------------------------------
% 
% grab all the state labels of "data_fit" as unique integers 
[~,~,state_sequence] = unique(data_fit); 
n_data_points = numel(data_fit);
event_index = (diff(state_sequence)~=0);
n_events = sum(event_index);

if ~n_events
    all_events = [1,n_data_points,n_data_points,data_fit(1)];
    return
end

% Allocate space for output variable. number_of_events by 4;
all_events = zeros(n_events+1,4); 

% event_start
all_events(:,1) = [1; find(event_index)+1];

% event_stop 
all_events(:,2) = [all_events(2:end,1)-1; n_data_points];

% Find dwell time of each event
all_events(:,3) = all_events(:,2) - all_events(:,1)+1;

% find the state label of each event from "data_fit"
all_events(:,4) = data_fit(all_events(:,1));

end


