function computeMeanOnTrials (app)
% This function is evoched in the presence of multiple trials. 
% Data are averaged on the trial number
% Finally, it computes metrics of the evoched response
% February 5, 2017
% Debug on January, 3 2018.
% Made some check to improve reliability for operation in the MeyerVEP mode
% Genuary 29, 2019. Adapted to app.
disp('Compute mean on trials');
computeMeanData (app)

skipFlag = get (app.skip1trialCk,'value');
if skipFlag
    trialBegins = 2 - app.alreadySkipped; % Gab, 2019/05/29: if the fist trial have been excluded
                                            % during trial extraction,
                                            % there's no reason for
                                            % skipping another one here.
else
    trialBegins = 1;
end

% load from the GUI all the necessary parameters

syCh = app.synchCh.Value;
exCh = app.excludeCh.Value;
flagExCh = app.excludeChFlag.Value;
flagSynch = app.internalSynchCk.Value;
flagTemplate = app.templateCk.Value;
flagDouble = app.doubleStimCk.Value;

sweepDuration = app.sp * (app.dtaLen-1);    % duration of each trial

% fix the following for meyer veps
%             handles.ntemp = 1;
%             if flagDouble, handles.ntemp = 2;
%             end

halfSweep = int32 (app.dtaLen/2);       % this can be easily generalize to multiple stim per sweep
halfSweepSPG = int32(app.spgl/2);

