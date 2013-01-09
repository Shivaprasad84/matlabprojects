function output = reconstructHoughBars(peaks3D,orientations,barLength,barWidth)
% reconstructs the original image based on the peaks given for each
% orientation

% Inputs:
%   peaks3D - a 3D array [row col orientation] containing the votes
%   orientations - e.g. [0 45 90 135]
%   barLength - 
%   barWidth -


% for each orientation
%   get the peaks
%   place a bar on the peak according to the  given orientation
%   the intensity(color) of the bar is proportional to the vote of that
%   peak
%   the pixel intensities don't add up. instead, the higher vote gets
%   preference to decide its intensity when two overlapping bars compete
%   for the same pixel


[numRows numCols numOrientations] = size(peaks3D);
output = zeros(numRows,numCols);

for i=1:numOrientations
   orientation = orientations(i);
   voteMat = peaks3D(:,:,i);
   peaksInd = find(voteMat);
   numPeaks = numel(peaksInd);
   
   for j=1:numPeaks
       % place a bar on each peak as described above
       

   end
       
end