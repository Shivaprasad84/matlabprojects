function [faceAdj,edges2regions,setOfRegionsMat,twoRegionEdgeIDs,wsIDsForRegions]...
    = getFaceAdjFromWS(ws,edges2pixels,b_imWithBorder,boundaryEdgeIDs)
% For all the faces in WS, get the corresponding regionID.
% RegionID is the sequence number of each region in setOfRegions

% Inputs:
% ws - 
% edges2pixels,
% b_imWithBorder - boolean var. 1, if image has a thick border

% Outputs: 
%   faceAdj - adjacency graph of the faces of the input planar graph.
%   values are edgeIDs
%   edges2cells - each row corresponds to an edge. the two columns give you
%   the two cells that are connected by that edge. The order of edges
%   present is according to listOfEdgeIDs
%   setOfCellsMat - each row corresponds to a cell and contains the set of
%   edges bounding that cell as a row vector with zero padding.
%   listOfEdgeIDs - the edges considered in the faceAdjMatrix. Each of these edges
%   connects a pair of cells

edgeIdList = edges2pixels(:,1);
numEdges = numel(edgeIdList);
edgeUsage = zeros(numEdges,1);
numWsFaces = max(max(ws));
% initialize

if(b_imWithBorder)
    start = 2; % the first ws region is the border. ignore it.
else
    start = 1;
end

wsIDsForRegions = start:numWsFaces;
maxNumEdgesPerRegion = 0;
k = 0; % index for cells to store sets of edges of each region
for i=start:numWsFaces
    clear intPix_i edgePix_i edgeSet_i
    % get internal pixels
    intPix_i = (ws==i);
    % get edge pixels
    edgePix_i = getEdgePixForWsFace(intPix_i,ws);
    % get edges (edgeIDs)
    edgeIdSet_i = getEdgeSetFromEdgePixSet(edgePix_i,edges2pixels);
    k = k + 1;
    c_setOfRegions{k} = edgeIdSet_i'; 
    numEdgesInSet = numel(edgeIdSet_i);
    if(numEdgesInSet>maxNumEdgesPerRegion)
        maxNumEdgesPerRegion = numEdgesInSet; 
    end
    % keep track of edge usage
    edgeListInds_logical = ismember(edgeIdList,edgeIdSet_i);
    edgeCurrentUsage_i = edgeUsage(edgeListInds_logical);
    edgeUsageUpdated_i = edgeCurrentUsage_i + 1; % increment usage
    edgeUsage(edgeListInds_logical) = edgeUsageUpdated_i;
end

nonBoundaryEdgeListInds_logical = (edgeIdList ~= boundaryEdgeIDs);
nonBoundaryEdgeUsage = edgeUsage(nonBoundaryEdgeListInds_logical);
underUtilizedEdgeListInd_logical = (nonBoundaryEdgeUsage==1);
underUtilizedEdgeIDs = edgeIdList(underUtilizedEdgeListInd_logical);
% for each under utilized edge (appears only in one region), get the
% regions on either side by searching around and update c_setOfRegions{}
c_setOfRegions = updateRegionsWithInsideEdges(ws,c_setOfRegions,...
            underUtilizedEdgeIDs,edges2pixels);


setOfRegionsMat = zeros(numel(wsIDsForRegions),maxNumEdgesPerRegion);
for i=1:numel(wsIDsForRegions)
    setOfEdgesForRegion_i = c_setOfRegions{i};
    numEdgesInSet = numel(setOfEdgesForRegion_i);
    numZerosForPadding = maxNumEdgesPerRegion - numEdgesInSet;
    if(numZerosForPadding>0)
        % pad to the right
        zeroArray = zeros(1,numZerosForPadding);
        setOfEdgesForRegion_i = [setOfEdgesForRegion_i zeroArray];
    end
    setOfRegionsMat(i,:) = setOfEdgesForRegion_i;
end

