function [outfeatures] = featExtrWT(inMat,par)
% Wavelet transform to extract features.
% This function selects significant features to describe each row of the
% input matrix. The features derive from the coefficients obtained by the
% discrete wavelet transform (dWT), and the significant ones are chosen 
% according to their non-gaussian behaviour computed on the columns of the
% matrix by the Kolmogorov-Smirnov test, Lilliefors version (Quiroga,2018).
% INPUTS:
% inMat = matrix with one element of interest per row; the function will
% run dWT on each distinct row.
% par = structure array containing the parameters to be used for the WT:
% par.wtType: type of WT
% par.lvl: level of the transform
% par.min: dimensionality reduction: min # of data points to be used for clustering
% par.max: dimensionality reduction: max # of data points to be used for
% clustering expressed in a fraction
% OUTPUTS:
% outfeatures: matrix that contains all the coefficients computed with the
% dWT that resulted to be relevant after the dimensionality reduction. The
% order of columns reflects ascending sorting of the Lilliefors'
% statistical value, meaning that the first column is the less
% statistically different for the test and the last column is the most
% statistically different value according to the test (thereby it is the
% most significant descriptive features for spike sorting purpose).

[nrow,ncol] = size(inMat);
par.max = ceil(par.max * ncol);
featMat = zeros(nrow,ncol);  % initialization of the matrix that will contain the general features of each row
% Haar's wavelet decomposition
for i=1:nrow
    [c,~] = wavedec(inMat(i,:),par.lvl,par.wtType);
    featMat(i,:) = c(1:ncol); 
end

% outliers elimination and KS-Lilliefors test
lillie = zeros(1,ncol); % vector that will contain the test values for each col 
thr_dist = (std(featMat))*3;
thr_dist_min = mean(featMat) - thr_dist;
thr_dist_max = mean(featMat) + thr_dist;
for i=1:ncol
    temp = featMat((featMat(:,i)>thr_dist_min(i) & featMat(:,i)<thr_dist_max(i)),i); % outliers elimination
    if length(temp) > 10
        [~,~,lillie(i)]  = lillietest(temp);
    else
        lillie(i) = 0;
    end
end

[sortL,iL] = sort(lillie);
sel_sortL = sortL(end - par.max + 1 : end); % first selection (dim reduc)

% %%% Debug: exponential behaviour of sortKS
% figure 
% stairs(sort(lillie))
% title('Exponential of Lilliefors values')
% ylabel('lilliefors stat')
% xlabel('# features')
% hold on
% plot([numel(lillie)-featNumLillie numel(lillie)-featNumLillie],ylim,'--r')
% %%%

% smooth derivative and normalization by the number of coefficients [length(sel_sortKS)
% or par.max] and the maximum:
nd = 10; 
dL = (sel_sortL(nd:end)-sel_sortL(1:end-nd+1))/nd/max(sel_sortL)*par.max; 

% definition of the knee of exponential: 
% estimate >1 for three consecutive samples
dLabove1 = dL >= 1;
if sum(dLabove1) >= 2  
    dL_conv = conv(double(dLabove1), [1/3 1/3 1/3]); % the convolution with 1/3 will be 1 only for three consecutive 1s in the vector
    kneeL = find(dL_conv == 1, 1) +2;
    if isempty(kneeL)
        featNumLillie = par.min;
    end
    featNumLillie = length(sel_sortL(kneeL:end)); % number of inputs for dimensionality reduction
else
    featNumLillie = par.min;
end

%%% how it works %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a = [0 0 0 0 1 0 0 0 0 0 1 1 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 ];
% b = ones(1,3)/3;
% c = conv(a,b);
% target = find(c==1,1)+length(b)-1;
% figure
% stairs(a)
% hold on
% plot(c,'o-')
% plot(target,'d')
% ylim([-0.1, 1.1])
% legend('logical array','convolution','location','southeast')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% control
if featNumLillie > par.max
    featNumLillie = par.max;
elseif isempty(featNumLillie) || featNumLillie < par.min
    featNumLillie = par.min;
end

featColLillie = iL(end - featNumLillie + 1:end); 

