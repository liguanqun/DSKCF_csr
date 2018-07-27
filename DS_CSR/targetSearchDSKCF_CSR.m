function [tarBB, occBB, tarlist, id,occmask] = targetSearchDSKCF_CSR(bb,...
    tracker, DSpara,im,depth,depth16Bit,scale_struct,confValue)

tarBB = [];
occBB=[];
id=[];

bbIn=bb;
bb=enlargeBB(bb ,0.05,size(im));

%%take Bounding box and mask from the previous segmentation!!!!!
occmask=tracker.cT.LabelRegions==tracker.cT.regionIndex;
centersEstimated=tracker.cT.Centers;
tarBBProp=regionprops(occmask,'BoundingBox','Area');

%one single big region....just take the bounding box
if(length(tarBBProp)==1)
    occBB=tarBBProp.BoundingBox;
    %use extrema points.....
    occBB=ceil([occBB(1), occBB(2),occBB(1)+occBB(3),occBB(2)+occBB(4)]);
    %and recenter to the entire image coordinate
    occBB([1 3])=occBB([1 3])+bb(1);
    occBB([2 4])=occBB([2 4])+bb(2);
    %else select the biggest one
elseif(length(tarBBProp)>1)
    areas= cat(1, tarBBProp.Area);
    [maxV,maxIndex]=max(areas);
    occBB=tarBBProp(maxIndex).BoundingBox;
    occBB=ceil([occBB(1), occBB(2),occBB(1)+occBB(3),occBB(2)+occBB(4)]);
    
    occBB([1 3])=occBB([1 3])+bb(1);
    occBB([2 4])=occBB([2 4])+bb(2);
    
else
    %EMPTY AREA....
    occBB=[];
end

occBB=occBB';

%retrieve the list of possible candidates according to the segmentation
[tarBBList, areaList] = regionSegmentsFast( tracker.cT.LabelRegions,bb);

%exclude the occluding index!!!!!!!!
if(tracker.cT.regionIndex~=6666666)
    tarBBList(:,tracker.cT.regionIndex) = [];
    areaList(tracker.cT.regionIndex)= [];
    centersEstimated(tracker.cT.regionIndex) =[];
end

minArea=tracker.cT.w*...
    tracker.cT.h*0.05;
areaSmallIndex=areaList<minArea;
%exclude the small area index!!!!!!!!
tarBBList(:,areaSmallIndex) = [];
areaList(areaSmallIndex)= [];
centersEstimated(areaSmallIndex)=[];

%for each target bb caculate confidience
tarlist = struct('bb',[],'Conf_color',[],'Conf_class',[]);
num_tar = size(tarBBList,2);
if isempty(tarBBList),
    %disp('total occ');
else
    tarlist.bb=nan(4,num_tar);
    tarlist.Conf_class=nan(1,num_tar);
    tarlist.Area=nan(1,num_tar);
    
    smoothFactorD_vector=[];
    for j=1:size(tarBBList,2),
        %conf  = hogGetConf(tarBBList(:,j), featurePym, svm);
        tmpBB=tarBBList(:,j);
        tmpWidthTarget=tmpBB(3)-tmpBB(1)+1;
        tmpHeightTarget=tmpBB(4)-tmpBB(2)+1;
        tmpCenter=ceil([tmpBB(1)+tmpWidthTarget/2 tmpBB(2)+tmpHeightTarget/2]);
        
        %take image patch....
        patch = get_subwindow(im, tmpCenter(2:-1:1), scale_struct.windows_sizes(scale_struct.i).window_sz);
        patch_depth = get_subwindow(depth, tmpCenter(2:-1:1), scale_struct.windows_sizes(scale_struct.i).window_sz);
        
        [ response, maxResponse, maxPositionImagePlane] = maxResponseDSKCF_CSR...
            ( patch,patch_depth,tmpCenter(2:-1:1),DSpara.cell_size,scale_struct.cos_windows(scale_struct.i).cos_window,...
           DSpara.w2c,tracker.chann_w,tracker.H,size(im,1),size(im,2));
        
        %now maxPositionImagePlane has row index and column index so.....
        smoothFactorD=weightDistanceLogisticOnDepth(tracker.cT.meanDepthObj,...
            double(depth16Bit(maxPositionImagePlane(1),maxPositionImagePlane(2))),...
            tracker.cT.stdDepthObj);
        smoothFactorD_vector=[smoothFactorD_vector,smoothFactorD];
        
        conf=maxResponse*smoothFactorD;
        
        reEstimatedBB(1:2)=maxPositionImagePlane(2:-1:1) - [tmpWidthTarget,tmpHeightTarget]/2;
        reEstimatedBB(3:4)=maxPositionImagePlane(2:-1:1) + [tmpWidthTarget,tmpHeightTarget]/2;
        
        tarlist.bb(:,j)=reEstimatedBB;
        tarlist.Conf_class(j)= conf;
        
    end
    %output the most possible target BB
    idx =  tarlist.Conf_class>-999;
    tarlist.bb=tarlist.bb(:,idx);
    tarlist.Conf_class=tarlist.Conf_class(idx);
    
    if sum(idx(:))>0,
        [conf,id]=max(tarlist.Conf_class);
        if(smoothFactorD_vector(id)~=0)
            conf=conf/smoothFactorD_vector(id);
        end
        tarlist.Conf_class=tarlist.Conf_class./smoothFactorD_vector;
        tarlist.Conf_class(isnan(tarlist.Conf_class))=0;
        %if ~isempty(id)&&conf>0.3*svm.thr, tarBB=tarlist.bb(:,id);end
        if ~isempty(id)&&conf>confValue, tarBB=tarlist.bb(:,id);end
    end
end

end

function res=sigmFunction(x,A,K,Q,ni,B,M)

res=A+(K-A)./((1+Q*exp(-B*(x-M))).^(1/ni));

end

function smoothFactor=weightDistanceLogisticOnDepth(targetDepth,candidateDepth,targetSTD)

%smoothFactor=1;
dist=abs((targetDepth-candidateDepth))/(3*targetSTD);

Q=1;
ni=0.5;
B=3.2;
M=1.94;
%              sigmFunction(x,A,K,Q,ni,B,M)
smoothFactor=(1-sigmFunction(dist,0,1,Q,ni,B,M));

end