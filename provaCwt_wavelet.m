% [wt,f,coi] = cwt(squeeze(zebra.LFP(2,:,:)),'bump',zebra.acqF);
% logWt = 10*log10(abs(wt));
% [minim, iMin] = min(logWt,[],'all','linear');
% [iRow,iCol] = ind2sub(size(logWt),iMin);
% tmin = zebra.x(iCol);
% fmin = f(iRow);
% maxim = max(logWt,[],'all')+1;
% for i = 1:length(coi)
%     logWt(f<=coi(i),i) = maxim;
% end
% minim2 = min(logWt,[],'all');
% sum(logWt==minim2,'all')
% logWt(logWt == maxim) = minim2;
% 
% figure
% ax = axes;
% imagesc(ax,zebra.x,f,logWt);
% ax.YDir = 'normal';
% ax.YScale = 'log';
% ax.Colormap = [[1, 1, 1]; jet];
% colorbar(ax)

cwt(squeeze(zebra.LFP(2,:,:)),'bump',zebra.acqF);