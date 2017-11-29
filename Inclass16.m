% Inclass16
% GB comments
1 100
2 100
3 100 
overall 100


%The folder in this repository contains code implementing a Tracking
%algorithm to match cells (or anything else) between successive frames. 
% It is an implemenation of the algorithm described in this paper: 
%
% Sbalzarini IF, Koumoutsakos P (2005) Feature point tracking and trajectory analysis 
% for video imaging in cell biology. J Struct Biol 151:182?195.
%
%The main function for the code is called MatchFrames.m and it takes three
%arguments: 
% 1. A cell array of data called peaks. Each entry of peaks is data for a
% different time point. Each row in this data should be a different object
% (i.e. a cell) and the columns should be x-coordinate, y-coordinate,
% object area, tracking index, fluorescence intensities (could be multiple
% columns). The tracking index can be initialized to -1 in every row. It will
% be filled in by MatchFrames so that its value gives the row where the
% data on the same cell can be found in the next frame. 
%2. a frame number (frame). The function will fill in the 4th column of the
% array in peaks{frame-1} with the row number of the corresponding cell in
% peaks{frame} as described above.
%3. A single parameter for the matching (L). In the current implementation of the algorithm, 
% the meaning of this parameter is that objects further than L pixels apart will never be matched. 
 
% Continue working with the nfkb movie you worked with in hw4. 

% addpath('//Documents/GitHub/inclass16-JohnKomoll/TrackingCode')
% addpath('//Documents/GitHub/bfmatlab')

reader1 = bfGetReader('nfkb_movie1.tif');
reader2 = bfGetReader('nfkb_movie2.tif');

% Part 1. Use the first 2 frames of the movie. Segment them any way you
% like and fill the peaks cell array as described above so that each of the two cells 
% has 6 column matrix with x,y,area,-1,chan1 intensity, chan 2 intensity
 
t = 1;
z = 1;
chan = 1;
ind1 = reader1.getIndex(z-1,chan-1,t-1)+1;
img_nuc1 = im2double(bfGetPlane(reader1, ind1));
ind2 = reader1.getIndex(z-1,chan-1,t)+1;
img_nuc2 = im2double(bfGetPlane(reader1, ind2));

% Prepare gaussian distribution for smoothing
rad = 15;
sigma = 5;
fgauss = fspecial('gaussian', rad, sigma);

% Remove some background noise with a mask, then erosion
img1 = img_nuc1 > 0.011;
img1 = imerode(img1, strel('disk', 1));
img2 = img_nuc2 > 0.011;
img2 = imerode(img2, strel('disk', 1));

% Fill back in the holes and filter smooth
img1 = img_nuc1 .* imdilate(img1, strel('disk', 5));
img1 = imfilter(img1, fgauss);
img2 = img_nuc2 .* imdilate(img2, strel('disk', 5));
img2 = imfilter(img2, fgauss);

% Subtract out the background and mask to get cells
back = imopen(img1, strel('disk', 50));
img1 = imsubtract(img1, back);
img1 = img1 > 0.003;
back = imopen(img2, strel('disk', 50));
img2 = imsubtract(img2, back);
img2 = img2 > 0.003;

% Use regionprops to get image info
stats1 = regionprops(img1, imadjust(img_nuc1), 'Centroid', 'Area', 'MeanIntensity');
stats2 = regionprops(img2, imadjust(img_nuc2), 'Centroid', 'Area', 'MeanIntensity');

% Put info into cell array
xy1 = cat(1, stats1.Centroid);
a1 = cat(1, stats1.Area);
mi1 = cat(1, stats1.MeanIntensity);
tmp = -1*ones(size(a1));
peaks{1} = [xy1, a1, tmp, mi1];

xy2 = cat(1, stats2.Centroid);
a2 = cat(1, stats2.Area);
mi2 = cat(1, stats2.MeanIntensity);
tmp = -1*ones(size(a2));
peaks{2} = [xy2, a2, tmp, mi2];

% Part 2. Run match frames on this peaks array. ensure that it has filled
% the entries in peaks as described above. 
 
peaks_matched = MatchFrames(peaks, 2, 50);

% Part 3. Display the image from the second frame. For each cell that was
% matched, plot its position in frame 2 with a blue square, its position in
% frame 1 with a red star, and connect these two with a green line. 

imshow(imadjust(img_nuc2))
hold on
[cells, ~] = size(peaks_matched{1});
for cell = 1:cells
    
    index = peaks_matched{1}(cell, 4);
    if index > 0
        plot(peaks_matched{1}(cell,1), peaks_matched{1}(cell,2), 'r*', 'MarkerSize', 10)
        plot(peaks{2}(index,1), peaks{2}(index,2), 'cs', 'MarkerSize', 10)
        plot([peaks_matched{1}(cell,1) peaks{2}(index,1)], [peaks_matched{1}(cell,2) peaks{2}(index,2)], 'g', 'LineWidth', 1)
    end
    
end


