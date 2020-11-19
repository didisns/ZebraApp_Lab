% refers to the 'compute' button            
app.evDet.upstates = struct('fromI',1,'fromT',1,'toI',1,'toT',1,'deltaT',1,'medianV',1,'SD',1,'pw',1,...
    'medianV_hem2', 1, 'SD_hem2', 1, 'pw_hem2', 1, 'enable',1);
app.evDet.downstates = struct('fromI',1,'fromT',1,'toI',1,'toT',1,'deltaT',1,'medianV',1,'SD',1,'pw',1,...
    'medianV_hem2', 1, 'SD_hem2', 1, 'pw_hem2', 1, 'enable',1);

app.evDet.SPG = [];
app.evDet.LFP = [];
app.evDet.LFP_hem2 = [];
app.evDet.timeSPG = [];
app.evDet.upstates.fromI = [];
app.evDet.upstates.toI = [];
app.evDet.downstates.fromI = [];
app.evDet.downstates.toI = [];
app.evDet.USlist = [];
app.evDet.USlist = {1 1 1 1 1 1 1 1 1 1};

% set the threshold for event detection based on the used method
if get(app.autoThr,'Value') % if autosetting state thresshold is clicked, automatically determine threshold
    lowThr = app.evDet.autoblThr; % this value is calculated later in analyzeData function based on power distribution!
    highThr = app.evDet.autoevThr; % this value is calculated later in analyzeData function based on power distribution!
else
    lowThr = get(app.baselineThr,'Value'); %otherwise, obtain user defined threshold values
    highThr = get(app.eventThr,'Value');
end

% Identify the data set to be analyzed
dataSource = NaN;
% Find the selected BP
selBP = find(strcmp(app.detectionBP_dropDown.Value,app.detectionBP_dropDown.Items));
if selBP < length(app.detectionBP_dropDown.Items)
    % selBP is not SPG envelope, which is always the last element
    if app.BPcomputed(selBP)
        dataSource = selBP;
    end
else 
    % SPG envelop is selected
    dataSource = 0;
end

