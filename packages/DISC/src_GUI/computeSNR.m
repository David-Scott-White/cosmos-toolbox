function [snr,snr_mu, snr_all] = computeSNR(components)
% compute average snr across all states
% David S. White 

% updated: 
% 2019-08-22 DSW wrote the code 

% SNR: 
% (mu_n+1 - mu_n)/sigma_n (all in 'components' matrix)

% no signal to compute 
if size(components,1) == 1
    snr = NaN; 
    return
end

mu = components(:,2); 
sd = components(:,3); 

snr_all = (mu(2:end) - mu(1:end-1)) ./ sd(1:end-1);
snr_mu = mean(snr_all); 
snr = snr_all(1);

end
