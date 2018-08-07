function [ tracker ] = initDSKCF_CSRtracker()
%INITDSKCF_CSRTRACKER Summary of this function goes here
%   Detailed explanation goes here
tracker=[];

%% 目标的位置尺寸 current target position and bounding box
tracker.cT.posX=0;%column in the image plane
tracker.cT.posY=0;%row in the image plane
tracker.cT.h=0;%height of the target
tracker.cT.w=0;%width in the image planeof the target
tracker.cT.bb=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker.cT.conf=0;
%% 当前目标的深度分布current target depth distribution info
tracker.cT.meanDepthObj=0;% mean depth of the tracker object
tracker.cT.stdDepthObj=0;% depth's standard deviation of the tracker object
tracker.cT.LabelRegions=[];%cluster labels of the segmented target region
tracker.cT.regionIndex=0;%label of the object cluster
tracker.cT.Centers=[];%depth centers of the clusters
tracker.cT.LUT=[];%LUT
tracker.cT.segmentedBB=[];%bounding box of the corresponding sgmented region
%% 当前目标的深度遮挡current target depth occluding info
tracker.cT.occBB=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker.cT.totalOcc=0; % total occlusion flag
tracker.cT.underOcclusion=0; % under occlusion flag
%%  目标的模型参数 target model alpha and X, see [1] for more details
% tracker.model_alphaf = []; 
% tracker.model_alphaDf = [];
% tracker.model_xf = [];
% tracker.model_xDf = [];
tracker.channel_discr = []; 
tracker.chann_w = []; 
tracker.Y = [];
tracker.H = [];
tracker.mask = [];
tracker.use_channel_wl = true;
tracker.conf_init = [];
tracker.abs_conf = [];
%previous target entries
tracker.pT=tracker.cT;


end

