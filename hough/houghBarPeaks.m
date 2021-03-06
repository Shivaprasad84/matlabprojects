function peaks3D = houghBarPeaks(houghSpace3D,orientations,thresholdFraction...
                    ,slidingDist,barLength,barWidth)

% TODO: parallelize    
% TODO: how to handle equally high peaks in the suppression neighborhood.
% at the moment they are left alone allowing muliple equally high peaks
% next to each other.

% NB. At the moment, only thresholiding is used for peak detection. No NMS
% etc.
                
% output:
%   peaks3D - [row col orientation] 3D array containing the votes for the
%   detected peaks or zero otherwise.

% inputs:
%   houghSpace3D - contains the vote for each pixel at each orientation as
%   a 3D array [row col orientation]
%   orientations - vector of the orientations e.g. [0 45 90 135]
%   thresholdFraction - what fraction of max(HoughVote) should be used for
%   thresholding the peaks
%   slidingDist - spacing between pixels for voting. not used at the moment. i.e = 1. 
%   barLength -
%   barWidth - 

% 1. set the threshold for peak detection separately per each orientation's max vote
% 2. extract all possible peaks for each orientation (thresholding)
% 3. non-max suppression in the defined neghborhoods
% 4. 

peaks3D = zeros(size(houghSpace3D));
[numRows numCols numOrientations] = size(houghSpace3D);

for i = 1:numOrientations
    % get max vote for this orientation
    maxVote = max(max(houghSpace3D(:,:,i)));
    thresh = maxVote*thresholdFraction;
    votes = houghSpace3D(:,:,i);
%     [r,c] = find(votes>thresh);
%     voteInd = sub2ind([numRows numCols],r,c);
    voteInd = find(votes>thresh);
    voteMat = zeros(numRows,numCols);
    
    voteMat(voteInd) = votes(voteInd);
    
    % peaks3D(:,:,i) = NMS_bars(voteMat,orientations(i),barLength,barWidth);
    peaks3D(:,:,i) = voteMat;
    
end