function varargout = MAINGUI(varargin)
% MAINGUI MATLAB code for MAINGUI.fig
%      MAINGUI, by itself, creates a new MAINGUI or raises the existing
%      singleton*.
%
%      H = MAINGUI returns the handle to a new MAINGUI or the handle to
%      the existing singleton*.
%
%      MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINGUI.M with the given input arguments.
%
%      MAINGUI('Property','Value',...) creates a new MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MAINGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MAINGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MAINGUI

% Last Modified by GUIDE v2.5 13-Mar-2020 13:48:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MAINGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MAINGUI_OutputFcn, ...
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


% --- Executes just before MAINGUI is made visible.
function MAINGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MAINGUI (see VARARGIN)

% Choose default command line output for MAINGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MAINGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MAINGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%
load DB
load svm
cl = {'open','close'};

dim = [30 60;
        30 60
        40 65];
delete(imaqfind)
%vid=videoinput('winvideo', 1, 'YUY2_640x480','ReturnedColorSpace', 'rgb'); 
vid=videoinput('winvideo',1);
triggerconfig(vid,'manual');
set(vid,'FramesPerTrigger',1 );
set(vid,'TriggerRepeat', Inf);
% start(vid);

%  View the default color space used for the data — The value of the ReturnedColorSpace property indicates the color space of the image data.
color_spec=vid.ReturnedColorSpace;

% Modify the color space used for the data — To change the color space of the returned image data, set the value of the ReturnedColorSpace property.
if  ~strcmp(color_spec,'rgb')
    set(vid,'ReturnedColorSpace','rgb');
end

start(vid)


% Create a detector object
faceDetector = vision.CascadeObjectDetector;   
faceDetectorLeye = vision.CascadeObjectDetector('EyePairBig'); 
faceDetectorM = vision.CascadeObjectDetector('Mouth'); 
tic
% Initialise vector
LC = 0; % Left eye closer
RC = 0; % Right eye closer
MC = 0; % Mouth closer
TF = 0; % Total frames
TC = 0; % Total closure
Feature = [];
c1p = 1;
species = 'Non-Fatigue';
tic
for ii = 1:600
   
    trigger(vid);
    im=getdata(vid,1); % Get the frame in im
    imshow(im)
    
    subplot(3,4,[1 2 5 6 9 10]);
    imshow(im)
    
    % Detect faces
    bbox = step(faceDetector, im); 
    
    if ~isempty(bbox)
        bbox = bbox(1,:);

        % Plot box
        rectangle('Position',bbox,'edgecolor','r');

         S = skin_seg2(im);
    
        % Segment skin region
        bw3 = cat(3,S,S,S);

        % Multiply with original image and show the output
        Iss = double(im).*bw3;

        Ic = imcrop(im,bbox);
        Ic1 = imcrop(Iss,bbox);
        subplot(3,4,[3 4]);
        imshow(uint8(Ic1))
        
        bboxeye = step(faceDetectorLeye, Ic); 
        
        if ~isempty(bboxeye)
            bboxeye = bboxeye(1,:);

            Eeye = imcrop(Ic,bboxeye);
            % Plot box
            rectangle('Position',bboxeye,'edgecolor','y');
        else
            disp('Eyes not detected')
        end
        
        if isempty(bboxeye)
            continue;
        end
       Ic(1:bboxeye(2)+2*bboxeye(4),:,:) = 0; 

        % Detect Mouth
        bboxM = step(faceDetectorM, Ic); 
        

        if ~isempty(bboxM)
            bboxMtemp = bboxM;
            
            if ~isempty(bboxMtemp)
            
                bboxM = bboxMtemp(1,:);
                Emouth =  imcrop(Ic,bboxM);

                % Plot box
                rectangle('Position',bboxM,'edgecolor','y');
            else
                disp('Mouth  not detected')
                continue;
            end
        else
            disp('Mouth not detected')
            continue;
        end
        
        [nre, nce, k ] = size(Eeye);
        
        % Divide into two parts
        Leye = Eeye(:,1:round(nce/2),:);
        Reye = Eeye(:,round(nce/2+1):end,:);
              
        subplot(3,4,7)
        imshow(edge(rgb2gray(Leye),'sobel'));
        subplot(3,4,8)
        imshow(edge(rgb2gray(Reye),'sobel'));
        
        Emouth3 = Emouth;
        
        
        Leye = rgb2gray(Leye);
        Reye = rgb2gray(Reye);
        Emouth = rgb2gray(Emouth);

        % K means clustering
        X = Emouth(:);
        [nr1, nc1 ] = size(Emouth);
        cid = kmeans(double(X),2,'emptyaction','drop');
        
        kout = reshape(cid,nr1,nc1);
        subplot(3,4,[11,12]);
        
        % Segment
        Ism = zeros(nr1,nc1,3);
%         Ism(:,:,3) = 255;
%         Ism(:,:,3) = 125;
        Ism(:,:,3) = 255;
        
        bwm = kout-1;
        bwm3 = cat(3,bwm,bwm,bwm);
        Ism(logical(bwm3)) = Emouth3(logical(bwm3));
        imshow(uint8(Ism));
        
        % Template matching using correlation coefficient
        % Left eye
        % Resize to standard size
        Leye =  imresize(Leye,[dim(1,1) dim(1,2)]);
        c1 =match_DB(Leye,DBL);
        subplot(3,4,7)
        title(cl{c1})
        
        
        % Right eye
        % Resize to standard size
        Reye =  imresize(Reye,[dim(2,1) dim(2,2)]);
        c2 = match_DB(Reye,DBR);
        subplot(3,4,8)
        title(cl{c2})
        
        % Mouth
        % Resize to standard size
        Emouth =  imresize(Emouth,[dim(3,1) dim(3,2)]);
        c3 = match_DB(Emouth,DBM);
        subplot(3,4,[11,12]);
        title(cl{c3})
        
        
        if c1 == 2
            LC = LC+1;
            if c1p == 1
                TC = TC+1;
            end
        end
        if c2==2
            RC = RC+1;
        end
        if c3 == 1
            MC = MC + 1;
        end

        TF = TF + 1; % Total frames
        toc
        if toc>8
            Feature = [LC/TF RC/TF MC/TF TC];
           % species = fictcsvm(svmStruct,Feature);
            

            tic
            % Initialise vector
            LC = 0; % Left eye closer
            RC = 0; % Right eye closer
            MC = 0; % Mouth closer
            TF = 0; % Total frames
            TC = 0; % Total closure
        end
        subplot(3,4,[1 2 5 6 9 10]);
        if strcmpi(species,'Fatigue')
            text(20,20,species,'fontsize',14,'color','r','Fontweight','bold')
            beep;
        else
            text(20,20,species,'fontsize',14,'color','g','Fontweight','bold')
        end
        c1p = c1;
        %pause(0.00005)
    end
end
toc /600;
close
axes(handles.axes1);
% --- Executes on button press in pushbutton2.

function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pause;
