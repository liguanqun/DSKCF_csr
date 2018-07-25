function scale_struct=initDSKCFparam(DSpara,target_sz,pos)
% INITDSKCFPARAM.m initializes the scale data structure for DS-KCF tracker [1]
% 
%   INITDSKCFPARAM function initializes the scale data structure of the
%   DS-KCF tracker. In particular, some matrices are precomputed at the
%   different scales and other flags are intialized
%
%   INPUT:
%  -DSKCFparameters DS-KCF algorithm parameters 
%  -target_sz initial target size of the tracked object
%  -pos initial target position of the tracked object
%   OUTPUT
%  -scaleDSKCF_struct data structure that contains scales parameters and
%  precomputed matrices. In particular the field of the struct are 
%
%  + i current scale among Sq in [1]
%  + iPrev previous scale among Sq in [1]
%  + minStep minimum interval between the scales in Sq in [1]
%  + scales is the Sq vector in [1]
%  + step minimum interval between the scales in Sq (the same as minStep)
%  + updated flag set to 1 (or 0) when a change of scale is (or not)
%  required
%  + currDepth is the ratio between the initial depth target and the
%  current one. Is Sr in [1]
%  + InitialDepth initial ratio
%  + InitialTargetSize size of the target in the initial frame
%  + windows_sizes vector containing precomputed windows size (according
%  the padding parameter) for each scale
%  + target_sz vector containing the expected target size at the different
%  scales
%  + pos vector where is stored per each scale the target centroid position
%  + output_sigmas vector where sigma parameter is stored for each scale
%  + yfs regression targets for all the scales
%  + cos_windows precomputed cosine windows for each scale
%  + len contains the area of the target at each scale
%  + ind 

scale_struct=[];

% Find initial scale
scale_struct.i = find(DSpara.scales == 1);
scale_struct.iPrev = scale_struct.i; % for inerpolating model
scale_struct.minStep = min(abs(diff(DSpara.scales)));
scale_struct.scales = DSpara.scales;
scale_struct.step = min(diff(DSpara.scales)); % use smallest step to decide whether to look at other scales
scale_struct.updated = 0;
scale_struct.currDepth = 1;
scale_struct.InitialDepth = 1;
scale_struct.InitialTargetSize = target_sz;

for i=1:length(DSpara.scales)
    scale_struct.windows_sizes(i).window_sz = round(DSpara.window_sz * DSpara.scales(i));
    scale_struct.target_sz(i).target_sz = round(target_sz * DSpara.scales(i));
    scale_struct.pos(i).pos = pos;
    
    %create regression labels, gaussian shaped, with a bandwidth
    %proportional to target size  构造回归函数的 目标函数
    scale_struct.output_sigmas(i).output_sigma = sqrt(prod(scale_struct.target_sz(i).target_sz)) * DSpara.output_sigma_factor / DSpara.cell_size;
    scale_struct.yfs(i).yf = fft2(gaussian_shaped_labels( scale_struct.output_sigmas(i).output_sigma, floor( scale_struct.windows_sizes(i).window_sz / DSpara.cell_size)));
    
    %store pre-computed cosine window存储 预计算的cos 窗函数
    scale_struct.cos_windows(i).cos_window = hann(size(scale_struct.yfs(i).yf,1)) * hann(size(scale_struct.yfs(i).yf,2))';
    scale_struct.lens(i).len = scale_struct.target_sz(i).target_sz(1) * scale_struct.target_sz(i).target_sz(2);
    scale_struct.inds(i).ind = floor(linspace(1,scale_struct.lens(i).len, round(0.25 * scale_struct.lens(i).len)));
end

scale_struct.prevpos=pos;



