function computeSpectrogram(app)

% Hello, my name is me and this is March 3, 2017
% This code computes the spectograms of all data.
% If so desired, the SPG is computed after removal of the (large) low
% frequency transients in order to attenuate the associated spectral
% leakage.

SPGfrom = app.SPGfromFreq.Value;
SPGto = app.SPGtoFreq.Value;
freqStep = app.SPGresolution.Value;
freq = SPGfrom:freqStep:SPGto;
app.freqN = (SPGto-SPGfrom)/freqStep + 1;
window = app.SPGwindow.Value;
noverlap = app.SPGoverlap.Value;
leakageFlag = app.leakageCk.Value;
app.spg=[];
for i = 1:app.nCh
    for j= 1:app.nTrials
        flag = app.decimateFlag.Value;
        if flag
            % decimate the input data in case of really long data set or
            % when using a slow pc...
            LFPsmall = decimate(app.workLFP(i,j,1:app.dtaLen),10);
            LFPsmall(i,j,1:app.dtaLen) = decimate(app.workLFP(i,j,1:app.dtaLen),10);
            [s, w, t, ps] = spectrogram(LFPsmall,hamming(window),noverlap, freq, app.acqF/10, 'yaxis');
            %t = t + app.timeOffset; %GAB 2019/02/24: offset added
        else
            tmp = app.workLFP(i,j,1:app.dtaLen);
            flagChronux = get(app.ChronuxCk,'Value');
            if flagChronux
                params.tapers = [3 5] ;%[10 0.5 1];
                params.Fs = app.acqF;
                params.fpass = [SPGfrom SPGto];
                [rollingWin, overlap] = setSPGwindow (app, app.dtaLen*app.sp);
                [ps, t, w] = mtspecgramc(tmp,[rollingWin overlap],params);
                l = size (ps);
                app.spgl = l(1);
                app.freqN = l(2);
                ps = ps';
                app.spg(i,j,1:app.freqN,1:app.spgl) = ps (1:app.freqN,1:app.spgl);
                if leakageFlag
                    % first: subtract the LP filtered data from the workLFP
                    % data. Second: compute its SPG
                    tmp = squeeze(app.workLFP(i,j,:))-squeeze(app.LPfiltLeakage(i,j,:));
                    [ps, t, w] = mtspecgramc(tmp,[rollingWin overlap],params);
                    ps = ps';
                    app.spgDeleaked(i,j,1:app.freqN,1:app.spgl) = ps (1:app.freqN,1:app.spgl);
                    app.deleakedFlag = 1;
                end
            else
                [s, w, t, ps] = spectrogram(tmp,hamming(window),noverlap, freq, app.acqF, 'yaxis');
                l = size (ps);
                app.spgl = l(2);
                app.spg(i,j,1:app.freqN,1:app.spgl) = ps (1:app.freqN,1:app.spgl);
                if leakageFlag
                    tmp = squeeze(app.workLFP(i,j,:))-squeeze(app.bandPassed_LFP(6,i,j,:));
                    [s, w, t, ps] = spectrogram(tmp,hamming(window),noverlap, freq, app.acqF, 'yaxis');
                    app.spgDeleaked(i,j,1:app.freqN,1:app.spgl) = ps (1:app.freqN,1:app.spgl);
                    app.deleakedFlag = 1;
                end
            end
        end
        % compute the short time E/I index
        % First: create the array containing the indexes of the spectral density in the interval 20-50 Hz
        [segmentI, segmentF, freqCnt] = findSPGelements (w, app.freqN, 20, 50);
        % Second: loop on all time point of the spg to compute the linear
        % fit to the spectra segment
        for ti=1:app.spgl
            spectraSegment = app.spg(i,j,segmentI(1):segmentI(freqCnt),ti);
            % compute now the linear fit to the log log segment
            segmentF = squeeze(segmentF);   % remove the singleton dimensions
            spectraSegment = squeeze(spectraSegment);
            % compute slope and offset of the fit
            %X = [ones(length(segmentF),1) segmentF'];
            X = [ones(length(segmentF),1) log(segmentF)'];
            fit = X\log(spectraSegment);
            app.EIrat (i,j,ti) = fit(2);
            % the linear regression operators '\' needs row vectors.
        end    
        % compute the integral of the SPG in 'gamma' band
        PWfrom = app.envSPGfrom.Value;
        PWto = app.envSPGto.Value;        
        [segmentI, segmentF, freqCnt] = findSPGelements (w, app.freqN, PWfrom, PWto);
        app.spgPlot(i,j,1:app.spgl) = sum(app.spg(i,j,segmentI(1):segmentI(freqCnt),1:app.spgl));
        if leakageFlag
            app.spgPlotDeleaked(i,j,1:app.spgl) = sum(app.spgDeleaked(i,j,segmentI(1):segmentI(freqCnt),1:app.spgl));            
        end    
    end    
end
app.spgt = t + app.timeOffset; %GAB 2019/02/24: offset added
app.spgw = w;

function [segmentI, segmentF, freqCnt] = findSPGelements (w, freqNum, lowFreq, highFreq)
% Given a frequency range (lowFreq and highFreq) identify the elements of
% the spectrogram that fall within this range. The function returns an array
% (freqIndex) containing the indexes of the elements, and an array
% containing the relative frequencies.

segmentI = [];
segmentF = [];

freqCnt = 0;
for fj=1:freqNum
    if w(fj)>highFreq      % interupt the iterations if we pass the frequency limit
        break
    end
    if w(fj)>=lowFreq
        freqCnt = freqCnt + 1;
        segmentI(freqCnt) = fj;
        segmentF(freqCnt) = w(fj);
    end
end   

function [wnd, ovl] = setSPGwindow (app, deltaT)
% This function reads (from GUI) or generates the values of window size and
% overlap to be used for the spectrogram computation.
% The automatic computation uses the width of the data to adapt the width
% of the rolling window.

flagAuto = app.ChronuxAutoConfigCk.Value;
if flagAuto
    if deltaT<5, wnd = 0.1;
    else
        if deltaT<10, wnd = 0.2;
        else
            if deltaT<30, wnd = 0.2;
            else
                if deltaT<100, wnd = 0.5;
                else
                    wnd = 0.5;
                end
            end
        end
    end
    ovl = wnd/5;
else
    wnd = app.ChronuxRW.Value;
    ovl = app.ChronuxOvl.Value;
end    
