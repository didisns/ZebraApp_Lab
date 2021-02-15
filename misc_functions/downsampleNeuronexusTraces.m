function downsampleNeuronexusTraces(selCh,newsf,fold)
% downsamples neuronexus files and saves them as .dat files into the same
% folder

% input arguments:
%   selCh = vector of selected channels
%   newsf = new sampling frequency (Hz)
%   fold = path to the source folder

%% initialize reader object
reader = allegoXDatFileReader();

%% folder and file selection
% fold = uigetdir;
[filestruct] = dir(fold);
% remove folders
filestruct([filestruct(:).isdir]) = [];
% only select .xdat files
allegofiles_logic = arrayfun(@(x)(strcmp(x.name(end-8:end),'data.xdat')),filestruct);
allegofiles = filestruct(allegofiles_logic);
clear allogofiles_logic filestruct

% selCh = [65 66];

%% set new sampling frequency

% newsf = 2000; %hz
for i = 1:length(allegofiles)
    disp(['processing file ' num2str(i)])
    fname = [allegofiles(i).folder filesep allegofiles(i).name(1:end-10)];
    NeuroStruct = reader.getAllegoXDatAllSigs(fname);
    actualFreq = 1/(NeuroStruct.timeSamples(2) - NeuroStruct.timeSamples(1));
    oneevery = round(actualFreq/newsf);
    r = rem(size(NeuroStruct.signals,2),oneevery);
    tmp = NeuroStruct.signals(selCh,1:oneevery:end-r);
    
    writematrix(tmp',[fname '_resamp_' num2str(newsf) '.dat']);
end
disp('done!')