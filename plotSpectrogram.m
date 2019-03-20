function plotSpectrogram (app)
% This function performs the plot in the SPG window.
% Depending on the selected radio button different data are plotted down
% there.

tmp = [];
%axes(handles.spectraWide)      % select the SPG axes
cla(app.spectraWide)
% load in all necessary parameters from the handles structure
freqLow = app.SPGfromFreq.Value;
freqHigh = app.SPGtoFreq.Value;
app.SPGlowDB = app.lowerDB.Value;
app.SPGhighDB = app.upperDB.Value;
flagMd = app.plotMeanFlag.Value;     % plot average trace
flagTr = app.plotTrCk.Value;         % plot single trace
flagFlt = app.filterBPpower.Value;
flagBPpower = app.gammaPower.Value;
flagEI = app.EIbutton.Value;
flagSPG = app.SPG.Value;
flagBP = app.BP.Value;
flagLog = app.SPGlogCk.Value;
flagLeak = app.displayLeakCk.Value;

flagSkip1st = app.skip1trialCk.Value; %gab&enrico 2018/11/02 provvisorio

% A the beginning, the scale must be reset to normal, to prevent errors. ENRICO 11/12/2018
app.spectraWide.YScale = 'linear';

if flagSPG
    if flagMd
        if (app.deleakedFlag && flagLeak)
            temp(1:app.freqN,1:app.spgl) = app.meanSpgDeleaked(app.currentCh,1:app.freqN,1:app.spgl);
        else
            temp(1:app.freqN,1:app.spgl) = app.meanSpg(app.currentCh,1:app.freqN,1:app.spgl);    
        end
    else    
        if (app.deleakedFlag && flagLeak)
            temp(1:app.freqN,1:app.spgl) = app.spgDeleaked(app.currentCh,app.currentTrial,1:app.freqN,1:app.spgl);
        else
            temp(1:app.freqN,1:app.spgl) = app.spg(app.currentCh,app.currentTrial,1:app.freqN,1:app.spgl);
        end
    end
    % the spectrogram is represented in decibels
    imagesc(app.spectraWide, app.spgt,app.spgw,10*log10(temp))
    axis(app.spectraWide, [app.tmin app.tmax freqLow freqHigh]);
%     cmap = fire(size(app.spectraWide.Colormap,1));
%     %colormap(app.spectraWide,map)
%     app.spectraWide.Colormap = cmap;
    caxis(app.spectraWide, [app.SPGlowDB app.SPGhighDB]);
    app.spectraWide.YDir = 'normal';
    app.spectraWide.YLabel.String = 'Frequency (Hz)';
end

if flagBP
    hold(app.spectraWide, 'on');
    % collect the BP data to plot
    flagBP1 = app.bpCheck1.Value;
    flagBP2 = app.bpCheck2.Value;
    flagBP3 = app.bpCheck3.Value;
    flagHP = app.hpCheck.Value;
    
    % BP power data are plotted one at the time 
    if flagBP1
        if flagMd
            % plot average of BP power
