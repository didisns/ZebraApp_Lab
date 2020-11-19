load('C:\Users\LaBandaPassante\Documents\Data\PTEN\IUE B4 Cre 80to1 P32\181119\Dir_08\ltp001_UStraces.mat');
strTitle = 'KO';

% load('C:\Users\LaBandaPassante\Documents\Data\PTEN\IUE B4 Cre 80to1 P32\181112 comtrol no fluo\181112\Dir_06\ltp001_UStraces.mat');
% strTitle = 'CTRL';

%% LFP
meanUs = squeeze(mean(lfp.traces,2));
semUs = squeeze(std(lfp.traces,[],2))./sqrt(size(lfp.traces,2));

figure
ax = axes;
hold on
shadeWt = patch( [lfp.timeVect, fliplr(lfp.timeVect)], [meanUs(1,:)+semUs(1,:), fliplr(meanUs(1,:)-semUs(1,:))],'b');
shadeWt.EdgeAlpha = 0;
% shadeKo.FaceColor = [1,0,0];
shadeWt.FaceAlpha = 0.2;

shadeKo = patch( [lfp.timeVect, fliplr(lfp.timeVect)], [meanUs(2,:)+semUs(2,:), fliplr(meanUs(2,:)-semUs(2,:))],'r');
shadeKo.EdgeAlpha = 0;
% shadeWt.FaceColor = [0,0,1];
shadeKo.FaceAlpha = 0.2;

plot(lfp.timeVect,meanUs(1,:),'Color','b','LineWidth',0.5)
plot(lfp.timeVect,meanUs(2,:),'Color','r','LineWidth',0.5)

title(strTitle)

%% RMS
meanUs = squeeze(mean(log10(env.traces),2));
semUs = squeeze(std(log10(env.traces),[],2))./sqrt(size(env.traces,2));

figure
ax = axes;
hold on
shadeWt = patch( [env.timeVect, fliplr(env.timeVect)], [meanUs(1,:)+semUs(1,:), fliplr(meanUs(1,:)-semUs(1,:))],'b');
shadeWt.EdgeAlpha = 0;
% shadeKo.FaceColor = [1,0,0];
shadeWt.FaceAlpha = 0.2;

shadeKo = patch( [env.timeVect, fliplr(env.timeVect)], [meanUs(2,:)+semUs(2,:), fliplr(meanUs(2,:)-semUs(2,:))],'r');
shadeKo.EdgeAlpha = 0;
% shadeWt.FaceColor = [0,0,1];
shadeKo.FaceAlpha = 0.2;

plot(env.timeVect,meanUs(1,:),'Color','b','LineWidth',0.5)
plot(env.timeVect,meanUs(2,:),'Color','r','LineWidth',0.5)

yyaxis('right')
plot(env.timeVect, mean( squeeze(log10(env.traces(2,:,:))-log10(env.traces(1,:,:))),1 ))

title(strTitle)