if ~isnan(dataSource)
    ct = app.currentTrial;
    cCh = app.currentCh;
    len = app.dtaLen;
    spp = app.sp;
    logFlag = get(app.powerLogCk,'Value'); % if 'log of envelope power' is checked
    flagLeak = get (app.displayLeakCk,'Value');
    app.evDet.tmin = get(app.leftTime,'Value'); % time values entered by user in the bottom left box
    app.evDet.tmax = get(app.rightTime,'Value');

    app.evDet.LFP(1:len) = app.workLFP (cCh,ct,1:len);
    
    % Check if double hemisphere analysis is selected
    if app.doubleHemCheckBox.Value
        Ch_hem2 = app.otherHem.Value;
        app.evDet.LFP_hem2(1:len) = app.workLFP(Ch_hem2, ct, 1:len);
    end

    app.evDet.timeSPG = [];
    if dataSource == 0          % length of the spectral power file
        sl = app.spgl;
        app.evDet.timeSPG = app.spgt;
    else
        sl = length(app.BPpower(dataSource).time); % length of the vector power of band passed data
        app.evDet.timeSPG = app.BPpower(dataSource).time; % spectrogram data itself for current BP setting
    end

    % 2019/05/28 Gab. Rearranged and adapted to multiple BPs
    % and to the new structure of the variable BPpower
    if (app.deleakedFlag && flagLeak)
        % If we want the deleaked version of the spg
        app.evDet.SPG = [];
        app.evDet.SPG (1:sl) = app.spgPlotDeleaked(cCh,ct,1:sl);
    else
        if ~dataSource
            % SPG envelop is selected
            app.evDet.SPG = [];
            app.evDet.SPG (1:sl) = app.spgPlot(cCh,ct,1:sl);
        else
            % a BP is selected
            app.evDet.SPG = squeeze(app.BPpower(dataSource).power(cCh,ct,:));
        end
    end
    if logFlag
        app.evDet.SPG = log10(app.evDet.SPG);
    end

    downStatesBolean = app.evDet.SPG < lowThr; %logical array of SPG below threshold
    downStatesI = find(app.evDet.SPG< lowThr); % indexes of SPG where it is below threshold (i.e. is downstate)
    upStatesBolean = app.evDet.SPG > highThr; % same for up states (above threshold)
    upStatesI = find(app.evDet.SPG>highThr);
    limboBolean = ~(downStatesBolean | upStatesBolean); % I don't understand this, it seems to create an empty logical array

    % now the vector app.evDet.SPGt (downstatesBolean) contains the timing of the
    % upstates. This has to be converted to the indexes of the workLFP file

    lus = length (upStatesI);
    lds = length (downStatesI);

    % process upstates first
    if lus>0
        firstI = upStatesI (1);
        firstTime = app.evDet.timeSPG (firstI);
        app.evDet.upstates.fromT (1) = firstTime;
        app.evDet.upstates.fromI (1) = 1+firstTime/spp; % spp is the sampling period, this converts the time to the LFP index
        nus = 1; % keeps track of the number of up states
        for i=2:lus
            nextI = upStatesI(i); % loop through all the indexes with higher than threshold value
            if nextI==firstI+1
                % continue the old US
                firstI=nextI;
                if i == lus
                    % we have reached the end of the track. close the US
                    endTime = app.evDet.timeSPG (firstI);
                    app.evDet.upstates.toT (nus) = endTime;
                    app.evDet.upstates.toI (nus) = int32(1+endTime/spp);
                    app.evDet.upstates.deltaT (nus) = endTime-app.evDet.upstates.fromT (nus);
                    app.evDet.upstates.enable (nus) = 1;
                end
            else
                firstTime = app.evDet.timeSPG (firstI);
                % beginning of a new US. Close the old US
                app.evDet.upstates.toT (nus) = firstTime;
                app.evDet.upstates.toI (nus) = int32(1+firstTime/spp);
                app.evDet.upstates.deltaT (nus) = firstTime-app.evDet.upstates.fromT (nus);
                app.evDet.upstates.enable (nus) = 1;
                nus = nus + 1;
                % open new US
                app.evDet.upstates.fromT (nus) = app.evDet.timeSPG (nextI);
                app.evDet.upstates.fromI (nus) =  int32(1+app.evDet.timeSPG (nextI)/spp);
                firstI = nextI;
            end
        end
    end

    nus = length (app.evDet.upstates.toI);      % just to make sure...

    % process downstates
    if nus>0
        firstI = downStatesI (1);
        firstTime = app.evDet.timeSPG (firstI);
        app.evDet.downstates.fromT (1) = firstTime;
        app.evDet.downstates.fromI (1) = 1+firstTime/spp;
        nds = 1;

        for i=2:lds
            nextI = downStatesI(i);
            if nextI==firstI+1
                % continue the old DS
                firstI=nextI;
                 if i == lds
                      % we have reached the end of the track. close the DS
                      endTime = app.evDet.timeSPG (firstI);
                      app.evDet.downstates.toT (nds) = endTime;
                      app.evDet.downstates.toI (nds) = int32(1+endTime/spp);
                      app.evDet.downstates.deltaT (nds) = endTime-app.evDet.downstates.fromT (nds);
                      app.evDet.downstates.enable (nds) = 1;
                 end
            else
                firstTime = app.evDet.timeSPG (firstI);
                % beginning of a new DS. Close the old DS
                app.evDet.downstates.toT (nds) = firstTime;
                app.evDet.downstates.toI (nds) = int32(1+firstTime/spp);
                app.evDet.downstates.deltaT (nds) = firstTime-app.evDet.downstates.fromT (nds);
                app.evDet.downstates.enable (nds) = 1;
                nds = nds + 1;
                % open new DS
                app.evDet.downstates.fromT (nds) = app.evDet.timeSPG (nextI);
                app.evDet.downstates.fromI (nds) =  int32(1+app.evDet.timeSPG (nextI)/spp);
                firstI = nextI;
            end
        end
    end
    nds = length(app.evDet.downstates.toI);


    % defragment DS and US across short state gap. The max size of the filled
    % gap is defined in the GUI
    % These are the rules: a brief interruption shorter than maxInterruption is
    % filled in by assigning to the neighboring US that are fused in a longer
    % one. Isolated US briefer than minDuration are attributed to the limbo.

    maxGap = get(app.maxInterruption,'Value');
    minUS = get(app.minDuration,'Value');

    if get(app.removeCk,'Value') %if the remove state interruptions button is clicked
        % process US first
        usi = 2;
        while usi <= nus % there must be at least two up states to do this operation, loop through from 2 till nus
            % perform the fusions first since brief US might get fused together
            % to form a longer and legal US.
            interval = [app.evDet.upstates.fromT(usi) app.evDet.upstates.toT(usi-1)];
            distance = interval(1) - interval(2);
            if (distance<=maxGap)
                % first fuse the two upstates
                app.evDet.upstates.toT(usi-1) = app.evDet.upstates.toT(usi);
                app.evDet.upstates.toI(usi-1) = app.evDet.upstates.toI(usi);
                app.evDet.upstates.deltaT(usi-1) = app.evDet.upstates.toT(usi-1) - app.evDet.upstates.fromT(usi-1);
                % second remove the US pointed to by usi
                for k = usi:nus-1
                    % shift all USs
                    app.evDet.upstates.toT(k) = app.evDet.upstates.toT(k+1);
                    app.evDet.upstates.toI(k) = app.evDet.upstates.toI(k+1);
                    app.evDet.upstates.fromT(k) = app.evDet.upstates.fromT(k+1);
                    app.evDet.upstates.fromI(k) = app.evDet.upstates.fromI(k+1);
                    app.evDet.upstates.deltaT(k) = app.evDet.upstates.deltaT (k+1);
                end
                nus = nus - 1;
            else
                usi = usi+1;
            end
        end
        % remove brief states
        for usi=1:nus
            if app.evDet.upstates.deltaT(usi) <= minUS, app.evDet.upstates.enable(usi) = 0;
            end
        end
        % remove the disabled states from the list
        cnt = nus;
        for usi=nus:-1:1
            if app.evDet.upstates.enable(usi)
                % do nothing
            else
                cnt = cnt - 1;
                % shift down if the US is not the last one of the track
                if usi < nus
                    app.evDet.upstates.fromI (cnt:-1:usi) = app.evDet.upstates.fromI (cnt+1:-1:usi+1);
                    app.evDet.upstates.toI (cnt:-1:usi) = app.evDet.upstates.toI (cnt+1:-1:usi+1);
                    app.evDet.upstates.fromT (cnt:-1:usi) = app.evDet.upstates.fromT (cnt+1:-1:usi+1);
                    app.evDet.upstates.toT (cnt:-1:usi) = app.evDet.upstates.toT (cnt+1:-1:usi+1);
                    app.evDet.upstates.deltaT (cnt:-1:usi) = app.evDet.upstates.deltaT (cnt+1:-1:usi+1);
                    app.evDet.upstates.enable (cnt:-1:usi) = app.evDet.upstates.enable (cnt+1:-1:usi+1);
                end
            end
        end
        nus = cnt;

        % process DS
        for usi=2:nds
            interval = [app.evDet.downstates.fromT(usi) app.evDet.downstates.toT(usi-1)];
            distance = interval(1) - interval(2);
            if (distance<=maxGap)
                % fuse the contiguous downstates
                app.evDet.downstates.toT(usi-1) = app.evDet.downstates.toT(usi);
                app.evDet.downstates.toI(usi-1) = app.evDet.downstates.toI(usi);
                app.evDet.downstates.deltaT(usi-1) = app.evDet.downstates.toT(usi-1) - app.evDet.downstates.fromT(usi-1);
                app.evDet.downstates.enable(usi) = 0;
            end
        end

        for usi=1:nds
            if app.evDet.downstates.deltaT(usi) <= minUS, app.evDet.downstates.enable(usi) = 0;
            end
        end

        cnt = nds;
        for usi=nds:-1:1
            if app.evDet.downstates.enable(usi)
                % do nothing
            else
                cnt = cnt - 1;
                % shift down
                if usi < nds
                    app.evDet.downstates.fromI (cnt:-1:usi) = app.evDet.downstates.fromI (cnt+1:-1:usi+1);
                    app.evDet.downstates.toI (cnt:-1:usi) = app.evDet.downstates.toI (cnt+1:-1:usi+1);
                    app.evDet.downstates.fromT (cnt:-1:usi) = app.evDet.downstates.fromT (cnt+1:-1:usi+1);
                    app.evDet.downstates.toT (cnt:-1:usi) = app.evDet.downstates.toT (cnt+1:-1:usi+1);
                    app.evDet.downstates.deltaT (cnt:-1:usi) = app.evDet.downstates.deltaT (cnt+1:-1:usi+1);
                    app.evDet.downstates.enable (cnt:-1:usi) = app.evDet.downstates.enable (cnt+1:-1:usi+1);
                end
            end
        end
        nds = cnt;
    end


    % refine the edges of the state detection. Experimental and not great
    % not to be used as of March 22, 2017
    refineEdges (app);

    % At this stage all US and DS have been extracted and we can compute the
    % relative metrics.
    % Compute median, PW and SD of each US and DS.
    for usi=1:nds   % compute DS first since you need this to compute US size
       i1 = app.evDet.downstates.fromI(usi);
       i2 = app.evDet.downstates.toI(usi);
       app.evDet.downstates.medianV(usi) = median(app.evDet.LFP(i1:i2));
       app.evDet.downstates.SD(usi) = std(app.evDet.LFP(i1:i2));
       app.evDet.downstates.pw(usi) = rms(app.evDet.LFP(i1:i2));
       if app.nCh == 2
           app.evDet.downstates.medianV_hem2(usi) = median(app.evDet.LFP_hem2(i1:i2));
           app.evDet.downstates.SD_hem2(usi) = std(app.evDet.LFP_hem2(i1:i2));
           app.evDet.downstates.pw_hem2(usi) = rms(app.evDet.LFP_hem2(i1:i2));
       end
    end

    DSsearch = 1;
    dsi1 = app.evDet.downstates.fromI(DSsearch);
    dsi2 = app.evDet.downstates.toI(DSsearch);
    for usi=1:nus
       i1 = app.evDet.upstates.fromI(usi);
       i2 = app.evDet.upstates.toI(usi);
       app.evDet.upstates.medianV(usi) = median(app.evDet.LFP(i1:i2));
       app.evDet.upstates.SD(usi) = std(app.evDet.LFP(i1:i2));
       app.evDet.upstates.pw(usi) = rms(app.evDet.LFP(i1:i2));
       if app.nCh == 2
           app.evDet.upstates.medianV_hem2(usi) = median(app.evDet.LFP_hem2(i1:i2));
           app.evDet.upstates.SD_hem2(usi) = std(app.evDet.LFP_hem2(i1:i2));
           app.evDet.upstates.pw_hem2(usi) = rms(app.evDet.LFP_hem2(i1:i2));
       end
       % now search for the closest DS
       while dsi2 < i1 && DSsearch <= nds % while the end of the downstate is smaller than the start of the current up
           % state and smaller than the number of down states
           DSsearch = DSsearch + 1; % it will increase by one: we found the down state following the current up state
           if DSsearch <= nds
               dsi2 = app.evDet.downstates.toI(DSsearch);
           end
       end
       % now DSsearch points to the DS immediatey after unless the data ends
       % with a US. A second exception is when the data starts with an US
       if DSsearch == 1     % data begins with US
           baseline = app.evDet.downstates.medianV(1);
           if app.nCh == 2
               baseline_hem2 = app.evDet.downstates.medianV_hem2(1);
           end
       else
           if DSsearch > nds    % data ends up with a US
               baseline = app.evDet.downstates.medianV(nds);
               if app.nCh == 2
                   baseline_hem2 = app.evDet.downstates.medianV_hem2(nds);
               end
           else
               % OK, this is a middle of the road US!
               baseline = (app.evDet.downstates.medianV(DSsearch)+app.evDet.downstates.medianV(DSsearch-1))/2;
               if app.nCh == 2
                   baseline_hem2 = (app.evDet.downstates.medianV_hem2(DSsearch)+app.evDet.downstates.medianV_hem2(DSsearch-1))/2;
               end
           end
       end
       % this is added by Didi, in order to access the value later, so that
       % I can add a downward going filter
       if app.removePosUSCheckBox.Value
           newmedianV(usi) = app.evDet.upstates.medianV(usi) - baseline;
           if app.nCh == 2
                newmedianV_hem2(usi) = app.evDet.upstates.medianV_hem2(usi) - baseline_hem2;
           end
       end
    end

    % This part is added by Didi in November, 2018. Meant to remove
    % upstates from the list that have a positive medianV (i.e. that are
    % just artefacts)
    if app.removePosUSCheckBox.Value
        for us = 1:nus
           i1 = app.evDet.upstates.fromI(us);
           i2 = app.evDet.upstates.toI(us);
            if newmedianV(us) > 0
                app.evDet.upstates.enable(us) = 0;
            end
        end

        % now remove the disabled up states from the list as was done above
        cnt = nus;
        for usi=nus:-1:1
            if app.evDet.upstates.enable(usi)
            % do nothing
            else
                cnt = cnt - 1;
                % shift down if the US is not the last one of the track
                if usi < nus
                    app.evDet.upstates.fromI (cnt:-1:usi) = app.evDet.upstates.fromI (cnt+1:-1:usi+1);
                    app.evDet.upstates.toI (cnt:-1:usi) = app.evDet.upstates.toI (cnt+1:-1:usi+1);
                    app.evDet.upstates.fromT (cnt:-1:usi) = app.evDet.upstates.fromT (cnt+1:-1:usi+1);
                    app.evDet.upstates.toT (cnt:-1:usi) = app.evDet.upstates.toT (cnt+1:-1:usi+1);
                    app.evDet.upstates.deltaT (cnt:-1:usi) = app.evDet.upstates.deltaT (cnt+1:-1:usi+1);
                    app.evDet.upstates.enable (cnt:-1:usi) = app.evDet.upstates.enable (cnt+1:-1:usi+1);
                    app.evDet.upstates.medianV(cnt:-1:usi) = app.evDet.upstates.medianV(cnt+1:-1:usi+1);
                    newmedianV(cnt:-1:usi) = newmedianV(cnt+1:-1:usi+1);
                    app.evDet.upstates.SD(cnt:-1:usi) = app.evDet.upstates.SD(cnt+1:-1:usi+1);
                    app.evDet.upstates.pw(cnt:-1:usi) = app.evDet.upstates.pw(cnt+1:-1:usi+1);
                    if app.nCh == 2
                        app.evDet.upstates.medianV_hem2(cnt:-1:usi) = app.evDet.upstates.medianV_hem2(cnt+1:-1:usi+1);
                        newmedianV_hem2(cnt:-1:usi) = newmedianV_hem2(cnt+1:-1:usi+1);
                        app.evDet.upstates.SD_hem2(cnt:-1:usi) = app.evDet.upstates.SD_hem2(cnt+1:-1:usi+1);
                        app.evDet.upstates.pw_hem2(cnt:-1:usi) = app.evDet.upstates.pw_hem2(cnt+1:-1:usi+1);
                    end
                end
            end
        end
        nus = cnt;
    end
    
    app.evDet.NUS = nus;
    app.evDet.NDS = nds;

    % now create the list
    for usi = 1:nus
       app.evDet.USlist (usi,5) = num2cell(newmedianV(usi));
       app.evDet.USlist (usi,6) = num2cell(app.evDet.upstates.SD(usi));
       app.evDet.USlist (usi,7) = num2cell(app.evDet.upstates.pw(usi));
       if app.nCh == 2
           app.evDet.USlist (usi,8) = num2cell(newmedianV_hem2(usi));
           app.evDet.USlist (usi,9) = num2cell(app.evDet.upstates.SD_hem2(usi));
           app.evDet.USlist (usi,10) = num2cell(app.evDet.upstates.pw_hem2(usi));
       end
    end

    % Creation of the list of USs
    %app.evDet.USlist (1,1) = num2cell(1);
    %app.evDet.USlist (1,2) = num2cell(app.evDet.upstates.fromT(1));
    app.evDet.USlist (1:nus,1) = num2cell(1:nus); % the first cell contains the up state number
    app.evDet.USlist (1:nus,2) = num2cell(app.evDet.upstates.fromT(1:nus)); % the second cell contains the start
    % time of the corresponding up state
    app.evDet.USlist (1:nus,3) = num2cell(app.evDet.upstates.toT(1:nus)); % then the end time
    app.evDet.USlist (1:nus,4) = num2cell(app.evDet.upstates.toT(1:nus) - app.evDet.upstates.fromT(1:nus)); % and the length of the up state


                    % Didi February 2019: Add Number of Multipeak Waves for both hemispheres. Based on the set of three papers Tononi lab: Sleep Homeostasis 
    % and Cortical Synchronization. This analysis is going to use the Band Passed filter data in the BP1 range. Here, an up state is represented
    % as a negative deflection of the signal. Multipeak waves are defined as waves with more than 1 negative peak between 2 zero crossings. So 
    % here, I took the BP1 filtered LFP from the start till the end of each up state and used the findpeaks function of matlabs Signal Processing
    % Toolbox to find negative peak number of both hemispheres.
    if app.multiPeakWavesCheckBoxValue
    %                 Gab 2019/05/28: from now on BPs are not fixed, so it is necessaty to choose the desired BP for this
    %                 analysis. I added a spinnder button for this, it is called app.detectionBPmultiPeak_dropDown.
        multiPeakBP = app.detectionBPmultiPeak_spinner.Value;


        % start by setting up the parameters to find multipeaks of the current hemispere
        multipeak = zeros(app.evDet.NUS, 1);
        deltaBP(1:app.dtaLen) = app.bandPassed_LFP(multiPeakBP,app.currentCh, app.currentTrial, 1:app.dtaLen);

        % Now start looping through the up states and find peaks
        for usn = 1:app.evDet.NUS
            cnt = 0;
            start = app.evDet.upstates.fromI(usn);
            stop = app.evDet.upstates.toI(usn);
            pks = findpeaks(-deltaBP(start:stop));
            if isempty(pks)
                cnt = 0;
            else
            cnt = length(pks);
            end
            multipeak(usn) = cnt;
        end                

        % same to find peaks of other hemisphere
        if app.doubleHemCheckBox.Value
            multipeak_hem2 = zeros(app.evDet.NUS, 1);
            deltaBP_hem2(1:app.dtaLen) = app.bandPassed_LFP(multiPeakBP,Ch_hem2, app.currentTrial, 1:app.dtaLen);
            for usn2 = 1:app.evDet.NUS
                cnt2 = 0;
                start2 = app.evDet.upstates.fromI(usn2);
                stop2 = app.evDet.upstates.toI(usn2);
                pks2 = findpeaks(-deltaBP_hem2(start2:stop2));
                if isempty(pks2)
                    cnt2 = 0;
                else
                    cnt2 = length(pks2);
                end
            multipeak_hem2(usn2) = cnt2;
            end 
        end
    end
   % End of the finding of multipeak waves. 

   if app.USslopes_ck.Value
       % Didi February 2019: Finding slopes of the slow waves. Based on the set of three papers Tononi lab: Sleep Homeostasis and Cortical 
       % Synchronization. Here, we take the 0.5-4 Hz (BP1) filtered LFP, where an up state is represented as a negative delfection. We define
       % both the average slope, and the maximum slope of the first and second segment of both hemispheres. Average slope is defined as the 
       % amplitude of the most negative peak, divided by the time of the previous zero crossing till the peak (for the first segment) or from 
       % the peak till the next zero crossing (for the second segment). Maximum slopes were defined as the maximum of the signal derivative 
       % (after applying a 1 millisecond moving average) following the negative zero crossing (first-segment slope) but before the most negative
       % peak, or subsequent to the most negative peak (second-segment slope) but prior to the positive-going zero crossing.

       % Start with the current channel (hemisphere)             


       % Set the parameters               
       avslopesegment1 = zeros(app.evDet.NUS, 1);
       maxslopesegment1 = zeros(app.evDet.NUS, 1);                              
       avslopesegment2 = zeros(app.evDet.NUS, 1);
       maxslopesegment2 = zeros(app.evDet.NUS, 1);              
       deltaBP(1:app.dtaLen) = app.bandPassed_LFP(multiPeakBP,app.currentCh, app.currentTrial, 1:app.dtaLen);

       % start looping through all the up states
       for usn = 1:app.evDet.NUS                    
            st = app.evDet.upstates.fromI(usn);
            en = app.evDet.upstates.toI(usn);
            [pks, loc] = findpeaks(-deltaBP(st:en)); % pks contains the amplitude of the peaks, loc contains the index of the peaks
            if isempty(pks) % if there are no peaks, the average and max slopes are 0
                avslopesegment1(usn) = 0;
                maxslopesegment1(usn) = 0;
                avslopesegment2(usn) = 0;
                maxslopesegment2(usn) = 0;
            else
                [mx, indexmx] = max(pks); % indexmx now contains contains the index of pks and loc with the largest peak
                locmx = loc(indexmx)+(st-1); % locmx now contains the index of the most negative peak

                % first find first segment
                posfirst = find(deltaBP(st:locmx)>=0)+(st-1); % contains all the indexes of delta BP higher than 0 before the most negative peak
                if isempty(posfirst) % if there are no values above 0, we take the max value of the BP1 LFP
                    [zero1, Izero1] = max(deltaBP(st:locmx));
                    Izerocrossing1 = Izero1+(st-1);
                    timezerocrossing1 = Izerocrossing1*spp;
                    Ipeaktozerocrossing1 = locmx-Izerocrossing1;
                    timepeaktozerocrossing1 = Ipeaktozerocrossing1*spp;  
                else                  
                    distance1 = locmx-posfirst;
                    Ipeaktozerocrossing1 = min(distance1);
                    timepeaktozerocrossing1 = Ipeaktozerocrossing1*spp;
                    Izerocrossing1 = locmx-min(distance1);
                    timezerocrossing1 = Izerocrossing1*spp;
                end
                avslopesegment1(usn) = (-pks(indexmx)-deltaBP(Izerocrossing1))/timepeaktozerocrossing1;

                % same for the second segment
                possecond = find(deltaBP(locmx:en)>=0)+(locmx-1); % contains all the indexes of delta BP higher than 0 after the most negative peak
                if isempty(possecond) % if there are no values above 0, we take the max value of the BP1 LFP
                    [zero2, Izero2] = max(deltaBP(locmx:en));
                    Izerocrossing2 = Izero2+(locmx-1);
                    timezerocrossing2 = Izerocrossing2*spp;
                    Ipeaktozerocrossing2 = Izerocrossing2-locmx;
                    timepeaktozerocrossing2 = Ipeaktozerocrossing2*spp;  
                else                  
                    distance2 = possecond-locmx;
                    Ipeaktozerocrossing2 = min(distance2);
                    timepeaktozerocrossing2 = Ipeaktozerocrossing2*spp;
                    Izerocrossing2 = locmx+min(distance2);
                    timezerocrossing2 = Izerocrossing2*spp;
                end
                avslopesegment2(usn) = (deltaBP(Izerocrossing2)+pks(indexmx))/timepeaktozerocrossing2;                        

                % then we need to find the max slope. I want to have a moving (non-overlapping) average of 1 ms steps
                stepT = 1e-3; % so the time step is 1 ms
                stepI = stepT/spp; % then the step size in index number is this
                dervector1 = [];
                dervector2 = [];

                % First segment 1
                cnt1 = 1; %set a count value that keeps track of each new time step
                for ind1 = Izerocrossing1+stepI:stepI:locmx
                    av1 = mean(deltaBP(ind1-stepI:ind1));
                    dervector1(cnt1) = av1;
                    cnt1 = cnt1+1;
                end
                % Now dervector contains the average delta power of 1 ms periods
                derivative1 = diff(dervector1)./stepT; % diff finds the difference between all the points in the input data (so if input data is
                % is x, diffX) = x(2)-x(1), x(3)-x(2), etc. of length x-1. So if we divide this by the time step between x(2) and x(1), in our case stepT
                % we found the derivative 
                if isempty(derivative1)
                    maxslopesegment1(usn) = 0;
                else
                    maxslopesegment1(usn) = min(derivative1); % minimun since negative slope so it should be below 0
                end

                % Then for the second segment
                cnt2 = 1; %set a count value that keeps track of each new time step
                for ind2 = locmx+stepI:stepI:Izerocrossing2
                    av2 = mean(deltaBP(ind2-stepI:ind2));
                    dervector2(cnt2) = av2;
                    cnt2 = cnt2+1;
                end
                % Now dervector contains the average delta power of 1 ms periods
                derivative2 = diff(dervector2)./stepT; % diff finds the difference between all the points in the input data (so if input data is
                % is x, diffX) = x(2)-x(1), x(3)-x(2), etc. of length x-1. So if we divide this by the time step between x(2) and x(1), in our case stepT
                % we found the derivative
                if isempty(derivative2)
                    maxslopesegment2(usn) = 0;
                else
                    maxslopesegment2(usn) = max(derivative2); % maximum since positive slope so it should be above 0
                end
            end
        end 

        % Now the the other hemisphere
        if app.multiPeakWavesCheckBoxValue
            % Set parameters
            avslopesegment1_hem2 = zeros(app.evDet.NUS, 1);
            maxslopesegment1_hem2 = zeros(app.evDet.NUS, 1);                              
            avslopesegment2_hem2 = zeros(app.evDet.NUS, 1);
            maxslopesegment2_hem2 = zeros(app.evDet.NUS, 1);              
            deltaBP_hem2(1:app.dtaLen) = app.bandPassed_LFP(multiPeakBP, Ch_hem2, app.currentTrial, 1:app.dtaLen);


            % start looping through all the up states
            for usn = 1:app.evDet.NUS                    
                st = app.evDet.upstates.fromI(usn);
                en = app.evDet.upstates.toI(usn);
                [pks, loc] = findpeaks(-deltaBP_hem2(st:en)); 
                if isempty(pks) 
                    avslopesegment1_hem2(usn) = 0;
                    maxslopesegment1_hem2(usn) = 0;
                    avslopesegment2_hem2(usn) = 0;
                    maxslopesegment2_hem2(usn) = 0;
                else
                    [mx, indexmx] = max(pks); 
                    locmx = loc(indexmx)+(st-1); 

                    % first find first segment
                    posfirst = find(deltaBP_hem2(st:locmx)>=0)+(st-1); 
                    if isempty(posfirst) 
                         [zero1, Izero1] = max(deltaBP_hem2(st:locmx));
                         Izerocrossing1 = Izero1+(st-1);
                         timezerocrossing1 = Izerocrossing1*spp;
                         Ipeaktozerocrossing1 = locmx-Izerocrossing1;
                         timepeaktozerocrossing1 = Ipeaktozerocrossing1*spp;  
                    else                  
                         distance1 = locmx-posfirst;
                         Ipeaktozerocrossing1 = min(distance1);
                         timepeaktozerocrossing1 = Ipeaktozerocrossing1*spp;
                         Izerocrossing1 = locmx-min(distance1);
                         timezerocrossing1 = Izerocrossing1*spp;
                    end
                    avslopesegment1_hem2(usn) = (-pks(indexmx)-deltaBP_hem2(Izerocrossing1))/timepeaktozerocrossing1;

                    % same for the second segment
                    possecond = find(deltaBP_hem2(locmx:en)>=0)+(locmx-1); 
                    if isempty(possecond) 
                        [zero2, Izero2] = max(deltaBP_hem2(locmx:en));
                        Izerocrossing2 = Izero2+(locmx-1);
                        timezerocrossing2 = Izerocrossing2*spp;
                        Ipeaktozerocrossing2 = Izerocrossing2-locmx;
                        timepeaktozerocrossing2 = Ipeaktozerocrossing2*spp;  
                    else                  
                        distance2 = possecond-locmx;
                        Ipeaktozerocrossing2 = min(distance2);
                        timepeaktozerocrossing2 = Ipeaktozerocrossing2*spp;
                        Izerocrossing2 = locmx+min(distance2);
                        timezerocrossing2 = Izerocrossing2*spp;
                    end
                    avslopesegment2_hem2(usn) = (deltaBP_hem2(Izerocrossing2)+pks(indexmx))/timepeaktozerocrossing2;                        

                    % then we need to find the max slope. I want to have a moving (non-overlapping) average of 1 ms steps
                    stepT = 1e-3; % so the time step is 1 ms
                    stepI = stepT/spp; % then the step size in index number is this
                    dervector1_hem2 = [];
                    dervector2_hem2 = [];

                    % First segment 1
                    cnt1 = 1; 
                    for ind1 = Izerocrossing1+stepI:stepI:locmx
                        av1 = mean(deltaBP_hem2(ind1-stepI:ind1));
                        dervector1_hem2(cnt1) = av1;
                        cnt1 = cnt1+1;
                    end
                    derivative1_hem2 = diff(dervector1_hem2)./stepT;
                    if isempty(derivative1_hem2)
                         maxslopesegment1_hem2(usn) = 0;
                    else
                         maxslopesegment1_hem2(usn) = min(derivative1_hem2); 
                    end

                    % Then for the second segment
                    cnt2 = 1; 
                    for ind2 = locmx+stepI:stepI:Izerocrossing2
                        av2 = mean(deltaBP_hem2(ind2-stepI:ind2));
                        dervector2_hem2(cnt2) = av2;
                        cnt2 = cnt2+1;
                    end                        
                    derivative2_hem2 = diff(dervector2_hem2)./stepT;
                    if isempty(derivative2_hem2)
                        maxslopesegment2_hem2(usn) = 0;
                    else
                        maxslopesegment2_hem2(usn) = max(derivative2_hem2); 
                    end
                end
            end
        end   

        % Didi February 2019: Add the number of peaks of the up state and the slopes to the US table

        for usi = 1:app.evDet.NUS
           app.evDet.USlist (usi,11) = num2cell(multipeak(usi));
           app.evDet.USlist (usi,13) = num2cell(avslopesegment1(usi));
           app.evDet.USlist (usi,14) = num2cell(maxslopesegment1(usi));
           app.evDet.USlist (usi,15) = num2cell(avslopesegment2(usi));
           app.evDet.USlist (usi,16) = num2cell(maxslopesegment2(usi));
           if app.multiPeakWavesCheckBoxValue
               app.evDet.USlist (usi,12) = num2cell(multipeak_hem2(usi)); 
               app.evDet.USlist (usi,17) = num2cell(avslopesegment1_hem2(usi));
               app.evDet.USlist (usi,18) = num2cell(maxslopesegment1_hem2(usi));
               app.evDet.USlist (usi,19) = num2cell(avslopesegment2_hem2(usi));
               app.evDet.USlist (usi,20) = num2cell(maxslopesegment2_hem2(usi));
           end
        end
    end
    



    % Add the up state info to the table in the GUI
    set(app.UStable,'Data',app.evDet.USlist);

    % plot the state IDs
    plotStatesFun (app)

    % create the joined files
    app.evDet.US = [];
    app.evDet.DS = [];

    ifrom = app.evDet.upstates.fromI(1);
    ito = app.evDet.upstates.toI(1);
    app.evDet.US = app.evDet.LFP(ifrom:ito);

    for usi=2:nus
        ifrom = app.evDet.upstates.fromI(usi);
        ito = app.evDet.upstates.toI(usi);
        if get(app.joinOffsetChk,'Value')
            offset = app.evDet.LFP(ifrom)-app.evDet.US(end);
            app.evDet.US = [app.evDet.US app.evDet.LFP(ifrom:ito)-offset];
        end
        if get(app.joinCk,'Value'), app.evDet.US = [app.evDet.US tempData(ifrom:ito)];
        end
    end

    for usi=1:nds
        ifrom = app.evDet.downstates.fromI(usi);
        ito = app.evDet.downstates.toI(usi);
        if get(app.joinOffsetChk,'Value') %Gab
            if ~isempty(app.evDet.DS) %Gab
                offset = app.evDet.LFP(ifrom)-app.evDet.DS(end); %Gab
                app.evDet.DS = [app.evDet.DS app.evDet.LFP(ifrom:ito)-offset];    %Gab
            else %Gab
                app.evDet.DS = [app.evDet.DS app.evDet.LFP(ifrom:ito)]; %Gab
            end %Gab
        else %Gab
        app.evDet.DS = [app.evDet.DS app.evDet.LFP(ifrom:ito)];
        end
    end

    % and finally lets compute the power spectra!
    if app.computePwsCheckBox.Value
        app.params = struct('tapers',[],'Fs',1,'fpass',[]);

        flagChronux = get(app.ChronuxCk,'Value');
        if flagChronux
            params.tapers = [5 9] ;%[5 9];
            params.Fs = app.acqF;
            params.fpass = [0 1000];
            [app.evDet.pssUS,app.evDet.fUS] = mtspectrumc(app.evDet.US, params);
            app.evDet.fUS = app.evDet.fUS';
            [app.evDet.pssDS,app.evDet.fDS] = mtspectrumc(app.evDet.DS, params);
            app.evDet.fDS = app.evDet.fDS';
        else
            [app.evDet.pssUS,app.evDet.fUS] = pwelch(app.evDet.US,[],[],[],app.acqF);
            [app.evDet.pssDS,app.evDet.fDS] = pwelch(app.evDet.DS,[],[],[],app.acqF);
        end
        %lUS = size(app.evDet.fUS);
        %lDS = size(app.evDet.fDS);

    %                 axes(app.powerSpectra);
    %                 hold on;
    %                 lim = axis;
    %                 cla
        cla(app.powerSpectra);
        lim = [app.powerSpectra.XLim, app.powerSpectra.YLim];

        %flagN = get(app.spectreData.normSpectraCk,'Value');
        % plot the mean traces
        plot(app.powerSpectra,app.evDet.fUS,10*log10(app.evDet.pssUS.'),'red');            % spectra in decibels
        plot(app.powerSpectra,app.evDet.fDS,10*log10(app.evDet.pssDS.'),'green');

        lim(1) = get(app.minFreq,'Value');
        lim(2) = get(app.maxFreq,'Value');
        lim(3) = get(app.minPw,'Value');
        lim(4) = get(app.maxPw,'Value');
        %axis (lim);
        app.powerSpectra.XLim = [lim(1) lim(2)];
        app.powerSpectra.YLim = [lim(3) lim(4)];

        set(app.powerSpectra,'XScale','log');
        app.powerSpectra.XLabel.String = 'Frequency (Hz)';
        app.powerSpectra.YLabel.String ='Magnitude (dB)';
    end
    
    if app.expTracesCheckBox.Value
        exportUStraces(app)
    end
else
    errStr = [app.detectionBP_dropDown.Value ' is not a valid source.'];
    error(errStr)

    disp('Computation Up/Down states finished');
end
