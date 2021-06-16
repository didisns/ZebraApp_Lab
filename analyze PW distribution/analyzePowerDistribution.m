
function analyzePowerDistribution(hObject, handles)

% June 14, 2017
% This function computes the distribution of the log of the spectral power in the BP
% data an in the HP data. The code identifies the peak of the main mode
% distributions and create a new population that consists of the data on
% the left of the main mode peak and of its mirror reflection. Then a
% gaussian fit is fitted to this data and it is subtrated from the original
% distribution.

% This procedure extracts the episodes of high activity that falls out of the 
% basal noise. Finally, the overall power in these event is computed and placed in the output.

% In line of principle each histo has its own optimal range and bin number.
% These must be entered in the analyzePWdistribution figure
% Initialize arrays and structures

handles.distLogPW = [];
handles.mainModeMean = [];
handles.mainModeAmp = [];
handles.mainModeStd = [];
handles.mainModeModel = [];

handles.nelements = [];
handles.centers = [];
handles.freqPW = [];
handles.secondaryMode = [];

% read histo limits and bin number for the band passed data

handles.distFrom (1) = str2double(get(handles.analyzePWdata.BP1from,'String'));
handles.distTo (1) = str2double(get(handles.analyzePWdata.BP1to,'String'));
handles.distBins (1) = str2double(get(handles.analyzePWdata.BP1bins,'String'));

handles.distFrom (2) = str2double(get(handles.analyzePWdata.BP2from,'String'));
handles.distTo (2) = str2double(get(handles.analyzePWdata.BP2to,'String'));
handles.distBins (2) = str2double(get(handles.analyzePWdata.BP2bins,'String'));

handles.distFrom (3) = str2double(get(handles.analyzePWdata.BP3from,'String'));
handles.distTo (3) = str2double(get(handles.analyzePWdata.BP3to,'String'));
handles.distBins (3) = str2double(get(handles.analyzePWdata.BP3bins,'String'));

handles.distFrom (4) = str2double(get(handles.analyzePWdata.HPfrom,'String'));
handles.distTo (4) = str2double(get(handles.analyzePWdata.HPto,'String'));
handles.distBins (4) = str2double(get(handles.analyzePWdata.HPbins,'String'));

hWd = 2;    % bin half width for the determination of main mode mean

% beginning of the computation.
% 1) compute the power distribution
% 2) find the bin with the highest peak: thus define the fundamental mode
% 3) extract fro the power data the elements that fall within a
% predetermined distance form the max bin. The mean of this data subset
% define the mean of the pricipal mode.
% 4) compute the mean of the distribution. This is used to determine the
% amount of skewness of the power distribution and to understand the
% position of the secondary mode compared to the fundamental mode.

