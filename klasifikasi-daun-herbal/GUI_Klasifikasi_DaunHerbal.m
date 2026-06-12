function varargout = GUI_Klasifikasi_DaunHerbal(varargin)
% GUI_Klasifikasi_DaunHerbal MATLAB code for GUI_Klasifikasi_DaunHerbal.fig
% Dibuat otomatis untuk skripsi Klasifikasi Daun Herbal berbasis JST (Backpropagation)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GUI_Klasifikasi_DaunHerbal_OpeningFcn, ...
                   'gui_OutputFcn',  @GUI_Klasifikasi_DaunHerbal_OutputFcn, ...
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


function GUI_Klasifikasi_DaunHerbal_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;

% Muat model JST yang telah dilatih
if exist('model_jst.mat', 'file')
    load('model_jst.mat', 'net', 'mu', 'sigma', 'categories');
    handles.net = net;
    handles.mu = mu;
    handles.sigma = sigma;
    handles.categories = categories;
    disp('Model JST berhasil dimuat.');
else
    errordlg('File model_jst.mat tidak ditemukan! Jalankan training_model_jst_v2.m terlebih dahulu.');
end

guidata(hObject, handles);


function varargout = GUI_Klasifikasi_DaunHerbal_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% ==============================
% === PUSH BUTTON: INPUT CITRA ==
% ==============================
function pushbutton_input_Callback(hObject, eventdata, handles)
[filename, pathname] = uigetfile({'*.jpg;*.png;*.jpeg','File Citra (*.jpg, *.png, *.jpeg)'});
if isequal(filename,0)
    return;
end
imgPath = fullfile(pathname, filename);
I = imread(imgPath);
axes(handles.axes_gambar);
imshow(I);
title('Citra Input');

handles.I = I;
guidata(hObject, handles);


% =================================
% === PUSH BUTTON: KLASIFIKASI ====
% =================================
function pushbutton_klasifikasi_Callback(hObject, eventdata, handles)
if ~isfield(handles, 'I')
    errordlg('Silakan input citra terlebih dahulu!');
    return;
end

I = handles.I;
I = imresize(I, [256 256]);
gray = rgb2gray(I);

% --- Fitur Tekstur (LBP) ---
lbp = extractLBPFeatures(gray);
meanLBP = mean(lbp);
stdLBP = std(lbp);

% --- Fitur Bentuk ---
bw = imbinarize(gray);
bw = imfill(bw, 'holes');
stats = regionprops(bw, 'Area', 'Perimeter', 'Eccentricity', 'BoundingBox', 'ConvexArea');
if isempty(stats)
    aspectRatio = 0; eccentricity = 0; circularity = 0; convexity = 0;
else
    area = stats(1).Area;
    perimeter = stats(1).Perimeter;
    boundingBox = stats(1).BoundingBox;
    aspectRatio = boundingBox(3) / boundingBox(4);
    eccentricity = stats(1).Eccentricity;
    circularity = (4 * pi * area) / (perimeter^2 + eps);
    convexity = area / (stats(1).ConvexArea + eps);
end

% --- Fitur Warna ---
Rmean = mean(mean(I(:,:,1)));
Gmean = mean(mean(I(:,:,2)));
Bmean = mean(mean(I(:,:,3)));

% Gabungkan fitur
fitur = [meanLBP, stdLBP, aspectRatio, eccentricity, circularity, convexity, Rmean, Gmean, Bmean];

% Normalisasi
fiturNorm = (fitur - handles.mu) ./ handles.sigma;

% Klasifikasi
y = handles.net(fiturNorm');
[~, idx] = max(y);
hasil = handles.categories{idx};

% === Tampilkan hasil klasifikasi ===
set(handles.text_hasil, 'String', hasil, 'ForegroundColor', 'b', 'FontSize', 14);

% === Tampilkan tabel fitur ===
tabelData = {'Mean LBP', meanLBP;
             'Std LBP', stdLBP;
             'Aspect Ratio', aspectRatio;
             'Eccentricity', eccentricity;
             'Circularity', circularity;
             'Convexity', convexity;
             'Mean R', Rmean;
             'Mean G', Gmean;
             'Mean B', Bmean};
set(handles.uitable_fitur, 'Data', tabelData, 'ColumnName', {'Fitur', 'Nilai'});

guidata(hObject, handles);


% =================================
% === PUSH BUTTON: RESET ==========
% =================================
function pushbutton_reset_Callback(hObject, eventdata, handles)
cla(handles.axes_gambar, 'reset');
set(handles.text_hasil, 'String', '');
set(handles.uitable_fitur, 'Data', {});
guidata(hObject, handles);
