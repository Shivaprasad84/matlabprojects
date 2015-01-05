function [newWS, removedWsIDs, invisibleEdgeLIDs] = getCorrectedWSregions...
                        (ws,removeEdgeIDs,edges2pixels)
% merges ws regions after removing removeEdgeIDs

% Inputs
%   ws - ws transform of the original image
%   removeEdgeIDs - edges to be removed from ws to merge regions
%   edges2pixels - first col has edgeID. other cols have pixelInds

% Outputs
%   newWS - new ws transform after merging ws region due to removal of
%   edges
%   removedWsIDs - list of removed ws region ids due to merging with larger regions
%       these correspond to original ws ids

removedWsIDs = [];
expandedWsIDs = [];
cell_mergedWsIDs_original = {};
newWS = ws;
edgeIDsAll = edges2pixels(:,1);
edgepixelsAll = edges2pixels;
edgepixelsAll(:,1) = [];
[sizeR,sizeC] = size(ws);
% for each removed edge
for i=1:numel(removeEdgeIDs)
% get the two ws regions on either side
    edgeListInd_i = find(edgeIDsAll==removeEdgeIDs(i));
    edgepixels_i = edgepixelsAll(edgeListInd_i,:);
    edgepixels_i = edgepixels_i(edgepixels_i>0);
    regionIDs = getRegionsForEdgePixels(ws,edgepixels_i,sizeR,sizeC);
    % regionIDs contain original wsIDs
% find the bigger region and assign its wsID to the smaller region except
% if its region 1 = border (takes precedence)
    if(ismember(1,regionIDs))
        % assign id 1 to the other region
        regionIDs = sort(regionIDs);
        newWS(ws==regionIDs(2)) = 1;
        removedWsIDs = [removedWsIDs regionIDs(2)];
        % assign the edge pixels also 1
        newWS(edgepixels_i) = 1;
        
    else
        % if one of the regions is already in the expandedWsIDs list, keep
        % expanding that. i.e. assign that id to the other
        if(ismember(regionIDs(1),expandedWsIDs))
            newWS(ws==regionIDs(2)) = regionIDs(1);
            removedWsIDs = [removedWsIDs regionIDs(2)];
            % assign the edge pixels also the ws id
            newWS(edgepixels_i) = regionIDs(1); 
            % update merged regions list
            mergedRegionInd = find(expandedWsIDs==regionIDs(1));
            oldWsID = getOldWsID(ws,newWS,regionIDs(2));
            cell_mergedWsIDs_original{mergedRegionInd}(end+1) = oldWsID;
            
        elseif(ismember(regionIDs(2),expandedWsIDs))
            newWS(ws==regionIDs(1)) = regionIDs(2);
            removedWsIDs = [removedWsIDs regionIDs(1)];
            % assign the edge pixels also the ws id
            newWS(edgepixels_i) = regionIDs(2); 
            % update merged regions list
            mergedRegionInd = find(expandedWsIDs==regionIDs(2));
            oldWsID = getOldWsID(ws,newWS,regionIDs(1));
            cell_mergedWsIDs_original{mergedRegionInd}(end+1) = oldWsID;            
        else
            newWS(ws==regionIDs(2)) = regionIDs(1);
            removedWsIDs = [removedWsIDs regionIDs(2)];
            % assign the edge pixels also the ws id
            newWS(edgepixels_i) = regionIDs(1);
            expandedWsIDs = [expandedWsIDs regionIDs(1)];
            % create new element for merged old ws id
            oldWsID = getOldWsID(ws,newWS,regionIDs(2));
            cell_mergedWsIDs_original{end+1} = [oldWsID ];
        end
    end

end

% if there are edges separating adjoining mergedWsIDs, make them invisible
% by assigning the same regionID to the edge

[newWS, invisibleEdgeLIDs] = fixEdgesBetweenMergedRegions(...
    newWS,cell_mergedWsIDs_original,ws,edges2pixels,expandedWsIDs);


function oldWsID = getOldWsID(ws,newWS,regionID)
% we already know that regionID is not an expandedRegion
wspixelVals = ws(ws==regionID);
wspixelVals = wspixelVals(wspixelVals>0);
oldWsID = unique(wspixelVals);
if(numel(oldWsID)>1)
    error('Error: getCorrectedWSregions: multiple oldWsIDs for same region')
elseif(numel(oldWsID)==0)
    error('Error: getCorrectedWSregions: no oldWsIDs for region')
end