for iCh=1:handles.nCh
    for jTr=1:handles.nTrials
        for BP = 2:5
            % extract the power data
            sl = handles.BPpowerL(BP);
            tmp = zeros(1,sl);
            tmp (1:sl) = log10(handles.BPpower(2,BP,iCh,jTr,1:sl));
            % compute the distribution: do the histrogram
            bins = handles.distBins(BP-1);
            xValues = handles.distFrom(BP-1):((handles.distTo(BP-1)-handles.distFrom(BP-1))/(bins-1)):handles.distTo(BP-1);
            [nel,cent] = hist(tmp,xValues);
            handles.nelements{BP-1}(iCh,jTr,1:bins) = nel(1,1:bins);
            nel = nel/sl;
            handles.freqPW{BP-1}(iCh,jTr,1:bins) = nel(1,1:bins);
            handles.centers{BP-1}(iCh,jTr,1:bins) = cent(1,1:bins);        

            % compute the Shannon entropy for the entire recording
            % Procedure: the bad passed signal is divided in tokens and each one can exist in a number of states.
            % The state number is defines by the bin number, there fore the
            % probability of each message is given by the relative
            % frequency of the relative bin. 
            
            handles.ShEntropy{BP-1}(iCh,jTr) = sum(nel(nel>0).*(-log2(nel(nel>0))));
 
            % Begins the analysis of the distribution
            % find the mean of the fundamental mode
            [nMax iMax] = max(handles.freqPW{BP-1}(iCh,jTr,:));
            l = iMax - hWd;
            if l < 1, l = 1;
            end
            r = iMax + hWd;
            if r > bins, r = bins;
            end
            leftLim = handles.centers{BP-1}(iCh,jTr,l);
            rightLim = handles.centers{BP-1}(iCh,jTr,r);

            % extract the elements with the main mode peak
            tmpPeak = tmp(tmp>leftLim & tmp<rightLim);
            mainModeM = mean(tmpPeak);
            % great, now we must determine on what side of this peak is the
            % secondary mode
            overallMean = mean(tmp);
            % only two possible outcomes: overallMean larger or smaller
            % than mainModeM.
            if overallMean > mainModeM
                % the main mode is on the left and the distribution is
                % skewed to the right
                leftValues = tmp(tmp<=mainModeM);
                rightValues = 2*mainModeM-leftValues; 
            else    
                rightValues = tmp(tmp>=mainModeM);
                leftValues = 2*mainModeM-rightValues; 
            end
            total = [leftValues rightValues];   % new artificial data
            meanTotal = mean(total);
            stdTotal = std(total);
            [nel,cent] = hist(total,xValues);
            % Look carefully at the normalisation of this distribution
            nel = nel/sl;
            % gaussian fit to the simmetrified main mode
            param(2) = meanTotal;                          % mean main mode
            param(3) = stdTotal;                           % SD first component
            ampli = 1/(2.50663*stdTotal);               % amplitude first component
         
            gaussFnc = [];
            oldopts = optimset;
            options = optimset(oldopts,'MaxFunEvals',10000);
            amplitudeOut = fminsearch(@gaussFit1,ampli,options);
            param(1) = amplitudeOut;
            paramOut = fminsearch(@gaussFit2,param,options);
            % paramOut contains the 3 parameters that define the best fit.
            handles.mainModeMean{BP-1}(iCh,jTr) = paramOut(2);
            handles.mainModeAmp{BP-1}(iCh,jTr) = paramOut(1);
            handles.mainModeStd{BP-1}(iCh,jTr) = paramOut(3);
            handles.mainModeModel{BP-1}(iCh,jTr,1:bins) = nel(1:bins);
            
            % Now we compute the difference between the complete distribution and 
            % the gaussian model of the fundamental mode
            tmp (1:bins) = handles.freqPW{BP-1}(iCh,jTr,1:bins);
            handles.secondaryMode{BP-1}(iCh,jTr,1:bins) = tmp(1:bins) - nel(1:bins);
            
            % Computation of the metrics:
            % 1) mean and STD of the main mode (from the gaussian fit)
            % 2) median and STD of the secondary mode (from the integral of
            % the secondaryMode distribution (positive part only!)
            % 3) Metrics of the relative weight of the two modes:
            % 3a) Integral of the main mode gaussian
            % 3b) Integral of the secondary mode distribution (positive
            % part only).
            % Metrics 3a and b are normalized to the total of 3a+3b.
            
            % compute metrics of the secondary mode
            sum1 = 0;
            sum2 = 0;
            area = 0;
            totalArea = 0;
            for bin=1:bins
                secMode = handles.secondaryMode{BP-1}(iCh,jTr,bin);
                newTerm = secMode * handles.centers{BP-1}(iCh,jTr,bin);
                totalArea = totalArea + handles.freqPW{BP-1}(iCh,jTr,bin);
                % grab only the positive part of the distribution
                if secMode > 0,
                    sum1 = sum1 + newTerm;
%                    sum2 = sum2 + newTerm.^2;
                    sum2 = sum2 + secMode * handles.centers{BP-1}(iCh,jTr,bin).^2;
                    area = area + secMode;
                end
            end
            handles.secModeMean{BP-1}(iCh,jTr) = sum1/area;
            handles.secModeStd{BP-1}(iCh,jTr) = sqrt(sum2/area - (sum1/area).^2);
            handles.mainModeArea{BP-1}(iCh,jTr) = (totalArea-area)/totalArea;
            handles.secModeArea{BP-1}(iCh,jTr) = area/totalArea;
            
            % prepare the cell array. This is a multidimensional table that
            % separates channel, trial and BP
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 1) = cellstr(handles.dir_in);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 2) = cellstr(handles.file_in);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 3) = cellstr(handles.fileTime);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 4) = num2cell(iCh);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 5) = num2cell(jTr);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 6) = num2cell(BP-1);
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 7) = num2cell(handles.ShEntropy{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 8) = num2cell(handles.mainModeMean{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 9) = num2cell(handles.mainModeStd{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 10) = num2cell(handles.mainModeArea{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 11) = num2cell(handles.secModeMean{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 12) = num2cell(handles.secModeStd{BP-1}(iCh,jTr));
            handles.dtaPWsummary(handles.fileInNum, iCh, jTr, BP-1, 13) = num2cell(handles.secModeArea{BP-1}(iCh,jTr));
        end
    end
end
guidata(hObject, handles);

% Now plot the histogram
plotPWhisto (hObject,handles);

    function res = gaussFit1(a)
        % gmodel = a(1)*exp(-(centers-a(2))^2/2*a(3).^2)
        % nelements is the array that contains the histogram bin counts: this
        % is the function to fit
        % The first passage computes the amplitude
        gaussFnc = a*exp(-(xValues-param(2)).^2/(2*(param(3)^2)));
        res = sum((nel - gaussFnc).^2);
    end

    function res = gaussFit2(a)
        % gmodel = a(1)*exp(-(centers-a(2))^2/2*a(3).^2)
        % nelements is the array that contains the histogram bin counts: this
        % is the function to fit
        % The second passage refines the computation
        gaussFnc = a(1)*exp(-(xValues-a(2)).^2/(2*(a(3)^2)));
        res = sum((nel - gaussFnc).^2);
    end
end
