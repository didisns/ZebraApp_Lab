% load all the matrix


normX = 10; % avg power of a nigh seizure
f = figure;
a = axes;
hold on
% day first
xincrement = 0.45;
daymice = unique([seiz_day_withbaseline{2:end,1}]);
currentX = 0;
x_incr = 0;
cols = autumn(numel(daymice));
for i = 1:numel(daymice)
    fprintf('drawing mouse %i \n',i)
    subtab = seiz_day_withbaseline( [false, [seiz_day_withbaseline{2:end,1}] == daymice(i)], :);
    currentX = currentX+x_incr;
    x_incr = 0;
    for currEvent = 1:size(subtab,1)
        if subtab{currEvent,3}>0
            startT = subtab{currEvent,2};
            duration = subtab{currEvent,3};
            amplit = subtab{currEvent,4};
            images.roi.Ellipse(a,'center',[currentX, startT+duration/2/60],'semiaxes',[amplit/2/normX, duration/2/60],...
                    'FaceSelectable',false,'selected',false,'InteractionsAllowed','none',...
                    'Color',cols(i,:),'LineWidth',0.1);
            x_incr = max(x_incr,xincrement);
        else
            plot(currentX,60,'^','color',cols(i,:),'MarkerFaceColor',cols(i,:),'MarkerSize',10)
            x_incr = max(x_incr,xincrement);
        end
    end
end
xlim([-2, currentX+2])
ylim([-5,65])

% then night
xincrement = 0.6;
nightmice = unique([seiz_night_withbaseline{2:end,1}]);
x_incr = 1;
cols = winter(numel(nightmice));
for i = 1:numel(nightmice)
    fprintf('drawing mouse %i \n',i)
    subtab = seiz_night_withbaseline( [false, [seiz_night_withbaseline{2:end,1}] == nightmice(i)], :);
    currentX = currentX+x_incr;
    x_incr = 0;
    for currEvent = 1:size(subtab,1)
        if subtab{currEvent,3}>0
            startT = subtab{currEvent,2};
            duration = subtab{currEvent,3};
            amplit = subtab{currEvent,4};
            images.roi.Ellipse(a,'center',[currentX, startT+duration/2/60],'semiaxes',[amplit/2/normX, duration/2/60],...
                    'FaceSelectable',false,'selected',false,'InteractionsAllowed','none',...
                    'Color',cols(i,:),'LineWidth',0.1);
            x_incr = max(x_incr,xincrement);
        else
            plot(currentX,60,'^','color',cols(i,:),'MarkerFaceColor',cols(i,:),'MarkerSize',10)
            x_incr = max(x_incr,xincrement);
        end
    end
end
xlim([-0.5, currentX+0.5])
ylim([-5,65])

% then night + BUME
xincrement = 0.45;
nightmiceBUME = unique([seiz_nightBume{2:end,1}]);
x_incr = 1;
cols = copper(numel(nightmiceBUME));
for i = 1:numel(nightmiceBUME)
    fprintf('drawing mouse %i \n',i)
    subtab = seiz_nightBume( [false, [seiz_nightBume{2:end,1}] == nightmiceBUME(i)], :);
    currentX = currentX+x_incr;
    x_incr = 0;
    for currEvent = 1:size(subtab,1)
        if subtab{currEvent,3}>0
            startT = subtab{currEvent,2};
            duration = subtab{currEvent,3};
            amplit = subtab{currEvent,4};
            images.roi.Ellipse(a,'center',[currentX, startT+duration/2/60],'semiaxes',[amplit/2/normX, duration/2/60],...
                    'FaceSelectable',false,'selected',false,'InteractionsAllowed','none',...
                    'Color',cols(i,:),'LineWidth',0.1);
            x_incr = max(x_incr,xincrement);
        else
            plot(currentX,60,'^','color',cols(i,:),'MarkerFaceColor',cols(i,:),'MarkerSize',10)
            x_incr = max(x_incr,xincrement);
        end
    end
end
xlim([-0.5, currentX+0.5])
ylim([-5,65])
a.YGrid = 'on';


