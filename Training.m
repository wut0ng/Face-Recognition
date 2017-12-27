clc;clear;close all;warning off all;
 
image_folder = 'Pelatihan';
filenames = dir(fullfile(image_folder, '*.jpg'));
total_images = numel(filenames);

feature = zeros(total_images,8);

for n = 1:total_images
    full_name = fullfile(image_folder, filenames(n).name);
    facedetector = vision.CascadeObjectDetector('FrontalFaceCART');
    
    I = imread(full_name);
    gray_images = rgb2gray(I); %Convert RGB Image to Grayscale Image
    images_gray = medfilt2(gray_images); %Noise Removal using Median Filter
    BB = step(facedetector, images_gray); %Face Detection using Viola Jones Algorithm
    
    N = size(BB,1);
    handles.N = N;
    counter=1;
    for i = 1:N
        face = imcrop(images_gray,BB(i,:)); %Cropping based on detected face
    end
    
    rect = [80 70 140 175];
    crop_face = imcrop(face, rect); %Cropping based on xmin ymin width height
  
    %Statistical Texture Feature Extraction
    I3 = double(crop_face);
    m = mean(I3(:));
    s = skewness(I3(:));
    k = kurtosis(I3(:));
    e = entropy(crop_face);
    
    %GLCM Texture Feature Extraction
    GLCM = graycomatrix(crop_face,'Offset',[0 1; -1 1; -1 0; -1 -1]);
    stats = graycoprops(GLCM,{'contrast','correlation','energy','homogeneity'});
    contrast = mean(stats.Contrast);
    correlation = mean(stats.Correlation);
    energy = mean(stats.Energy);
    homogeneity = mean(stats.Homogeneity);

    feature(n,1) = m; %mean
    feature(n,2) = s; %skewness
    feature(n,3) = k; %kurtosis
    feature(n,4) = e; %entropy
    feature(n,5) = contrast;
    feature(n,6) = correlation;
    feature(n,7) = energy;
    feature(n,8) = homogeneity;
    
end

target = zeros(total_images,1);

target(1:15,:) = 1; %Class 1
target(16:29,:) = 2; %Class 2
target(30:44,:) = 3; %Class 3

TrnData = [feature, target]

epoch = 61;
%numMFs = 2; 
%mfType = 'gbellmf';
error_goal = 1e-6;
trnOpt = [];
dispOpt = [];
initFis = [];
trnOpt(1) = epoch;
trnOpt(2) = error_goal;

%Training
trnfismat = anfis(TrnData, initFis, trnOpt, dispOpt);
writefis(trnfismat,'trnfismat');
save trnfismat.mat trnfismat;

output = round(evalfis(TrnData(1:44,1:8), trnfismat))
error = numel(find(output~=target))
accuracy = (numel(output)-error)/(numel(output))*100