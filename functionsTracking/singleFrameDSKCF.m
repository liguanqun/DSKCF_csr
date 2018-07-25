function [pos,tracker,tracker_Occ,scale_struct, DSpara_Occ,segmentedMASK,shape_struct]=...
    singleFrameDSKCF(firstFrame,pos,frameCurr,tracker,DSpara,scale_struct,tracker_Occ,DSpara_Occ,shape_struct)

im=frameCurr.gray;
imRGB=frameCurr.rgb;
depth=frameCurr.depth;
noData=frameCurr.depthNoData;
depth16Bit=frameCurr.depth16Bit;

%hard coded threshold for DS-KCF algorithm see [1] for more details
confInterval1=0.4;
confInterval2=0.15;
confValue3=0.14;

cScale=scale_struct.i;

%把target结构中 关于当前目标的状态清空 在新的循环中重新赋值
tracker=resetDSKCFtrackerInfo(tracker);
changeOfShapeFlag=false;
segmentedMASK=repmat(0,size(depth));


%This is not the first frame we can start tracking!!!!!!!!!!
if(firstFrame==false)
    
    %no occlusion case 非遮挡的情况
    if ~tracker.pT.underOcclusion,
            %track the object and then check for occlusions  跟踪目标并且检查是否遮挡
        patch = get_subwindow(im, pos, scale_struct.windows_sizes(cScale).window_sz);
        patch_depth = get_subwindow(depth, pos, scale_struct.windows_sizes(cScale).window_sz);
        
        %calculate response of the DS-KCF tracker 计算DSKCF的response
        [response, maxResponse,pos]=maxResponseDepthWeightDSKCF(patch,patch_depth,depth16Bit,...
            DSpara.features,DSpara.kernel,pos,DSpara.cell_size, scale_struct.cos_windows(cScale).cos_window,...
            tracker.model_xf,tracker.model_alphaf, tracker.model_xDf,tracker.model_alphaDf, tracker.pT.meanDepthObj,tracker.pT.stdDepthObj);
        
        %update tracker struct, new position etc 更新 tracker 结构
        tracker.cT.posX=pos(2);
        tracker.cT.posY=pos(1);
        
        tracker.cT.bb=fromCentralPointToBB (tracker.cT.posX,tracker.cT.posY, tracker.cT.w,tracker.cT.h, size(im,2),size(im,1));
        
        tracker.cT.conf=max(response(:));%use this one, discard the weight...
        
        %segment the depth data inside the tracked region在跟踪区域分割深度图
        [p, tracker.cT.meanDepthObj,tracker.cT.stdDepthObj,estimatedDepth,estimatedSTD,...
            minIndexReduced,tracker.cT.LabelRegions,tracker.cT.Centers,tracker.cT.regionIndex,tracker.cT.LUT,regionIndexOBJ] =...
            checkOcclusionsDSKCF_noiseModel(depth16Bit,noData,tracker, tracker.cT.bb);
        

        %  如果分割的目标在前景中，使用当前的bounding box 否则的话使用深度图目标分割提供的
        if(regionIndexOBJ==0 )
            tracker.cT.segmentedBB=tracker.cT.bb';
        else
            tmpProp=regionprops(tracker.cT.LabelRegions==regionIndexOBJ,'BoundingBox');
            tmpBB=tmpProp.BoundingBox;
            %tmpCentroid=tmpProp.Centroid;
            tracker.cT.segmentedBB=ceil([tmpBB(1), tmpBB(2),tmpBB(1)+tmpBB(3),tmpBB(2)+tmpBB(4)]);
           
            tmpOffset=enlargeBB(tracker.cT.bb ,0.05,size(depth16Bit));
           
            tracker.cT.segmentedBB([1,3])= +tracker.cT.segmentedBB([1,3]) +tmpOffset(1);
           
            tracker.cT.segmentedBB([2,4])=+tracker.cT.segmentedBB([2,4])+tmpOffset(2);
            
            tmpBBforSeg=enlargeBB(tracker.cT.bb ,0.05,size(depth16Bit));
            
            %generate a out of bound rect is necessary
            outOfBoundBB=enlargeBB(tracker.cT.bb ,0.05,5*size(depth16Bit));
            
            outOfBoundSize=[outOfBoundBB(4)-outOfBoundBB(2)+1,outOfBoundBB(3)-outOfBoundBB(1)+1];
            
            [tmpMask,insidePatchIndexes,finalMask]=extractSegmentedPatchV3(tracker.cT.LabelRegions==regionIndexOBJ,...
                outOfBoundSize,[tracker.cT.posX,tracker.cT.posY],...
                shape_struct,[size(depth16Bit,2),size(depth16Bit,1)]);
            
            if(shape_struct.growingStatus==false)
                shape_struct=addSegmentationResults(shape_struct,tmpMask,tmpBBforSeg,tmpOffset,size(depth16Bit));
            else
                %in case region is growing....then resegment....
                %segment the depth data inside the tracked region
                %take the new bb
                newSegmentBB=fromCentralPointToBB(tracker.cT.posX, tracker.cT.posY,shape_struct.segmentW,...
                    shape_struct.segmentH,size(im,2),size(im,1));
                
                [pNEW, newMean,newSTD,newEstimatedDepth,newEstimatedSTD,newMinIndexReduced,...
                    newLabelRegions,newCenters,newRegionIndex,newLUT,newRegionIndexOBJ] = ...
                    checkOcclusionsDSKCF_noiseModel(depth16Bit,noData,tracker, newSegmentBB);
                
                [depthDistance,depthIndex]=min(abs(newCenters - tracker.cT.meanDepthObj));
                
                newLabelData=newLabelRegions==depthIndex;
                
                tmpProp=regionprops(newLabelData,'BoundingBox');
                if(isempty(tmpProp)==true)
                    tmpBB=tracker.cT.segmentedBB;
                    newLabelData=zeros(size(shape_struct.cumulativeMask));
                else
                    tmpBB=tmpProp.BoundingBox;
                    %end
                    
                    %tmpCentroid=tmpProp.Centroid;
                    tracker.cT.segmentedBB=ceil([tmpBB(1),tmpBB(2),tmpBB(1)+tmpBB(3),tmpBB(2)+tmpBB(4)]);
                    
                    tmpOffset=enlargeBB(newSegmentBB ,0.05,size(depth16Bit));
                    
                    tracker.cT.segmentedBB([1,3])= +tracker.cT.segmentedBB([1,3])+tmpOffset(1);
                    
                    tracker.cT.segmentedBB([2,4])=+tracker.cT.segmentedBB([2,4])+tmpOffset(2);
                end
                
                tmpBBforSeg=enlargeBB(newSegmentBB ,0.05,size(depth16Bit));
                outOfBoundBB=enlargeBB(newSegmentBB,0.05,5*size(depth16Bit));%generate a out of bound rect is necessary
                outOfBoundSize=[outOfBoundBB(4)-outOfBoundBB(2)+1,outOfBoundBB(3)-outOfBoundBB(1)+1];
                
                [tmpMask,insidePatchIndexes,finalMask]=extractSegmentedPatchV3(newLabelData,...
                    outOfBoundSize,[tracker.cT.posX,tracker.cT.posY], shape_struct,[size(depth16Bit,2),size(depth16Bit,1)]);          
               
                shape_struct=addSegmentationResults(shape_struct,tmpMask,tmpBBforSeg,...
                    tmpOffset,size(depth16Bit));
            end
            
            %CUMULATIVE SEGMENTATION...
            tmpBBforSegCumulative=shape_struct.cumulativeBB;
            
            sizeOfSegmenter=(tmpBBforSegCumulative(3)-tmpBBforSegCumulative(1)) *...
                (tmpBBforSegCumulative(4)-tmpBBforSegCumulative(2));
            
            sizeOfTarget=(tracker.cT.bb(3)- tracker.cT.bb(1))*(tracker.cT.bb(4) -tracker.cT.bb(2));
            %%sizeOfSegmenter=
            accumulatedSEGBool=size(shape_struct.maskArray,3)==(shape_struct.slidingWindowSize);
            sr = scale_struct.InitialDepth / scale_struct.currDepth;
            targ_sz = round(scale_struct.InitialTargetSize * sr);
            %invert the coordinate as you need to combine this with positions
            srSize= targ_sz([2,1]);
            cScaleBB=[pos(:,[2,1]) - srSize/2, pos(:,[2,1]) + srSize/2];
            
            tracker.cT.segmentedBB=cScaleBB;
            
            %No data percentage
            depthNoData=roiFromBB(noData,tracker.cT.bb);
            noDataPercent=sum(sum(depthNoData))<0.4*sizeOfTarget;
            
            %minimunSize check
            minSizeOK=(sizeOfSegmenter>39*39);
            if(minSizeOK==0)
                
                minSizeOK= (tmpBBforSegCumulative(3)-tmpBBforSegCumulative(1)>39)...
                    ||(tmpBBforSegCumulative(4)-tmpBBforSegCumulative(2)>39);
            end
            [tmpBBforSegCumulative,shape_struct,changeOfShapeFlag,newOutput]=regionModificationCheck...
                (sizeOfSegmenter,sizeOfTarget, accumulatedSEGBool,noDataPercent,minSizeOK,tmpBBforSegCumulative,...
                shape_struct,size(depth16Bit),tracker);
            %if it is not changed the target bb is used
            if(newOutput)
                tracker.cT.segmentedBB=tmpBBforSegCumulative(:)';
            end
            
        end
        %occlusion condition  遮挡条件 
        tracker.cT.underOcclusion = abs(p)>0.35 && tracker.cT.conf<confInterval1;
        
        if ~tracker.cT.underOcclusion
            %eventually correct the frameCurr.targetDepthFast
            if(tracker.cT.meanDepthObj~=estimatedDepth && minIndexReduced==1)
                tracker.cT.meanDepthObj=estimatedDepth;
                tracker.cT.stdDepthObj=estimatedSTD;
            end
        end
        
        
        %当前处于遮挡，分割出遮挡物体，并且初始化 这遮挡物额跟踪器
        if tracker.cT.underOcclusion,
            % initialize occlusion
            [tmpOccBB] = occludingObjectSegDSKCF(depth16Bit,tracker);
            
            if (isempty(tmpOccBB) | isnan(tmpOccBB) )
                tracker.cT.underOcclusion = 0;
            else
                if tracker.cT.conf <0.15,
                    tracker.cT.bb = [];
                end
                tracker.cT.occBB = tmpOccBB;
            end
            
            %occlusion detected......is time to fill the struct
            %for the occluder we not use any change of scale or other
            %occlusion detector!!!! so now you have to re-init it,
            %according to the new patch size etc etc
            
            if (isempty(tmpOccBB)==false)
                
                %delete cumulative Mask
                shape_struct=initDSKCFshape(5,0);
                %assign the occluding bb to the occluder data struct
                tracker_Occ.pT.bb=tmpOccBB;
                
                [tracker_Occ.pT.posX, tracker_Occ.pT.posY, tracker_Occ.pT.w,tracker_Occ.pT.h]...
                    =fromBBtoCentralPoint(tmpOccBB);
                
                tracker_Occ.target_sz= [tracker_Occ.pT.h,  tracker_Occ.pT.w];
                
                tracker_Occ.window_sz = floor( tracker_Occ.target_sz * (1 + DSpara_Occ.padding));
                
                tracker_Occ.output_sigma = sqrt(prod(tracker_Occ.target_sz)) * DSpara_Occ.output_sigma_factor /DSpara_Occ.cell_size;
                
                tracker_Occ.yf = fft2(gaussian_shaped_labels( tracker_Occ.output_sigma, floor(...
                    tracker_Occ.window_sz / DSpara_Occ.cell_size)));
                
                %store pre-computed cosine window
                tracker_Occ.cos_window = hann(size( tracker_Occ.yf,1)) * hann(size( tracker_Occ.yf,2))';
                
                [tracker_Occ]=singleFrameDSKCF_occluder(1,im,depth,tracker_Occ,DSpara_Occ);
                
                %update target size in the current object tracker
                tracker_Occ.cT=tracker_Occ.pT;
            end
        end
        
 
        
    else  %PREVIOUS FRAME UNDER OCCLUSION....上一帧处于遮挡状态     跟踪遮挡物
        [tracker_Occ,occludedPos]=singleFrameDSKCF_occluder(0,im,depth,tracker_Occ,DSpara_Occ);
        
        %update occluder previous position for tracking...
        tracker_Occ.pT.posX= tracker_Occ.cT.posX;
        tracker_Occ.pT.posY= tracker_Occ.cT.posY;
        
        
        if isempty(tracker_Occ.cT.bb),
            tracker_Occ.cT.bb =  tracker_Occ.pT.bb;
        end
        %then update the previous
        tracker_Occ.pT.bb=  tracker_Occ.cT.bb;
        
        %update occluder bb in the main target
        tracker.cT.occBB=tracker_Occ.cT.bb;

        %enlarge searching reagion...扩大搜索区域
        if(isempty(tracker.pT.bb)==false)
            extremaBB=[min([tracker.cT.occBB(1),  tracker.pT.occBB(1), tracker.pT.bb(1)]), min([tracker.cT.occBB(2),...
                tracker.pT.occBB(2), tracker.pT.bb(2)]),max([tracker.cT.occBB(3),tracker.pT.occBB(3),...
                tracker.pT.bb(3)]), max([tracker.cT.occBB(4), tracker.pT.occBB(4), tracker.pT.bb(4)])];
            
            extremaBB=[max(extremaBB(1),1),max(extremaBB(2),1), min(extremaBB(3),size(im,2)),min(extremaBB(4),size(im,1))];
        else
            extremaBB=[min(tracker.cT.occBB(1), tracker.pT.occBB(1)), min(tracker.cT.occBB(2), tracker.pT.occBB(2)),...
                max(tracker.cT.occBB(3), tracker.pT.occBB(3)),max(tracker.cT.occBB(4), tracker.pT.occBB(4))];
            extremaBB=[max(extremaBB(1),1),max(extremaBB(2),1), min(extremaBB(3),size(im,2)),min(extremaBB(4),size(im,1))];
            
        end
        
        %bbIn=framePrev.occBB;
        bbIn=extremaBB;
        bbIn=enlargeBB(bbIn ,0.05,size(noData));
        
        %extract the target roi, from the depth and the nodata mask
        front_depth=roiFromBB(depth16Bit,bbIn);
        depthNoData=roiFromBB(noData,bbIn);
        
        %in case of bounding box with no depth data....
        if(sum(sum(depthNoData)')==size(front_depth,1)*size(front_depth,2))
            tracker.cT.LabelRegions=depthNoData>10000000;
            tracker.cT.Centers=1000000;
            tracker.cT.LUT=[];
            %eventually segment the current occluding area
        else
            %note, we are saving the segmentation of the occluding region,
            %in the target struct rather thant the other one!!!!!
            [tracker.cT.LabelRegions, tracker.cT.Centers, tracker.cT.LUT,~,~,~]=...
                fastDepthSegmentationDSKCF_noiseModel(front_depth,3,depthNoData, 1,[-1 -1 -1],...
                1,tracker.cT.meanDepthObj, tracker.cT.stdDepthObj,[2.3,0.00055,0.00000235]);
            
        end
        
        %filter out very small regions过滤掉小面积的区域
        tmpProp=regionprops(tracker.cT.LabelRegions,'Area');
        areaList= cat(1, tmpProp.Area);
        minArea=scale_struct.target_sz(cScale).target_sz(2)*scale_struct.target_sz(cScale).target_sz(1)*0.05;
        
        areaSmallIndex=areaList<minArea;
        
        %exclude the small area index setting a super high depth!!!!!!!!
        %it will never be used
        tracker.cT.Centers(:,areaSmallIndex)= 1000000;
        
        [dummyVal,tracker.cT.regionIndex]=...
            min(tracker.cT.Centers);
        
        %very bad segmentation, full of small regions. Set up a flag....
        if(dummyVal==1000000)
            tracker.cT.regionIndex=6666666;
        end
        
        %search for target's candidates in the search region.....在搜索区域寻找目标的候选块
        [tarBB, segmentedOccBB, targetList, targetIndex,occmask] = targetSearchDSKCF(bbIn, tracker, DSpara,...
            im,depth,depth16Bit,scale_struct,confValue3);
        tarBBSegmented=[];
        if(isempty(segmentedOccBB)==false)
            extremaBB=[min([tracker.cT.occBB(1),segmentedOccBB(1)]),min([tracker.cT.occBB(2),...
                segmentedOccBB(2)]),max([tracker.cT.occBB(3),segmentedOccBB(3)]),max([tracker.cT.occBB(4),...
                segmentedOccBB(4)])];
            
            tracker.cT.occBB=[max(extremaBB(1),1), max(extremaBB(2),1),min(extremaBB(3),size(im,2)),...
                min(extremaBB(4),size(im,1))]';
            
        end
        
        if(isempty(tracker.cT.occBB))
            tracker.cT.occBB=tracker.pT.occBB;
        end
        
        %THESE CANDIDATES....CAME FROM THE SEGMENTATIONS....YOU NEED TO
        %RESIZE THEM WITH THE REQUIRED WINDOW...
        centerNew=[];
        if(~isempty(tarBB))
            tarBBSegmented=tarBB;
            widthtarBB=tarBB(3)-tarBB(1);
            heighttarBB=tarBB(4)-tarBB(2);
            centerNew=floor([tarBB(1)+widthtarBB/2 tarBB(2)+heighttarBB/2]);
            
            tarBB(1:2)=centerNew - scale_struct.target_sz(scale_struct.i).target_sz([2 1])/2;
            tarBB(3:4)=centerNew + scale_struct.target_sz(scale_struct.i).target_sz([2 1])/2;
            
        end
        
        
        % calculate detection and segmentation consistency
        tracker.cT.bb = tarBB;
        tracker.cT.conf = targetList.Conf_class(targetIndex);
        tracker.cT.segmentedBB = tarBB';
        
        
        %%Kill some strange respons on the occluding mask
        occmask = imfill(occmask,'holes');
        tmpMask=repmat(0,size(depth));
        tmpMask(bbIn(2):bbIn(4),bbIn(1):bbIn(3))=occmask;
        
        if(isempty(centerNew)==false)
            
            %re-assign new position to the target, even if the target is
            %not valid, you need this just for visualization or checking
            %the algorithm....
            [tracker.cT.posX, tracker.cT.posY, tracker.cT.w,tracker.cT.h]=fromBBtoCentralPoint(tracker.cT.bb);
            %update tracker struct, new position etc
            pos(2)=tracker.cT.posX;
            pos(1)=tracker.cT.posY;
            
            if(tmpMask(centerNew(2),centerNew(1))==1)
                tracker.cT.conf=0;
            end
        end
        
        % check recovery
        tracker.cT.underOcclusion =1;
        if ~isempty(tracker.cT.bb)
            [p, TMpTDepth,TMpTStd,TMPLabelRegions,TMPCenters,...
                TMPregionIndex,TMPLUT,secondPlaneDepth,secondPlaneDepthStd] ...
                = checkOcclusionsDSKCF_secondPlane(depth16Bit,noData,tracker, tracker.cT.bb);
            
            if tracker.cT.conf > confInterval1/2 && p<0.35,
                tracker.cT.underOcclusion =0;
                tracker.cT.segmentedBB = tarBBSegmented';
            end
            
            if ~tracker.cT.underOcclusion,
                tmpWeight = max(0,min(1,tracker.cT.conf));
                
            else
                tmpWeight = 0;
            end
            
            
            if(isempty(secondPlaneDepth)==false)
                TMpTDepth=secondPlaneDepth;
                TMpTStd=secondPlaneDepthStd;
                tmpWeight=tmpWeight*2.5;
                if(tmpWeight>1)
                    tmpWeight=0.95;
                end
                
            end
            
            tracker.cT.meanDepthObj = tmpWeight * TMpTDepth + (1-tmpWeight) * tracker.cT.meanDepthObj;
            tracker.cT.stdDepthObj = tmpWeight * TMpTStd + (1-tmpWeight) * tracker.cT.stdDepthObj;
            
        else
            tracker.cT.meanDepthObj = tracker.pT.meanDepthObj;
            tracker.cT.stdDepthObj = tracker.pT.stdDepthObj;
        end
        
   
    end
    
    
end  %if(firstFrame==false)
%  更新阶段
%IF UNDER OCCLUSION DON'T UPDATE.....
if(tracker.pT.underOcclusion==false && tracker.cT.underOcclusion==false)
    
    additionalShapeInterpolation=0;
    %check for scale change检查尺度变化
    if(firstFrame==false)
        scale_struct=getScaleFactorStruct(tracker.cT.meanDepthObj,scale_struct);
        if(changeOfShapeFlag && scale_struct.updated==false)
               [scale_struct,newPosShape,additionalShapeInterpolation,shape_struct]=...
                   getShapeFactorStructDirectionsV2(tracker.cT.segmentedBB,pos, tracker.cT.meanDepthObj,scale_struct,shape_struct);
        end
    end
    
    %obtain a subwindow for training at newly estimated target position
    patch = get_subwindow(im, pos, scale_struct.windows_sizes(scale_struct.i).window_sz);
    patch_depth = get_subwindow(depth, pos, scale_struct.windows_sizes(scale_struct.i).window_sz);
    
    %根据尺度的变化 选择相应的目标函数
    detWf=scale_struct.yfs(scale_struct.i).yf;%fft2(detW);
    %update the model更新模型
    [tracker.model_alphaf, tracker.model_alphaDf, tracker.model_xf, tracker.model_xDf]=...
        modelUpdateDSKCF(firstFrame,patch,patch_depth,DSpara.features,...
        DSpara.cell_size,scale_struct.cos_windows(scale_struct.i).cos_window,DSpara.kernel,detWf,...
        DSpara.lambda,tracker.model_alphaf, tracker.model_alphaDf,tracker.model_xf,...
        tracker.model_xDf,scale_struct.updated,DSpara.interp_factor+additionalShapeInterpolation);
    
    %if scale changed you must change tracker size information
    %更新尺度的变化
    if(scale_struct.updated)
        %[newH,newW]= ;
        tracker.cT.h=scale_struct.target_sz(scale_struct.i).target_sz(1);
        tracker.cT.w=scale_struct.target_sz(scale_struct.i).target_sz(2);
        
        %reinit tracker shape
        relativeShapeScaleFactor=0;
        if(shape_struct.growingStatus==true)
            relativeShapeScaleFactor=1+(scale_struct.i-scale_struct.iPrev)*scale_struct.step;
            %shapeScaleFactor=scaleDSKCF_struct
        end
        shape_struct=initDSKCFshape(5,relativeShapeScaleFactor,shape_struct);
        
    end
    
else
    %%THERE IS AN OCCLUSION.....NOW WHAT TO DO.....? DON'T UPDATE MODEL....
    %UPDATE ONLY POSITION!!!!!
    %遮挡情况下，不更新模型 只更新位置
    % TO BE CHECKEDD!!!!!
    if(isempty(tracker.cT.bb))
        pos=[];
    else
        pos=[tracker.cT.posY,tracker.cT.posX];
    end
end

end