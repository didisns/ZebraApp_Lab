
function computeMeanData (app)
    % Compute means of all the data representations on all trials
    % April 25, 2017. A checkbox is added to skip the first trial
    % March 2018. Modified to allow conditional computation of BPed data
    % 2019/05/29, Gab. mean BandPassed_LFP computation moved to the function "computeBPandNotch"

    leakageFlag = app.displayLeakCk.Value;
    skipFlag = app.skip1trialCk.Value;
    if skipFlag
        trialBegins = 2 - app.alreadySkipped; % Gab, 2019/05/29: if the fist trial have been excluded
                                            % during trial extraction,
                                            % there's no reason for
                                            % skipping another one here.
    else
        trialBegins = 1;
    end

    app.meanSpgDeleaked = [];
    app.meanSpg = [];
    
    % compute mean lfp
    app.meanLFP = squeeze(mean(app.workLFP(:,trialBegins:app.nTrials,:),2));
    
    % compute mean band-passed lfp
    app.meanBP = squeeze(mean(app.bandPassed_LFP(:,:,trialBegins:app.nTrials,:),3));
    
    % compute mean spectrogram
    if leakageFlag      %GAB: add plotting of deleaked mean spg.
        app.meanSpgDeleaked = squeeze(mean(app.spgDeleaked(:,trialBegins:app.nTrials,:,:),2));
    end
    app.meanSpg = squeeze(mean(app.spg(:,trialBegins:app.nTrials,:,:),2));
    
    % compute mean E/I index
    if app.computeEIrat.Value
        app.meanEIrat = mean (app.EIrat(:,trialBegins:app.nTrials,:),2);
    end
    % compute mean 'gamma' power
    if app.computeEnvelope.Value
        app.meanSpgPlot = mean (app.spgPlot(:,trialBegins:app.nTrials,:),2);
    end
    % the computation of the mean power spectra has been moved to the
    % ZebraSpectre.m file
    
%     for i=1:app.nCh
%         tmp = [];        % initialize tmp
%         % create temporary matrix for average computation
%         tmp (1:app.nTrials-trialBegins+1,1:app.dtaLen) = app.workLFP(i,trialBegins:app.nTrials,1:app.dtaLen);
%         app.meanLFP (i,1:app.dtaLen) = mean (tmp,1);
%         
%         % compute mean of band-passed data
%         % Gab: moved to "computeBPandNotch"
%         
%         % compute mean spectrogram
%         tmp = [];
%         if leakageFlag      %GAB: add plotting of deleaked mean spg.
%             tmp (1:app.nTrials-trialBegins+1,1:app.freqN,1:app.spgl) = app.spgDeleaked(i,trialBegins:app.nTrials,1:app.freqN,1:app.spgl);
%             app.meanSpgDeleaked (i,1:app.freqN,1:app.spgl) = mean (tmp,1);
%         end
%         tmp (1:app.nTrials-trialBegins+1,1:app.freqN,1:app.spgl) = app.spg(i,trialBegins:app.nTrials,1:app.freqN,1:app.spgl);
%         app.meanSpg (i,1:app.freqN,1:app.spgl) = mean (tmp,1);
% 
%           
%     end
end