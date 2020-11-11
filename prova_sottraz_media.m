m = mean(squeeze(zebra.LFP(1:16,:,:)),1);
m = reshape(m,1,1,[]);
zebra.LFP(1:16,:,:) = zebra.LFP(1:16,:,:) - m;