%             tmp(1:handles.spgl) = handles.meanSpgPlot(handles.currentCh,1:handles.spgl);
            tmpX(1:app.BPpowerL(2)) = app.BPpower (1,2,app.currentCh,app.currentTrial,1:app.BPpowerL(2));
            tmpY(1:1:app.BPpowerL(2)) = ...
                squeeze(mean(app.BPpower (2,2,app.currentCh,flagSkip1st+1:end,1:app.BPpowerL(2)),4));
            plot(app.spectraWide, tmpX,tmpY,'Color','c','LineWidth',1);
        end
        if flagTr
            % plot single trial
            tmpX(1:app.BPpowerL(2)) = ...
                app.BPpower (1,2,app.currentCh,app.currentTrial,1:app.BPpowerL(2));  
            tmpY(1:1:app.BPpowerL(2)) = ...
                app.BPpower (2,2,app.currentCh,app.currentTrial,1:app.BPpowerL(2));
            plot(app.spectraWide, tmpX,tmpY,'Color','c','LineWidth',1);
        end
    end
    if flagBP2
        if flagMd
            % plot average of BP power
    %        tmp(1:handles.spgl) = handles.meanSpgPlot(handles.currentCh,1:handles.spgl);
            tmpX(1:app.BPpowerL(3)) = app.BPpower (1,3,app.currentCh,app.currentTrial,1:app.BPpowerL(3));
            tmpY(1:1:app.BPpowerL(3)) = ...
                squeeze(mean(app.BPpower (2,3,app.currentCh,flagSkip1st+1:end,1:app.BPpowerL(3)),4));
            plot(app.spectraWide, tmpX,tmpY,'Color','r','LineWidth',1);
        end
        if flagTr
            % plot single trial
            tmpX(1:app.BPpowerL(3)) = ...
                app.BPpower (1,3,app.currentCh,app.currentTrial,1:app.BPpowerL(3));  
            tmpY(1:1:app.BPpowerL(3)) = ...
                app.BPpower (2,3,app.currentCh,app.currentTrial,1:app.BPpowerL(3));
            plot(app.spectraWide, tmpX,tmpY,'Color','r','LineWidth',1);
        end
    end
    if flagBP3
        if flagMd
            % plot average of BP power
    %        tmp(1:handles.spgl) = handles.meanSpgPlot(handles.currentCh,1:handles.spgl);
            tmpX(1:app.BPpowerL(4)) = app.BPpower (1,4,app.currentCh,app.currentTrial,1:app.BPpowerL(4));
            tmpY(1:1:app.BPpowerL(4)) = ...
                squeeze(mean(app.BPpower (2,4,app.currentCh,flagSkip1st+1:end,1:app.BPpowerL(4)),4));
            plot(app.spectraWide, tmpX,tmpY,'Color','g','LineWidth',1);
        end
        if flagTr
            % plot single trial
            tmpX(1:app.BPpowerL(4)) = ...
                app.BPpower (1,4,app.currentCh,app.currentTrial,1:app.BPpowerL(4));  
            tmpY(1:1:app.BPpowerL(4)) = ...
                app.BPpower (2,4,app.currentCh,app.currentTrial,1:app.BPpowerL(4));
            plot(app.spectraWide, tmpX,tmpY,'Color','g','LineWidth',1);
        end
    end
    if flagHP
        if flagMd
            % plot average of BP power
    %        tmp(1:handles.spgl) = handles.meanSpgPlot(handles.currentCh,1:handles.spgl);
            tmpX(1:app.BPpowerL(5)) = app.BPpower (1,5,app.currentCh,app.currentTrial,1:app.BPpowerL(5));
            tmpY(1:1:app.BPpowerL(5)) = ...
                squeeze(mean(app.BPpower (2,5,app.currentCh,flagSkip1st+1:end,1:app.BPpowerL(5)),4));
            plot(app.spectraWide, tmpX,tmpY,'Color','blue','LineWidth',1);
        end
        if flagTr
            % plot single trial
            tmpX(1:app.BPpowerL(5)) = ...
                app.BPpower (1,5,app.currentCh,app.currentTrial,1:app.BPpowerL(5));  
            tmpY(1:1:app.BPpowerL(5)) = ...
                app.BPpower (2,5,app.currentCh,app.currentTrial,1:app.BPpowerL(5));
            plot(app.spectraWide, tmpX,tmpY,'Color','blue','LineWidth',1);
        end
    end
%         if flagFlt
%             % adapt the filter frame and order to the length of the data
%             frame = int32(handles.spgl / 64) * 2 + 1;   % frame must be odd. Thats is why *2+1 !
%             if (frame > 3), tmp = sgolayfilt(tmp,3,frame);
%             else
%                 if (frame > 2), tmp = sgolayfilt(tmp,2,frame);
%                 end
%             end
%         end

    axis(app.spectraWide, [app.tmin app.tmax 0 inf]);
    if flagLog, app.spectraWide.YScale = 'log';
    end
    app.spectraWide.YLabel.String = 'Power';
    hold(app.spectraWide, 'off')
end
    
if flagBPpower
    if flagMd
        tmp(1:app.spgl) = app.meanSpgPlot(app.currentCh,1:app.spgl);
    else
        if (app.deleakedFlag && flagLeak)
            tmp(1:app.spgl) = app.spgPlotDeleaked(app.currentCh,app.currentTrial,1:app.spgl);
        else
            tmp(1:app.spgl) = app.spgPlot(app.currentCh,app.currentTrial,1:app.spgl);
        end
        if flagFlt
            % adapt the filter frame and order to the length of the data
            frame = int32(app.spgl / 64) * 2 + 1;   % frame must be odd. Thats is why *2+1 !
            if (frame > 3), tmp = sgolayfilt(tmp,3,frame);
            else
                if (frame > 2), tmp = sgolayfilt(tmp,2,frame);
                end
            end
        end
    end    
    plot(app.spectraWide, app.spgt,tmp);
    axis(app.spectraWide, [app.tmin app.tmax -inf inf]);
    if flagLog, app.spectraWide.YScale = 'log';
    end
    app.spectraWide.YLabel.String = 'Power';
end

if flagEI
    if flagMd
        tmp(1:app.spgl) = app.meanEIrat(app.currentCh,1:app.spgl);
    else
        tmp(1:app.spgl) = app.EIrat(app.currentCh,app.currentTrial,1:app.spgl);
        if flagFlt
            % adapt the filter frame and order to the length of the data
            frame = int32(app.spgl / 64) * 2 + 1;   % frame must be odd. Thats is why *2+1 !
            if (frame > 3), tmp = sgolayfilt(tmp,3,frame);
            else
                if (frame > 2), tmp = sgolayfilt(tmp,2,frame);
                end
            end
        end
    end    
    plot(app.spectraWide, app.spgt,tmp);
    axis(app.spectraWide, [app.tmin app.tmax -inf inf]);
    if flagLog, app.spectraWide.YScale = 'log';
    end
    %set(gca,'yscale','log');
end