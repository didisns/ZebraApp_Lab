may/june 2019, Gab.
I've made some changes:
	1) Possibility to choose an arbitrary number of BPs
	2) Possibility to rescale the main plots of different channels, so that they can be compared in the when
			"multichannel plot" option is selected.
	3) Files are now loaded with the command "readtable" (instead of "fscanf") while in "Default" mode (for 
			.dat files). It is something like 10x faster on my PC.
	4) The extraction of trials from a synch channel is now performed with a completely different strategy
			suggested by Gimmi. It is faster and way more straightforward.
	5) The variable powerBP is now a structure array instead of a 5D matrix. The lenght of the array is equal
			to the number of selected frequency bandpasses. This structure has 2 fields: power and time:
				-power is a 3D matrix (channels x trials x time).
				-time is a 1D vector containig the timepoints for that bandpass.