% Creation of the input matrix for the clustering: 
% featColLillie contains the indeces of coeff of interest but they are
% ordered according to the ascendent sorting of ks values
outfeatures = featMat(:,featColLillie);
%% this is their code that i don't understand completely: 
% if numel(all_above1) >=2
%     aux2 = diff(all_above1);
%     temp_bla = conv(aux2(:),[1 1 1]/3);
%     temp_bla = temp_bla(2:end-1);
%     temp_bla(1) = aux2(1);
%     temp_bla(end) = aux2(end);
%     
%     thr_knee_diff = all_above1(find(temp_bla(2:end)==1,1))+(nd/2); %ask to be above 1 for 3 consecutive coefficients
%     inputs = max_inputs-thr_knee_diff+1;
% else
%     inputs = min_inputs;
% end
% if inputs > max_inputs
%     inputs = max_inputs;
% elseif isempty(inputs) || inputs < min_inputs
%     inputs = min_inputs;
% end
% coeff(1:inputs)=ind(ls:-1:ls-inputs+1);

% %% feature extraction using the KS test
% [nrow,ncol] = size(inMat);
% par.max = ceil(par.max * ncol);
% featMat = zeros(nrow,ncol);  % initialization of the matrix that will contain the general features of each row
% % Haar's wavelet decomposition
% for i=1:nrow
%     [c,~] = wavedec(inMat(i,:),par.lvl,par.wtType);
%     featMat(i,:) = c(1:ncol); 
% end


% % Kolmogorov-Smirnov test
% ks = zeros(1,ncol); % vector that will contain the values of the KS for each col
% thr_dist = (std(featMat))*3;
% thr_dist_min = mean(featMat) - thr_dist;
% thr_dist_max = mean(featMat) + thr_dist;
% % build-up of a normal distribution from the empirical data distribution
% % and KS test
% for j=1:ncol
%     temp = featMat((featMat(:,j)>thr_dist_min(j) & featMat(:,j)<thr_dist_max(j)),j); % outliers elimination
%     temp = temp';
%     mu = mean(temp);
%     sigma = std(temp);
%     interval = linspace(min(temp), max(temp), length(temp));
%     GaussCDF = cdf('Normal',interval, mu, sigma);
%     gaussian = [interval' GaussCDF'];
%     if length(temp) > 10
%         [~,~,ks(j)]  = kstest(temp','CDF',gaussian);
%     else
%         ks(j) = 0;
%     end
% end
% [sortKS,iKS] = sort(ks);
% sel_sortKS = sortKS(end - par.max + 1 : end); % first selection (dim reduc)
% % %%% Debug: exponential behaviour of sortKS
% % figure
% % stairs(sort(ks))
% % title('Exponential of KS values')
% % ylabel('ks_stat')
% % xlabel('#features')
% % hold on
% % plot([numel(ks)-par.max numel(ks)-par.max],ylim,'--r')
% % % if ~isempty(inputs)
% % %     line([numel(ks)-inputs+1 numel(ks)-inputs+1],ylim,'color','r')
% % % end
% 
% % smooth derivative and normalization by the number of coefficients [length(sel_sortKS)
% % or par.max] and the maximum:
% nd = 10;
% d = (sel_sortKS(nd:end)-sel_sortKS(1:end-nd+1))/nd/max(sel_sortKS)*par.max; % /par.max
% % definition of the knee of exponential:
% % estimate >1 for three consecutive samples
% d_above1 = d >= 1;
% if sum(d_above1) >= 2
%     d_conv = conv(double(d_above1), [1/3 1/3 1/3]); % the convolution with 1/3 will be 1 only for three consecutive 1 in the vector
%     knee = find(d_conv == 1, 1) +2;
%     if isempty(knee)
%         featNum = par.min;
%     end
%     featNum = length(sel_sortKS(knee:end)); % number of inputs for dimensionality reduction
% else
%     featNum = par.min;
% end
% % control
% if featNum > par.max
%     featNum = par.max;
% elseif isempty(featNum) || featNum < par.min
%     featNum = par.min;
% end
% featCol = iKS(end - featNum + 1:end);
% % Creation of the input matrix for the clustering:
% % featCol contains the indeces of coeff of interest but they are
% % ordered according to the ascendent sorting of ks values
% outputKS = featMat(:,featCol);
% idx3featKS = iKS(end-3:end);
end