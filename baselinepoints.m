function [xout, yout, varargout] = baselinepoints(x,y,varargin)

% varargout:
%   1: y_smooth

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
parser = inputParser;
addRequired(parser,'x',@(x)(isnumeric(x)))
addRequired(parser,'y',@(x)(isnumeric(x)))
addOptional(parser,'YSgolayWindow',0.05,@(x)(isscalar(x)))
addOptional(parser,'YSgolayOrder',15,@(x)(isscalar(x)))
addOptional(parser,'DerivativeSgolayWindow',0.02,@(x)(isscalar(x)))
addOptional(parser,'DerivativeSgolayOrder',3,@(x)(isscalar(x)))
addOptional(parser,'FirstDerivativeThreshold',5,@(x)(isscalar(x)))
addOptional(parser,'SecondDerivativeThreshold',0.1,@(x)(isscalar(x)))
addOptional(parser,'OutputPlot',false,@(x)(isscalar(x) && islogical(x)))
parse(parser,x,y,varargin{:})
p = parser.Results;

ysgolaywin = p.YSgolayWindow;
ysgolayord = p.YSgolayOrder;
dsgolaywin = p.DerivativeSgolayWindow;
dsgolayord = p.DerivativeSgolayOrder;
thr1 = p.FirstDerivativeThreshold;
thr2 = p.SecondDerivativeThreshold;
outplot = p.OutputPlot;
clear p
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% preliminary routine
% x and y must have the same length and they must be 1D vectors
assert(length(x)==length(y),'x and y must have the same length')
assert((numel(x)==numel(y))&&(numel(y)==length(y)),'x and y must be 1D vectors')

% make x and y row vectors
ncol = size(x,2);
x = reshape(x,1,[]);
y = reshape(y,1,[]);

%% compute 1st and 2nd derivatives

% first, smooth the power
ywinsmooth = length(y)*ysgolaywin;
ywinsmooth = ywinsmooth + 1 - rem(ywinsmooth,2); % make it odd
% p_smooth = movmean(p,[(win_smooth-1)/2 (win_smooth-1)/2]);
y_smooth = sgolayfilt(y, ysgolayord, ywinsmooth);
y_smooth = fliplr(sgolayfilt(fliplr(y_smooth), ysgolayord, ywinsmooth));

% compute the 1st derivative. Then smooth and standardize it
dwinsmooth = length(y)*dsgolaywin; %s
dwinsmooth = dwinsmooth + 1 - rem(dwinsmooth,2); % make it odd
d1 = sgolayfilt([0, diff(y_smooth)],dsgolayord,dwinsmooth);
d1z = (d1-mean(d1))./mean(d1);
% find where the 1st derivative is close to 0
b1_logic = d1z>=-thr1 & d1z<=thr1;
b1_time = x(b1_logic);

% Now the same with the 2nd derivative
d2 = sgolayfilt([0, diff(d1z)],dsgolayord,dwinsmooth);
d2z = (d2-mean(d2))./std(d2);
b2_logic = d2z>=-thr2 & d2z<=thr2;
b2_time = x(b2_logic);

% baseline points are when both the 1st and the 2nd derivatives are 0
b_logic = b1_logic & b2_logic;
xout = x(b_logic);
% b = y_smooth(b_logic);
yout = y(b_logic);
% reshape the output to match input size
if ncol==1
    yout = reshape(yout,[],1);
    xout = reshape(xout,[],1);
end

if nargout>2
    varargout{1} = y_smooth;
end

if outplot
    figure
    % plot the both the original and the smoothed trace
    a1 = subplot(3,1,1);
    plot(x,y)
    hold on
    plot(x,y_smooth)
    title('y')
    
    % plot the 1st derivative and the regions where it's close to 0
    a2 = subplot(3,1,2);
    plot(x,d1z)
    hold on
    plot(b1_time,d1z(b1_logic),'o','markersize',4)
    title('first derivative')
    
    % plot the 2nd derivative and the regions where it's close to 0
    a3 = subplot(3,1,3);
    plot(x,d2z)
    hold on
    plot(b2_time,d2z(b2_logic),'o','markersize',4)
    title('second derivative')
    
    % plot baseline points and interpolated baseline
    plot(a1,xout,yout,'o','markersize',4)

    linkaxes([a1,a2,a3],'x')
end
