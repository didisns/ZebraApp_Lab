function varargout = analyzePWdistribution(varargin)
% ANALYZEPWDISTRIBUTION MATLAB code for analyzePWdistribution.fig
%      ANALYZEPWDISTRIBUTION, by itself, creates a new ANALYZEPWDISTRIBUTION or raises the existing
%      singleton*.
%
%      H = ANALYZEPWDISTRIBUTION returns the handle to a new ANALYZEPWDISTRIBUTION or the handle to
%      the existing singleton*.
%
%      ANALYZEPWDISTRIBUTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANALYZEPWDISTRIBUTION.M with the given input arguments.
%
%      ANALYZEPWDISTRIBUTION('Property','Value',...) creates a new ANALYZEPWDISTRIBUTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before analyzePWdistribution_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to analyzePWdistribution_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help analyzePWdistribution

% Last Modified by GUIDE v2.5 27-Jun-2017 16:21:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @analyzePWdistribution_OpeningFcn, ...
                   'gui_OutputFcn',  @analyzePWdistribution_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before analyzePWdistribution is made visible.
function analyzePWdistribution_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to analyzePWdistribution (see VARARGIN)

% Choose default command line output for analyzePWdistribution
handles.output = hObject;

% establish the link with the calling process
handles.parentObject =  varargin{1};
handles.parentHandles = varargin{2};

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes analyzePWdistribution wait for user response (see UIRESUME)
% uiwait(handles.analyzePWdist);


% --- Outputs from this function are returned to the command line.
function varargout = analyzePWdistribution_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function BP1from_Callback(hObject, eventdata, handles)

function BP1from_CreateFcn(hObject, eventdata, handles)

function BP1to_Callback(hObject, eventdata, handles)

function BP1bins_Callback(hObject, eventdata, handles)

function BP2from_Callback(hObject, eventdata, handles)

function BP2to_Callback(hObject, eventdata, handles)

function BP2bins_Callback(hObject, eventdata, handles)

function BP3from_Callback(hObject, eventdata, handles)

function BP3to_Callback(hObject, eventdata, handles)

function BP3bins_Callback(hObject, eventdata, handles)

function HPfrom_Callback(hObject, eventdata, handles)

function HPto_Callback(hObject, eventdata, handles)

function HPbins_Callback(hObject, eventdata, handles)

function Histo_Callback(hObject, eventdata, handles)

% refresh the local values of the parent handles
handles.parentHandles = guidata(handles.parentObject);
analyzePowerDistribution(handles.parentObject, handles.parentHandles);
guidata(hObject,handles);


function selectCh_Callback(hObject, eventdata, handles)
plotPWhisto(handles.parentObject,handles.parentHandles)

function selectCh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectCh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes when selected object is changed in selectBPdisplay.
function selectBPdisplay_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in selectBPdisplay 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

plotPWhisto(handles.parentObject,handles.parentHandles)


% --- Executes on button press in clearTable.
function clearTable_Callback(hObject, eventdata, handles)
% hObject    handle to clearTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
