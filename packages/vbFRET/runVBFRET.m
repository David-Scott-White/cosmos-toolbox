function [components,ideal, class,outF,allIdeal] = runVBFRET(X, threshold, maxRestarts)

%% Idealize vbFRET within ROI viewer
% Marcel P. Goldschen-Ohm
% marcel.goldschen@gmail.com
%
% David S. White
% dwhite7@wisc.edu
% edit by DSW

%%
% Purpose:
%   Run vbFRET_VBEM with self termination at 2 states > maxF
%
% How it Works:
%   Provide data (roi.zproj) to vbFRET_VBEM along with minClasses and
%   maxClasses. The alogirthm will determine which idealized values are
%   best for each set of classes, then determine which number of classes
%   best suits the data.
%
% Link to vbFRET:
%   http://vbfret.sourceforge.net/
%   Based on: Broson et al., 2009, Biophysical Journal


%% Updates
% 19/03/13  Written by DSW



%% Inititate for vBFRET
% all inputs for the vbFRET algorithm.
if ~exist('threshold','var'); threshold = 1e-6; end
if ~exist('maxRestarts','var'); maxRestarts = 10; end

data = X;
numDataPts = length(data);
dataMin = min(data);
dataMax = max(data);
data = (data - dataMin) ./ (dataMax - dataMin);

dim = 1; % analyze data in 1D

% analyzeFRET program settings
PriorPar.upi = 1;
PriorPar.mu = .5 * ones(dim, 1);
PriorPar.beta = 0.25;
PriorPar.W = 50 * eye(dim);
PriorPar.v = 5.0;
PriorPar.ua = 1.0;
PriorPar.uad = 0;
%PriorPar.Wa_init = true;

% set the vb_opts for VBEM
vb_opts.maxIter = 100; % stop after vb_opts iterations if program has not yet converged
vb_opts.threshold = threshold; % question: should this be a function of the size of the data set??
vb_opts.displayFig = 0; % display graphical analysis
vb_opts.displayNrg = 0; % display nrg after each iteration of forward-back
vb_opts.displayIter = 0; % display iteration number after each round of forward-back
vb_opts.DisplayItersToConverge = 0; % display number of steped needed for convergance

% bestMix = cell(1, maxClasses);
% set size
bestOut = cell(1, 10);
outF = -inf * ones(1, 10);
best_idx = zeros(1, 10);

% Make sure the data is a row vector.
if ~isequal(size(data), [1, length(data)])
    data = data';
end

%% Run the VBEM algorithm.
best_k = 1;
k = 1;
done = 0;
while ~done
    % disp(['States: ' num2str(k)])
    
    init_mu = (1:k)' / (k + 1);
    i = 1;
    maxLP = -Inf;
    while i < maxRestarts + 1
        if k == 1 && i > 3
            break
        end
        if i > 1
            % init_mu = (1:k)' / (k + 1);
            init_mu = (1:k)' / (k-1);
            init_mu = init_mu - min(init_mu);
            step = mean(diff(init_mu));
            init_mu = init_mu + (rand(k, 1) .* 2 - 1) .* (0.1 * step);
        end
        clear mix out;
        % Initialize gaussians
        % Note: x and mix can be saved at this point andused for future
        % experiments or for troubleshooting. try-catch needed because
        % sometimes the K-means algorithm doesn't initialze and the program
        % crashes otherwise when this happens.
        try
            [mix] = get_mix(data', init_mu);
            [out] = vbFRET_VBEM(data, mix, PriorPar, vb_opts);
        catch
            disp('There was an error, repeating restart.');
            runError = lasterror;
            disp(runError.message)
            continue
        end
        % Only save the iterations with the best out.F
        if out.F(end) > maxLP
            maxLP = out.F(end);
            bestOut{1, k} = out;
            outF(1, k) = out.F(end);
            best_idx(1, k) = i;
        end
        i= i + 1;
    end
    % check for termination
    % terminate 2 greater than max value
    [best_f,best_k] = max(outF);
    if best_k + 2 == k
        done = 1;
    else
        % iterate
        k = k +1;
    end
    
end

%% Get idealized data fits of best_k
% [classk, idealk] = chmmViterbi(bestOut{1, best_k}, data);
% 
% % compute components and stuff
% [components,ideal,class] = computeCenters(X,classk);
% outF = outF';

% get all idealized fits 
allIdeal = [];
allClass = []; 
for i = 1:length(bestOut)
    if ~isempty(bestOut{i})
        [c, cc] = chmmViterbi(bestOut{1, i}, data);
        allIdeal = [allIdeal, cc]; 
        allClass = [allClass, cc];
    end
end

% get best fit 
[components,ideal,class] = computeCenters(X,allClass(:,best_k));
outF = outF';


%%
% disp('idealizeVbFRET done.');
