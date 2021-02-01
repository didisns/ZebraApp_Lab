start = [1 7 15 18];
stop = [4 8 17 21];
ref = 3;

samespk = (start(2:end) - stop(1:end-1)) < ref; % logic array: 1 points that belong to the same spike
diffsamespk = diff(samespk); % 1 when the event begins, -1 when it ends; then find the correct indeces:
% control to merge events that are at the beginning or at the end:
if diffsamespk(1) == 0 || diffsamespk(1) == -1
   sameEvStart = [1, find(diffsamespk == 1) +2];
elseif diffsamespk(end) == 1
    EvStop = find(diffsamespk == -1) +1;
    sameEvStop = [EvStop, EvStop(end)+1];
else
sameEvStart = find(diffsamespk == 1) +1;
sameEvStop = find(diffsamespk == -1) +1;
end