% window for template computation and fit
templFromI = int32(app.templateFrom.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
templToI = int32(app.templateTo.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
PWfromI = int32(app.winPWleft.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added  % window for power computation
PWtoI = int32(app.winPWright.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
% now check that all thee pointers have legal values, i.e. are compatible
% with the sweep length
if (templToI > app.dtaLen), templToI = app.dtaLen;
end
if (PWtoI > app.dtaLen), PWtoI = app.dtaLen;
end

templateLen = templToI - templFromI + 1;
tempTempl = zeros(1,templateLen);    
templateConvolutionLen = PWtoI - PWfromI +1;
tempTemplConv = zeros(1,templateConvolutionLen);
app.templateConv = [];

% windows for baseline computation and response
blFrom = int32(app.baselineFrom.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
blTo = int32(app.baselineTo.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
respFrom = int32(app.respFrom.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added
respTo = int32(app.respTo.Value/app.sp)+1 - app.timeOffset_i; %GAB 2019/02/24: offset added

% processing of spectrograms
% compute the deltaT of the spectrogram
dlt = (app.spgt(end)-app.spgt(1))/(size(app.spgt,2));
blFromSPG = int32((app.baselineFrom.Value-app.spgt(1))/dlt) + 1;
if (blFromSPG<1), blFromSPG=1;
end
blToSPG = int32((app.baselineTo.Value-app.spgt(1))/dlt) + 1;
if (blToSPG<1), blToSPG=1;
end
rsFromSPG= int32((app.respFrom.Value-app.spgt(1))/dlt) + 1;
if (rsFromSPG<1), rsFromSPG=1;
end
rsToSPG = int32((app.respTo.Value-app.spgt(1))/dlt) + 1;
bltemp = [];
rstemp = [];

if get(app.autoclear,'Value')
    app.respSummary = {};
    app.EPcnt = 0;
end

%----enrico+gab-2018/10/09
%set sgolay filter window
wSgolay = 2*round(0.5*(0.0101/app.sp-1))+1;
%----
for i=1:app.nCh
    % Computation of the metrics of the responses
    % Here we exclude the trigger channel and, if it is so marked, the
    % excluded channel.
    
    if (i ~= syCh || ~flagSynch) % if flagSynch is false always do the following
        if ~(flagExCh && i == exCh) 
            % compute evoked response from the mean trials and SPGs
            % first: computation in the time domain
            bltemp = [];
            rstemp = [];
            % compute the template all the way to the end of the
            % convolution window for the computation of the normalized
            % spectral power.
            app.ntemp = 1;
            if flagDouble, app.ntemp = 2;
            end
            for ii=1:app.ntemp
                tFrom(ii) = templFromI + halfSweep * (ii-1);
                tTo(ii) = templToI + halfSweep * (ii-1);
                tempTempl = tempTempl + app.meanLFP (i,tFrom(ii):tTo(ii)); 
                blFromNow(ii) = blFrom + halfSweep * (ii-1);
                blToNow(ii) = blTo + halfSweep * (ii-1);
                respFromNow(ii) = respFrom + halfSweep * (ii-1);
                respToNow(ii) = respTo + halfSweep * (ii-1);

                tFromPW(ii) = PWfromI + halfSweep * (ii-1);
                tToPW(ii) = PWtoI + halfSweep * (ii-1);
                tempTemplConv = tempTemplConv + app.meanLFP (i,tFromPW(ii):tToPW(ii));
            end
            
            % now average the mean sweeps
            template = tempTempl / app.ntemp;
            templateConv = tempTemplConv / app.ntemp;
            % smooth the template by Savitzky-Golay filtering
            template = sgolayfilt(template,3,wSgolay); %previously framelength was 101
            templateConv = sgolayfilt(templateConv,3,wSgolay);
            
            % align the template to baseline=0
            blDelta = blTo - templFromI;    % number of point in baseline
            offset = median(template(1:blDelta));     % OK
            template = template - offset;
            templateConv = templateConv - offset;
            % compute the amplitude of the template.
            [templatePeak peak_i] = max(abs(template));      % suggestion: what about normalizing the template to 1?
            app.templatePeakSigned(i) = template(peak_i);
            templateConv = templateConv / templatePeak;
            if templatePeak ~= max(template), templatePeak = -templatePeak;
            end
            template = template  / templatePeak;
            %handles.templ = template;
            app.templ(i,:) = template; %gab_2018/09/19 -> handles.templ is now a matrix with a "channel" dimension.
            app.templateConv(i,:) = templateConv; %gab+enr_2018/10/09
            
            % now the template must be fitted to the corresponding segments
            % of each trial. Each fit returns the offset and the linear
            % scaling factor.
            EPamplitude = [];
            for k=trialBegins:app.nTrials
                for ii=1:app.ntemp
                    app.EPcnt = app.EPcnt + 1;
                    % first extract the LFP segment to fit with the template
                    segment(1:templateLen) = app.workLFP(i,k,tFrom(ii):tTo(ii));
                    % Offset the segment to align the baseline to 0
                    offset = median(segment(1:blDelta));
                    segment = segment - offset;
                    %handles.segment(i,k,ii,:) = segment; %GAB&ENR 2018/10/03
                    %X = [ones(length(segment),1) segment];
                    %fitNow = template'\segment      
                    x = fminsearch(@gixres,1);
                    localEPamp = x ; % after the normalisation the following disappears! * templatePeak;
                    
                    app.EPamplitude(i,k,ii) = x; % this is used to plot the fitted template
                    app.EPoffset(i,k,ii) = offset;
                    % computation in the frequency domain by using the
                    % power selected (index: BP4power+1) GAB 06/04/2018
                    bltemp = [];
                    rstemp = [];
                    
                    bltemp = app.bandPassed_LFP(app.BP4power,i,k,blFromNow(ii):blToNow(ii));
                    %GAB 2019/02/24: add logarithm
                    bl = 10*log10(squeeze(rms (bltemp)));  % do we really need to squeeze?
                 
                    %bltemp = handles.EIrat (i,k,blFromSPG + halfSweepSPG*(ii-1):blToSPG + halfSweepSPG*(ii-1));
                    %bl = squeeze(mean (bltemp,3));
                    rstemp = app.bandPassed_LFP(app.BP4power,i,k,respFromNow(ii):respToNow(ii));
                    %GAB 2019/02/24: add logarithm
                    rs = 10*log10(squeeze(rms (rstemp)));
                    
                    %rstemp = handles.EIrat (i,k,rsFromSPG + halfSweepSPG*(ii-1):rsToSPG + halfSweepSPG*(ii-1));
                    %rs = squeeze(mean (rstemp,3));
                    FDresp = rs-bl;
                    % extract the band passed data
                    tempPW = app.bandPassed_LFP(app.BP4power,i,k,tFromPW(ii):tToPW(ii));
                    % multiply it by the fitted template. NO! we should
                    % pass it through the template but not the fitted
                    % template, otherwise the correlation between power and
                    % amplitude is artificially injected in the metric.
                    
                    newTempPW =  templateConv .* squeeze(tempPW)';
                    % and now compute the spectral power
                    templateSPW = rms(newTempPW);
                    
                    % stuff everything in the output table!
                    app.respSummary(app.EPcnt,1) = cellstr(app.file_in);  % 1: file name
                    app.respSummary(app.EPcnt,2) = num2cell(i);               % 2: channel number
                    app.respSummary(app.EPcnt,3) = num2cell(k);               % 3: trial
                    app.respSummary(app.EPcnt,4) = num2cell(ii);              % 4: repeat

                    app.respSummary(app.EPcnt,5)  = num2cell(localEPamp);     % 5: Peak response
                    app.respSummary(app.EPcnt,6)  = num2cell(0);              % 6: time to peak
                    app.respSummary(app.EPcnt,7)  = num2cell(bl);             % 7: Baseline mean BP1 power
                    app.respSummary(app.EPcnt,8)  = num2cell(rs);             % 8: Response mean BP1 power
                    app.respSummary(app.EPcnt,9)  = num2cell(FDresp);         % 9: Delta BP1 power
                    app.respSummary(app.EPcnt,10) = num2cell(templateSPW);   % 10: Delta BP1 power                
                    app.respSummary(app.EPcnt,11) = cellstr(app.expID);      % 11: Patient name-notes        
                end
            end    
            % compute metrics of the mean responses for each stim repeat
            for ii=1:app.ntemp
                bltemp = [];
                rstemp = [];
                bltemp = app.meanLFP (i,blFrom + halfSweep * (ii-1):blTo + halfSweep * (ii-1));
                bl = median (bltemp,2);
                % the baseline must be subtracted before computing the
                % absolute value
                rstemp = abs(app.meanLFP (i,respFrom + halfSweep * (ii-1):respTo + halfSweep * (ii-1)) - bl);
                % a bit of filtering before computation of the max
                rstemp = sgolayfilt(rstemp,3,floor(wSgolay/2)+1); %previously framelength
                [resp, imax] = max (rstemp,[],2);
                tpeak = app.sp*double(respFrom+imax) + app.timeOffset;
                resp = resp * sign(app.meanLFP (i,respFrom+imax) - bl);
                %resp = handles.meanLFP (i,respFrom+imax) - bl;

                % compute the response in the frequency domain    
                bltemp = [];
                rstemp = [];
                bltemp = app.meanEIrat (i,blFromSPG + halfSweepSPG*(ii-1):blToSPG + halfSweepSPG*(ii-1));
                bl = median (bltemp,2);

                rstemp = app.meanEIrat (i,rsFromSPG + halfSweepSPG*(ii-1):rsToSPG + halfSweepSPG*(ii-1));
                rs = median (rstemp,2);
                FDresp = rs-bl;

                app.EPcnt = app.EPcnt + 1;
                app.respSummary(app.EPcnt,1) = cellstr(app.file_in);  % 1: file name
                app.respSummary(app.EPcnt,2) = num2cell(i);               % 2: channel number
                app.respSummary(app.EPcnt,3) = num2cell(0);               % 3: trial
                app.respSummary(app.EPcnt,4) = num2cell(ii);              % 4: repeat

                app.respSummary(app.EPcnt,5) = num2cell(resp);            % 5: Peak response
                app.respSummary(app.EPcnt,6) = num2cell(tpeak);           % 6: time to peak
                app.respSummary(app.EPcnt,7) = num2cell(bl);              % 7: Baseline mean BP1 power
                app.respSummary(app.EPcnt,8) = num2cell(rs);              % 8: Response mean BP1 power
                app.respSummary(app.EPcnt,9) = num2cell(FDresp);          % 9: Delta BP1 power
%                handles.respSummary(handles.EPcnt,10) = num2cell(TemplateSPW);    % 10: Delta BP1 power                
                if ~isempty(app.expID)
                    app.respSummary(app.EPcnt,11) = cellstr(string(app.expID));   % 11: Patient name-notes
                    % leave column 11 empty
                end
            end
        end        
    end
end

app.outEvochedResponses.Data = app.respSummary;

    function gixout = gixres(b)
        % this nested function computes the residue of the difference
        % between the template and the given sweep.
        gixout = sum((segment(blDelta:end)-b*template(blDelta:end)).^2);
    end
end


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

    ntemp = 1; 
    app.meanSpgDeleaked = [];
    app.meanSpg = [];
    for i=1:app.nCh
        tmp = [];        % initialize tmp
        % create temporary matrix for average computation
        tmp (1:app.nTrials-trialBegins+1,1:app.dtaLen) = app.workLFP(i,trialBegins:app.nTrials,1:app.dtaLen);
        app.meanLFP (i,1:app.dtaLen) = mean (tmp,1);
        
        % compute mean of band-passed data
        % Gab: moved to "computeBPandNotch"
        
        % compute mean spectrogram
        tmp = [];
        if leakageFlag      %GAB: add plotting of deleaked mean spg.
            tmp (1:app.nTrials-trialBegins+1,1:app.freqN,1:app.spgl) = app.spgDeleaked(i,trialBegins:app.nTrials,1:app.freqN,1:app.spgl);
            app.meanSpgDeleaked (i,1:app.freqN,1:app.spgl) = mean (tmp,1);
        end
        tmp (1:app.nTrials-trialBegins+1,1:app.freqN,1:app.spgl) = app.spg(i,trialBegins:app.nTrials,1:app.freqN,1:app.spgl);
        app.meanSpg (i,1:app.freqN,1:app.spgl) = mean (tmp,1);

        % compute mean E/I index
        tmp = [];
        tmp(1:app.nTrials-trialBegins+1,1:app.spgl) = app.EIrat(i,trialBegins:app.nTrials,1:app.spgl);
        app.meanEIrat (i,1:app.spgl) = mean (tmp,1);    
        % compute mean 'gamma' power
        tmp = [];
        tmp(1:app.nTrials-trialBegins+1,1:app.spgl) = app.spgPlot(i,trialBegins:app.nTrials,1:app.spgl);
        app.meanSpgPlot (i,1:app.spgl) = mean (tmp,1);

        % the computation of the mean power spectra has been moved to the
        % ZebraSpectre.m file    
    end
end