function U = unionjack(m)
%   UNIONJACK(M) returns an M-by-3 matrix containing the unionjack colormap.
%   The colors begin with dark blue, range through dimmer shades of
%   blue until white and ends with dark red. UNIONJACK, by
%   itself, is the same length as the current figure's colormap. If no
%   figure exists, MATLAB uses the length of the default colormap.
%
%   See also PARULA, HSV, HOT, PINK, FLAG, COLORMAP, RGBPLOT.

%   Gab, 2020-05-03

if nargin < 1
   f = get(groot,'CurrentFigure');
   if isempty(f)
      m = size(get(groot,'DefaultFigureColormap'),1);
   else
      m = size(f.Colormap,1);
   end
end

h = floor(m/2);
g = [linspace(0,1,h)'; linspace(1,0,m-h)'];
r = [linspace(0,1,h)'; ones(m-h,1)];
b = [ones(h,1); linspace(1,0,m-h)' ];
U = [r g b];
