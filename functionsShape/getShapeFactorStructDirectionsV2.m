function [scale_struct, newPosShape, newInterpolationFactor,shape_struct]=...
    getShapeFactorStructDirectionsV2(estimatedShapeBB,pos,estimatedDepth,scale_struct,shape_struct)
%  GETSHAPEFACTORSTRUCTDIRECTIONSV2.m updates the shape struct according to
%  the detected changes
%
%   GETSHAPEFACTORSTRUCTDIRECTIONSV2 this function updates the shape struct
%   according to the detected changes
%
%   INPUT:
%  -estimatedShapeBB bounding box of the segmented object
%  -pos tracker predicted position
%  -estimatedDepth UNUSED argument, it is the mean depth value of the
%  object
%  -scaleDSKCF_struct,shapeDSKCF_struct data structure of shape and scale
%  information
%
%  OUTPUT: 
%  - updated scaleDSKCF_struct,shapeDSKCF_struct data structure of
%  shape and scale information
%  -newPosShape target centrouid position according to the segmented area
%  -newInterpolationFactor UNUSED VALUE, it is set to 0
%
%  See also INITDSKCFPARAM
%
%  University of Bristol
%  Massimo Camplani and Sion Hannuna
%
%  massimo.camplani@bristol.ac.uk
%  hannuna@compsci.bristol.ac.uk

%scaleDSKCF_struct.updated = 0;

%mode1 = estimatedDepthMode;
%scaleDSKCF_struct.currDepth = mode1;

%sf = scaleDSKCF_struct.InitialDepth / mode1;
%currentW=scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(1);
%currentH=scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(2);

newInterpolationFactor=0;

newPosShape=pos;
[centerX,centerY,width,height]=fromBBtoCentralPoint(estimatedShapeBB);
estimatedShapeSize=[height,width];
%newSize=sqrt(height*width);
newSize=height*width;

% Check for significant scale difference to current shape
%currentSize=sqrt(scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(1)*scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(2));
%initialSQsize=sqrt(scaleDSKCF_struct.InitialTargetSize(1)*scaleDSKCF_struct.InitialTargetSize(2));
currentSize=(scale_struct.target_sz(scale_struct.i).target_sz(1)*scale_struct.target_sz(scale_struct.i).target_sz(2));
initialSQsize=(scale_struct.InitialTargetSize(1)*scale_struct.InitialTargetSize(2));

shapeSF =  newSize/(initialSQsize);
shapeOffset =  shapeSF - scale_struct.scales(scale_struct.i);

%%NOW IF THE CHANGE IS NOT on the small side of the bounding box, check the
%%change on the large one... without really changing the square target area
if(shape_struct.growingStatus==false)
    
    
    if abs(shapeOffset) > scale_struct.minStep*0.93 %% Need to change scale if possible
        
        newPosShape=round([mean([centerY,pos(1)]),mean([centerX,pos(2)])]);
        %%update here segment Struct...
        shape_struct.growingStatus=true;
        
        shape_struct.segmentW=size(shape_struct.cumulativeMask,2);
        shape_struct.segmentH=size(shape_struct.cumulativeMask,1);
        
        %zero pad previous segmentations
        segmentWIncrement=round(0.05*shape_struct.segmentW);
        segmentHIncrement=round(0.05*shape_struct.segmentH);
        
        shape_struct.cumulativeMask=padarray(shape_struct.cumulativeMask,[segmentHIncrement segmentWIncrement]);
        %you need only from the second one...
        
        for i=1:size(shape_struct.maskArray,3)
            tmpMaskArray(:,:,i)=...
                padarray(shape_struct.maskArray(:,:,i),[segmentHIncrement segmentWIncrement]);
        end
        shape_struct.maskArray=tmpMaskArray;
        
    end
end

end