% add the cellList (index) as the first col of setOfCells. This is done so
% that we can reuse getAdjacencyMat() to creage faceAdj.
setOfRegionsMat_2 = [wsIDsForRegions' setOfRegionsMat];
[faceAdj,edges2regions,~,twoRegionEdgeIDs] = getAdjacencyMat(setOfRegionsMat_2);


function edgePix = getEdgePixForWsFace(intPix,ws)

edgePix = [];

[sizeR, sizeC] = size(ws);
[r,c] = find(intPix);
topRow = min(r);
botRow = max(r);
leftCol = min(c);
rightCol = max(c);

% each row
for j=topRow:botRow
    row_j = find(intPix(j,:));
    lc_j = min(row_j);
    rc_j = max(row_j);
    eLeft = lc_j -1;
    if(eLeft>0 && ws(j,eLeft)==0)
        % it's an edge
        newPix = [j eLeft];
        edgePix = [edgePix; newPix];
    end
    eRight = rc_j +1;
    if(eRight<=sizeC && ws(j,eRight)==0)
        % it's an edge
        newPix = [j eRight];
        edgePix = [edgePix; newPix];
    end
end

% each col
for j=leftCol:rightCol
    col_j = find(intPix(:,j));
    tr_j = min(col_j);
    br_j = max(col_j);
    eTop = tr_j -1;
    if(eTop>0 && ws(eTop,j)==0)
        % it's an edge
        newPix = [eTop j];
        edgePix = [edgePix; newPix];
    end
    ebottom = br_j +1;
    if(ebottom<=sizeR && ws(ebottom,j)==0)
        % it's an edge
        newPix = [ebottom j];
        edgePix = [edgePix; newPix];
    end
end

edgePix = sub2ind([sizeR sizeC],edgePix(:,1),edgePix(:,2));
edgePix = unique(edgePix);

function edgeIDset = getEdgeSetFromEdgePixSet(edgePix,edges2pixels)
numEdgePix = numel(edgePix);
edgepixels = edges2pixels;
edgepixels(:,1) = [];
[x1,x2] = ismember(edgepixels,edgePix);
x1sum = sum(x1,2); % sum each row
edgeIDset = edges2pixels((x1sum>0),1);

function c_setOfRegions = updateRegionsWithInsideEdges(ws,c_setOfRegions,...
            underUtilizedEdgeIDs,edges2pixels)
numUEdges = numel(underUtilizedEdgeIDs);
edgepixels = edges2pixels;
edgepixels(:,1) = [];
for i=1:numUEdges
    edgeListInd_logical = (edges2pixels(:,1)==underUtilizedEdgeIDs(i));
    edgePix = edgepixels(edgeListInd_logical,:);
    edgePix = edgePix(edgePix>0);
    pixIndsAroundEdge = getPixIndsAroundEdge(ws,edgePix);
    regionIDsAroundEdge = ws(pixIndsAroundEdge) + 1;
    regionIDsAroundEdge = unique(regionIDsAroundEdge); 
    regionIDsAroundEdge = regionIDsAroundEdge(regionIDsAroundEdge>0);
    numRegionsAround = numel(regionIDsAroundEdge);
    if(numRegionsAround>2)
        disp('PROBLEM! getFaceAdjFromWS. too many regions detected around edge')
    else
        for j=1:numRegionsAround
            % get the relevent entry in c_setOfRegions
        end
        
    end
end

function pixIndsAroundEdge = getPixIndsAroundEdge(ws,edgePix)
% returns pixInds that belong to ws regions around a certain edgePixel
[sizeR,sizeC] = size(ws);
numEdgePix = numel(edgePix);

if(numEdgePix>2)
    [r,c] = ind2sub([sizeR sizeC],edgePix(2));
else
    [r,c] = ind2sub([sizeR sizeC],edgePix(1));
end

r1 = r+1;
c1 = c+1;
r2 = r-1;
c2 = c-1;

p = zeros(8,1);
% all pix inds around one edge pixel selected above
p(1) = sub2ind([sizeR sizeC],r,c1);
p(2) = sub2ind([sizeR sizeC],r,c2);
p(3) = sub2ind([sizeR sizeC],r1,c);
p(4) = sub2ind([sizeR sizeC],r1,c1);
p(5) = sub2ind([sizeR sizeC],r1,c2);
p(6) = sub2ind([sizeR sizeC],r2,c);
p(7) = sub2ind([sizeR sizeC],r2,c1);
p(8) = sub2ind([sizeR sizeC],r2,c2);

ws_p = ws(p);
regionPixels_logical = (ws_p>1);


pixIndsAroundEdge = find(regionPixels_logical);
