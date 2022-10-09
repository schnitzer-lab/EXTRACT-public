function idx_match = match_sets(X1,X2,corr_thresh)

% Exit with empty match if one component is empty
if isempty(X1) || isempty(X2)
    idx_match = zeros(2,0);
    return;
end

if ~exist('corr_thresh','var')
    corr_thresh = 0.5;
end
N = size(X1,1);
X1_norm = zscore(X1,1,1)/sqrt(N);
X2_norm = zscore(X2,1,1)/sqrt(N);
C = X1_norm'*X2_norm;
[s1,s2] = size(C);

idx_match = [];
while true
    [m,i] = max(C(:));
    if m<=corr_thresh
        break
    end
    [i1,i2] = ind2sub([s1,s2],i);
    idx_match = [idx_match,[i1;i2]];
    C(i1,:) = 0;
    C(:,i2) = 0;
    
end

% Sort wrt X1
[~,sorted_idx] = sort(idx_match(1,:));
idx_match = idx_match(:,sorted_idx);

% OLD method
% k = size(X1,2);
% 
% corr = gather(normc(gpuArray(X1))'*normc(gpuArray(X2)));
% [m,idx] = max(corr,[],2);
% m = m';idx = idx';
% idx_match = [1:k;idx];
% 
% stop=0;
% while ~stop
%     for acc = 1:length(idx)
%         idx_equal = find(idx==acc);
%         m_sub = m(idx_equal);
%         idx_survived = idx_equal(m_sub==max(m_sub));
%         idx_others = setdiff(idx_equal,idx_survived);
%         idx(idx_others) = [];
%         idx_match(:,idx_others) = [];
%         m(idx_others) = [];
%         if length(idx_equal)>1
%             break;
%         end
%         if acc ==length(idx)
%             stop=1;
%         end
%     end
% end
% 
% idx_match(:,m<0.5)=[]; % threshold at 45 degree angle 
