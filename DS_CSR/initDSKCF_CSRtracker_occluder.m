function [ tracker_occ ] = initDSKCF_CSRtracker_occluder()
%INITDSKCF_CSRTRACKER_OCCLUDER Summary of this function goes here
%   Detailed explanation goes here
tracker_occ=[];

%% 目标的位置尺寸 current target position and bounding box
tracker_occ.cT.posX=0;%column in the image plane
tracker_occ.cT.posY=0;%row in the image plane
tracker_occ.cT.h=0;%height of the target
tracker_occ.cT.w=0;%width in the image planeof the target
tracker_occ.cT.bb=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker_occ.cT.conf=0;
tracker_occ.cT.conf_init=0;
%% 尺度信息，直接赋值，不需要尺度结构
tracker_occ.window_sz=[];
tracker_occ.output_sigma=[];
tracker_occ.yf=[];
tracker_occ.cos_window=[];
tracker_occ.target_sz=[];

%% 当前目标的深度分布current target depth distribution info
tracker_occ.cT.meanDepthObj=0;% mean depth of the tracker object
tracker_occ.cT.stdDepthObj=0;% depth's standard deviation of the tracker object
tracker_occ.cT.LabelRegions=[];%cluster labels of the segmented target region
tracker_occ.cT.regionIndex=0;%label of the object cluster
tracker_occ.cT.Centers=[];%depth centers of the clusters
tracker_occ.cT.LUT=[];%LUT
%% 当前目标的深度遮挡current target depth occluding info
tracker_occ.cT.occBB=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker_occ.cT.totalOcc=0; % total occlusion flag
tracker_occ.cT.underOcclusion=0; % under occlusion flag
%%  目标的模型参数 target model alpha and X, see [1] for more details
% tracker_occ.model_alphaf = []; 
% tracker_occ.model_alphaDf = [];
% tracker_occ.model_xf = [];
% tracker_occ.model_xDf = [];
tracker_occ.channel_discr = []; 
tracker_occ.chann_w = []; 
tracker_occ.Y = [];
tracker_occ.H = [];
tracker_occ.mask = [];

%previous target entries
tracker_occ.pT=tracker_occ.cT;

end

