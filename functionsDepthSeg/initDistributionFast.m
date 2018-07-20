function [targetDepth,targetStd,LabelReg,regionIndex,Centers,LUT] = initDistributionFast(bbIn, depth16Bit,noData)
% INITDISTRIBUTIONFAST.m initializes the depth distribution of the DS-KCF tracker
%
%   INITDISTRIBUTIONFAST function initializes the depth distribution of the
%   tracked object at the beginning of the sequence. In particular, the
%   fast depth segmentation algorithm described in [1] is used
%
%   INPUT:
%  -bbIn bounding box containing the tracked object. Format of the bounding
%  box is [topLeftX, topLeftY, bottomRightX, bottomRightY] read as
%  [rowIndexTopLeft, columnIndexTopLeft,rowIndexBottomRight,
%  columnIndexBottomRight]
%  -depth16Bit depth data in mm
%  -noData binary mask containing information about missing depth pixels
%
%   OUTPUT
%  -targetDepth mean depth value of the cluster containing the target
%  -targetStd standard deviation of the cluster containing the target
%  -LabelReg connected component with cluster labels
%  -regionIndex label of the target's cluster (or the closest object to the
%  camera)
%  -Centers depth value corresponding to the identified connected
%  components
%  -LUT look-up-table containing the connected component labels and the
%  corresponding mean depth value


%extract the target roi, from the depth and the nodata mask
front_depth=roiFromBB(depth16Bit,bbIn);
depthNoData=roiFromBB(noData,bbIn);

[LabelReg,Centers,LUT]=fastDepthSegmentationDSKCF_initFrameV2(front_depth,3,depthNoData,1,50,[-1 -1 -1],1);

%for the initialization the object belong to the cluster with the smaller depth (see [1] for more details)
%在初始化时，深度值最小的聚类 为 目标
[targetDepth,regionIndex]=min(Centers);

%extract all the depth value belonging to that cluster
%提取 属于 该 聚类的 所有 深度值
depthVector=double(front_depth(LabelReg==regionIndex));

%then calculate the standard deviation
%计算方差
targetStd=std(depthVector);

end

