clc; clear; close all;

rng(0); % seed acak tetap agar hasil konsisten


% =========================
% 1. SETUP DATASET
% =========================
baseDir = '/Users/muharwin/Documents/MATLAB/dataset_daun_herbal';
trainDir = fullfile(baseDir, 'datalatih');
testDir  = fullfile(baseDir, 'datauji');
% Menentukan lokasi folder dataset

% Kategori daun
categories = {'Daun Jambu Biji','Daun Kunyit','Daun Pepaya','Daun Sirih'};
% Empat kelas daun yang akan diklasifikasi

% Datastore training & testing
imdsTrain = imageDatastore(fullfile(trainDir, categories), ...
    'LabelSource', 'foldernames', 'IncludeSubfolders', true);
imdsTest = imageDatastore(fullfile(testDir, categories), ...
    'LabelSource', 'foldernames', 'IncludeSubfolders', true);
% Membuat imageDatastore MATLAB agar gambar bisa dibaca otomatis sekaligus label diambil dari nama folder

% =========================
% 2. EKSTRAKSI FITUR TRAINING
% =========================
fprintf('Ekstraksi fitur data latih...\n');
trainFeatures = []; % menyiapkan matriks fitur
trainLabels = imdsTrain.Labels; % menyiapkan label kelas daun 

for i = 1:numel(imdsTrain.Files) % Mengambil satu gambar satu per satu
    I = readimage(imdsTrain, i); % Membaca gambar
    I = imresize(I, [256 256]); % Menyamakan ukuran
    gray = rgb2gray(I); % Mengubah ke grayscale

    % --- Fitur Tekstur (LBP) ---
    lbp = extractLBPFeatures(gray); % LBP mengukur pola tekstur daun
    meanLBP = mean(lbp); % diambil nilai rata rata
    stdLBP = std(lbp); % diambil nilai standar deviasi

    % --- Fitur Bentuk ---
    bw = imbinarize(gray); % Gambar diubah ke hitam-putih
    bw = imfill(bw, 'holes'); % Objek daun diperbaiki
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

    % Membentuk vektor fitur 9 dimensi untuk satu gambar, lalu disimpan ke matriks training
    fitur = [meanLBP, stdLBP, aspectRatio, eccentricity, circularity, convexity, Rmean, Gmean, Bmean];
    trainFeatures = [trainFeatures; fitur];
end

% =========================
% 3. EKSTRAKSI FITUR UJI
% =========================
fprintf('Ekstraksi fitur data uji...\n');
testFeatures = [];
testLabels = imdsTest.Labels;

for i = 1:numel(imdsTest.Files)
    I = readimage(imdsTest, i);
    I = imresize(I, [256 256]); % resize otomatis
    gray = rgb2gray(I);

    % Tekstur
    lbp = extractLBPFeatures(gray);
    meanLBP = mean(lbp);
    stdLBP = std(lbp);

    % Bentuk
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

    % Warna
    Rmean = mean(mean(I(:,:,1)));
    Gmean = mean(mean(I(:,:,2)));
    Bmean = mean(mean(I(:,:,3)));

    fitur = [meanLBP, stdLBP, aspectRatio, eccentricity, circularity, convexity, Rmean, Gmean, Bmean];
    testFeatures = [testFeatures; fitur];
end

% =========================
% 4. NORMALISASI FITUR
% =========================
[trainFeatures, mu, sigma] = zscore(trainFeatures);
testFeatures = (testFeatures - mu) ./ sigma;
% Menjadikan semua fitur memiliki:mean = 0, standar deviasi = 1 Agar JST lebih stabil dan cepat belajar.

% =========================
% 5. TRAINING JARINGAN SYARAF TIRUAN
% =========================

fprintf('Melatih model JST...\n');

warning('off','all');  % nonaktifkan semua warning sementara

% Ubah label ke one-hot encoding contoh:Jambu → [1 0 0 0], Kunyit → [0 1 0 0]
target = full(ind2vec(double(grp2idx(trainLabels))'));
testTarget = full(ind2vec(double(grp2idx(testLabels))'));

% ======== OPTIMASI JST ========
% Perubahan hanya di arsitektur & parameter

net = patternnet([30 20 10]); % Membuat JST dengan:3 hidden layer, 30 neuron → 20 → 10
net.performFcn = 'mse';       % Error dihitung dengan Mean Squared Error.
net.trainFcn = 'trainlm'; % Menggunakan Levenberg-Marquardt Backpropagation (cepat & akurat).
net.divideParam.trainRatio = 0.8;
net.divideParam.valRatio = 0.1;
net.divideParam.testRatio = 0.1;
net.trainParam.epochs = 800; % Maksimal 800 iterasi
net.trainParam.goal = 1e-6; % Error target sangat kecil
net.trainParam.max_fail = 20;

% Melatih JST menggunakan fitur dan target.
[net, tr] = train(net, trainFeatures', target);

warning('on','all');   % aktifkan kembali warning

% =========================
% 6. UJI MODEL
% =========================
yPred = net(testFeatures'); % Menghasilkan output JST.
[~, predClass] = max(yPred); % Mengambil kelas prediksi dan kelas asli.
[~, trueClass] = max(testTarget); % Mengambil kelas prediksi dan kelas asli.
akurasi = sum(predClass == trueClass) / numel(trueClass) * 100; % Menghitung persentase akurasi.

fprintf('Akurasi Uji: %.2f%%\n', akurasi);

% Confusion Matrix
figure;
plotconfusion(testTarget, yPred); % Menampilkan confusion matrix.
title(sprintf('Confusion Matrix (Akurasi: %.2f%%)', akurasi));

% =========================
% 7. SIMPAN MODEL
% =========================
save('model_jst.mat', 'net', 'mu', 'sigma', 'categories'); % Menyimpan:jaringan JST, parameter normalisasi, nama kelas.
fprintf('Model tersimpan sebagai model_jst.mat\n');
