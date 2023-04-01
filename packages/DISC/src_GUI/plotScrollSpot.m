function varargout = plotScrollSpot(varargin)
% PLOTSCROLLSPOT MATLAB code for plotScrollSpot.fig
%      PLOTSCROLLSPOT, by itself, creates a new PLOTSCROLLSPOT or raises the existing
%      singleton*.
%
%      H = PLOTSCROLLSPOT returns the handle to a new PLOTSCROLLSPOT or the handle to
%      the existing singleton*.
%
%      PLOTSCROLLSPOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTSCROLLSPOT.M with the given input arguments.
%
%      PLOTSCROLLSPOT('Property','Value',...) creates a new PLOTSCROLLSPOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotScrollSpot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotScrollSpot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plotScrollSpot

% Last Modified by GUIDE v2.5 26-Jan-2022 15:45:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotScrollSpot_OpeningFcn, ...
                   'gui_OutputFcn',  @plotScrollSpot_OutputFcn, ...
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


% --- Executes just before plotScrollSpot is made visible.
function plotScrollSpot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotScrollSpot (see VARARGIN)
% Get data 
movegui('center')

handles.data = varargin{:}; 
handles.idx = 1; 
[mu,sigma] = normfit(handles.data(:));
handles.displayRange = [mu-sigma, mu+3*sigma];

handles.slider1.Min = 1;
handles.slider1.Max = size(handles.data, 3);
if handles.slider1.Max > 1
    handles.slider1.SliderStep = [1/(handles.slider1.Max-1) , 1/(handles.slider1.Max-1)];
else
    handles.slider1.SliderStep = [0, 0];
end
handles.slider1.Value = 1;
handles.textMin.String = '1';
handles.textMax.String = num2str(handles.slider1.Max);
handles.textCurrent.String = '1';

imshow(handles.data(:,:,1),'DisplayRange', handles.displayRange, 'Parent', handles.axes1);

% Choose default command line output for plotScrollSpot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plotScrollSpot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plotScrollSpot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.idx = round(handles.slider1.Value);
imshow(handles.data(:,:,handles.idx),'DisplayRange', handles.displayRange, 'Parent', handles.axes1);
handles.textCurrent.String = num2str(handles.idx);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
