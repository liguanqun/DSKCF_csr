function [p, depthCurr,stdNew,depthEstimated,stEstimated,minIndexReduced,LabelReg,Centers,regionIndex,LUTCC,regionIndexOBJ] ...
    = checkOcclusionsDSKCF_noiseModel_CSR(depthMapCurr,noDataCurrent, tracker, bb)


bbPrev = tracker.pT.bb;
depthPrev = tracker.pT.meanDepthObj;

p=999;
depthCurr=depthPrev;


stdOLD=tracker.pT.stdDepthObj;
regionIndexOBJ=0;
if isempty(bb),
    stdNew=stdOLD;
    depthEstimated=depthPrev;
    stEstimated=stdOLD;
    minIndexReduced=1;
    LabelReg=[];
    Centers=[];
    regionIndex=0;
    LUT=[];
    
    return;
end

bbIn=bb;
bb=enlargeBB(bb ,0.05,size(depthMapCurr));

%caluclate area of the current bounding box
bbFinalArea=(tracker.cT.w)*(tracker.cT.h);


%extract the target roi, from the depth and the nodata mask
front_depth=roiFromBB(depthMapCurr,bb);
depthNoData=roiFromBB(noDataCurrent,bb);

%hard coded quadratic noise model of the Kinect according to
%M. Camplani, T. Mantecon, and L. Salgado. Depth-color fusion strategy for
%3-D scene modeling with Kinect. Cybernetics, IEEE Transactions on,
%43(6):1560�1571, 2013
noiseModelVector=[2.3,0.00055,0.00000235];

[LabelReg,Centers,LUT,H,I,LUTCC]=fastDepthSegmentationDSKCF_noiseModel_CSR...
    (front_depth,3,depthNoData,1,[-1,-1,-1],1,depthPrev,stdOLD,noiseModelVector);

%wrong segmentation....you must exit
if(isempty(LabelReg))
    p=0;
    depthCurr=depthPrev;
    stdNew=stdOLD;
    depthEstimated=depthPrev;
    stEstimated=stdOLD;
    minIndexReduced=0;
    regionIndex=0;
    return
end

%%clean very smallRegions....
tmpProp=regionprops(LabelReg,'Area');
areaList= cat(1, tmpProp.Area);
widthTarget=bbIn(4)-bbIn(2);
heightTarget=bbIn(3)-bbIn(1);
%  minArea=widthTarget*heightTarget*0.09;
minArea=widthTarget*heightTarget*0.15;%lgq 20180731

areaSmallIndex=areaList<minArea;
if(sum(areaSmallIndex)==length(areaList))
    areaSmallIndex=[];
end

%exclude the small area index setting a super high depth!!!!!!!!
%it will never be used
Centers(:,areaSmallIndex)= 1000000;

%%%%
[targetDepth,regionIndex]=min(Centers);

depthVector=double(front_depth(LabelReg==regionIndex));

targetStd=std(depthVector);
targetStd=max(2.5*calculateNoiseVar(targetDepth,noiseModelVector(1),noiseModelVector(2),noiseModelVector(3)),targetStd);
if(targetStd<5)
    targetStd=stdOLD;
end


%find closest peak to the old depth distribution
depthEstimated=[];
stEstimated=[];

selectionIndex=I>-10000;
%%%AGAIN THIS CONDITION SHOULD BE CHECKED.....IF IT IS REACHED SOMEHOW
if isnan(depthPrev),
    depthCurr=targetDepth;
    p=0;
else
    peakDistances=abs(Centers-depthPrev);
    [minDist, minIndex]=min(peakDistances);
    
    %register the plane index when you filtered out some small
    %regions....
    CentersReduced=Centers(Centers<1000000);
    peakDistancesReduced=abs(CentersReduced-depthPrev);
    [minDistReduced, minIndexReduced]=min(peakDistancesReduced);
    
    depthEstimated=targetDepth;
    stEstimated=targetStd;
    stEstimated=max(2.5*calculateNoiseVar(depthEstimated,noiseModelVector(1),noiseModelVector(2),noiseModelVector(3)),stEstimated);
    %check first if the main mode in previous frame is the first peak of the actual distribution
    if((minIndexReduced==1 && minDist<3*stdOLD))
        %%everything seems ok....no occluding object, just a movement
        %%of the object....update the depth!!!
        depthCurr=targetDepth;
        stdNew=mean([targetStd stdOLD]);
        selectionIndex=LUT~=LUTCC(minIndex);
        regionIndexOBJ=minIndex;
    else
        %%%% THERE IS AN OCCLUSION......WHAT TO DO?
        %%find the new corresponding region (if exist) and calculate
        if(minDist<2.5*stdOLD)
            depthCurr=Centers(minIndex);
            depthVector=double(front_depth(LabelReg==minIndex));
            stdNew=mean([std(depthVector) stdOLD]);
            selectionIndex=LUT~=LUTCC(minIndex);
            if(stdNew<5)
                stdNew=stdOLD;
            end
            regionIndexOBJ=minIndex;
        else
            depthCurr=depthPrev;
            stdNew=stdOLD;
        end
    end
    
    normN=H/bbFinalArea;
    %not only consider the closest points, but also remove the pixels
    %beloning to the target region....only in this way you can really
    %estimate p
    validIndex=I<(depthCurr-1.5*stdNew);
    validIndex=validIndex & selectionIndex;
    p=sum(normN(validIndex));
end
end


