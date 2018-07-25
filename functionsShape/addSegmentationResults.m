function [ shape_struct ] = addSegmentationResults( shape_struct,lastMask,tmpBB,trackOffset,imSize)
% ADDSEGMENTATIONRESULTS.m function manage the alignment of segmented
% patches to accumulate object binary masks as in [1]
%
%
%   ADDSEGMENTATIONRESULTS is used to accumulate the segmented target
%   masks and align them correctly in case of target close to the borders
%   for example or change in scale while those silhouette are accumulated
%
%   INPUT:
%   - lastMask   segmented binary mask of the current frame processed by
%   EXTRACTSEGMENTEDPATCHV3 to be accumulated with the other masks as in
%   [1] without any errors due to change of shape or false segmentation,
%   masks are centered and then accumulated
%   - tmpBB  bounding box containing the segmented patch in the format
%   [topLeftX, topLeftY, bottomRightX, bottomRightY] read as
%   [columnIndexTopLeft, rowIndexTopLeft, columnIndexBottomRight,
%   rowIndexBottomRight]  
%   - trackOffset boundinbox of patch in case of offset
%   -dskcfShapeStruct data structure containing shape information (see INITDSKCFSHAPE) 
%   - imSize image size
%   OUTPUT
%   -dskcfShapeStruct modified data structure containing shape information (see INITDSKCFSHAPE) 
%
%  See also INITDSKCFSHAPE, EXTRACTSEGMENTEDPATCHV3
%
%
%  [1] S. Hannuna, M. Camplani, J. Hall, M. Mirmehdi, D. Damen, T.
%  Burghardt, A. Paiement, L. Tao, DS-KCF: A real-time tracker for RGB-D
%  data, Journal of Real-Time Image Processing
%
%
%  University of Bristol
%  Massimo Camplani and Sion Hannuna
%
%  massimo.camplani@bristol.ac.uk
%  hannuna@compsci.bristol.ac.uk

shape_struct.lastSegmentedBB=tmpBB;

if(isempty(shape_struct.cumulativeBB))
    
    shape_struct.cumulativeBB=shape_struct.lastSegmentedBB;
    shape_struct.maskArray=cat(3,shape_struct.maskArray,lastMask);
    shape_struct.cumulativeMask=lastMask;
else
    %%subtract
    if(size(shape_struct.maskArray,3)<(shape_struct.slidingWindowSize))
        shape_struct.maskArray=cat(3,shape_struct.maskArray,lastMask);
        shape_struct.cumulativeMask=shape_struct.cumulativeMask | lastMask;
    else
        shape_struct.maskArray=cat(3,shape_struct.maskArray(:,:,2:shape_struct.slidingWindowSize),lastMask);
        shape_struct.cumulativeMask=shape_struct.maskArray(:,:,1);
        for i=2:size(shape_struct.maskArray,3)
            shape_struct.cumulativeMask=shape_struct.cumulativeMask | shape_struct.maskArray(:,:,i);
        end
    end
    tmpProp=regionprops(shape_struct.cumulativeMask,'BoundingBox','area');
    areaList= cat(1, tmpProp.Area);
    [maxV,maxI]=max(areaList);
    if(isempty(areaList))
        tmpBB=shape_struct.cumulativeBB;
    else
        tmpBB=tmpProp(maxI).BoundingBox;
        tmpBB=ceil([tmpBB(1),tmpBB(2),tmpBB(1)+tmpBB(3),tmpBB(2)+tmpBB(4)]);

        tmpBB(1)=max(1,tmpBB(1)+trackOffset(1));
        tmpBB(3)=min(imSize(2),tmpBB(3)+trackOffset(1));

        tmpBB(2)=max(1,tmpBB(2)+trackOffset(2));
        tmpBB(4)=min(imSize(1),tmpBB(4)+trackOffset(2));

    end
    shape_struct.cumulativeBB=tmpBB;

end


end

