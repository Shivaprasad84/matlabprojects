%% Import image
inputImageFileName = '/home/thanuja/projects/data/myelin/RFCprobabilities_ilastik/ssSEM/s909/myelin_01.png';
inputImage = imread(inputImageFileName);
figure;imagesc(inputImage);title('Input Image')

%% Gaussian blur
sigma = 2;
maskSize = 7;   
gbImage = gaussianFilter(inputImage,sigma,maskSize);
figure;imagesc(inputImage);title('Gaussian blurred image')

%% Erosion and dilation
SE = strel('square',5);

erodedImage = imerode(gbImage,SE);
figure;imagesc(erodedImage);title('eroded')

dilatedImage = imdilate(gbImage,SE);
figure;imagesc(dilatedImage);title('dilated')

erosionDilation = imdilate(erodedImage,SE);
figure;imagesc(erosionDilation);title('eroded dilated')

dilationErosion = imerode(dilatedImage,SE);
figure;imagesc(erosionDilation);title('dilated eroded')

%% connected component analysis
threshold = 0.15;
binaryImage = im2bw(dilationErosion,threshold);
figure;imshow(binaryImage);title('binary image')

%% watershed
% invertedGbImage = invertImage(gbImage);
% ws0 = watershed(invertedGbImage);
% figure;imagesc(ws0);title('original ws')
% 
% ws = assignRandomIndicesToWatershedTransform(ws0);
% figure;imagesc(ws);title('randomized ws indices')
% 
% watershedColoredEdges = overlayWatershedOnImage(inputImage,ws);
%% threshold

