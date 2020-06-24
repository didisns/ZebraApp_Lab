function outfeatures = featExtrWT(inMat,par)
% Wavelet transform to extract features.
% This function selects significant features to describe each row of the
% input matrix. The features derive from the coefficients obtained by the
% discrete wavelet transfor (dWT), and the significant ones are chosen 
% according to their non-gaussian behaviour computed on the columns of the
% matrix by the Kolmogorov-Smirnov test (Quiroga,2018).
% INPUTS:
% inMat = matrix with one element of interest per row; the function will
% run dWT on each distinct row.
% par = structure array containing the parameters to be used:
% par.wtType: type of WT
% par.lvl: level of the transform
% par.min: dimensionality reduction: min # of data points to be used for clustering
% par.max: dimensionality reduction: max # of data points to be used for
% clustering expressed in a fraction
% OUTPUTS:
% outfeatures: matrix that contains all the coefficients computed with the
% dWT that resulted to be relevant after the dimensionality reduction.

[nrow,ncol] = size(inMat);
par.max = ceil(par.max * ncol);
featMat = zeros(nrow,ncol);  % initialization of the matrix that will contain the general features of each row
% Haar's wavelet decomposition
for i=1:nrow
    [c,~] = wavedec(inMat,par.lvl,par.wtType);
    featMat(i,1:ls) = c(1:ls); 
end

% outliers elimination and Kolmogorov-Smirnov test
ks = zeros(1,ncol); % vector that will contain the values of the KS for each col 
thr_dist = (std(featMat))*3;
thr_dist_min = mean(featMat) - thr_dist;
thr_dist_max = mean(featMat) + thr_dist;
for i=1:ncol
    temp = featMat(find(featMat(:,i)>thr_dist_min & featMat(:,i)<thr_dist_max),i); % outliers elimination
    if length(temp) > 10
        [~,~,ks(i)]  = kstest(temp);
    else
        ks(i) = 0;
    end
end
[sortKS,iKS] = sort(ks);
sel_sortKS = sortKS(end - par.max + 1:end); % first selection (dim red)
%%% Debug: exponential behaviour of sortKS
figure
stairs(sort(ks))
title('Exponential of KS values')
ylabel('ks_stat')
xlabel('#features')
hold on
plot([numel(ks)-par.max numel(ks)-par.max],ylim,'--r')
% if ~isempty(inputs)
%     line([numel(ks)-inputs+1 numel(ks)-inputs+1],ylim,'color','r')
% end
%%%

% smooth derivative and normalization by the number of coefficients [length(sel_sortKS)
% or par.max] and the maximum:
nd = 10; 
d = (sel_sortKS(nd:end)-sel_sortKS(1:end-nd+1))/nd/max(sel_sortKS)*par.max; 
% definition of the knee of exponential: 
% estimate >1 for three consecutive samples
all_above1 = find(d >= 1);
if numel(all_above1) >= 2
    all_above1_2 = [all_above1(2:end) 0];
    all_above1_3 = [all_above1(3:end) 0 0];
    sumabove1 = all_above1 + all_above1_2 + all_above1_3;
    knee = find(sumabove1 == 3, 1);
    featNum = lenght(sel_sortKS(knee:end)); % number of inputs for dimensionality reduction
else
    featNum = par.min;
end

if featNum > par.max
    featNum = par.max;
elseif isempty(featNum) || featNum < par.min
    featNum = par.min;
end

featCol = zeros(1,featNum);
if ~isempty(knee)
    featCol = iKS(knee:end);
else
    featCol = iKS(end-inNum+1 : end);
end

% Creation of the input matrix for the clustering 
outfeatures = zeros(nrow,featNum);
for i=1:nrow
    for j=1:featNum
        outfeatures(i,j) = featMat(i,featCol(j));
    end
end

% this is their code that i don't understand completely: 

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
end