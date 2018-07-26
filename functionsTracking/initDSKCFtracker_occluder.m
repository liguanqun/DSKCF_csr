function tracker_occ=initDSKCFtracker_occluder()
% INITDSKCFTRACKER_occluder.m initializes the data structure for DS-KCF tracker (occluder) [1]
% 
%   INITDSKCFTRACKER_OCCLUDER function initializes the data structure of
%   the DS-KCF tracker for the occluder. In particular, it is different
%   from INITDSKCFTRACKER as it has few more fields needed for the occluder
%   tracking.
%
%   INPUT: none
%
%   OUTPUT
%  -trackerDSKCF_struct data structure that contains DS-KCF tracker data
%  structure
%   
%   + cT.posX column in the image plane
%   + cT.posY row in the image plane
%   + cT.h height of the target
%   + cT.w width of the target
%   + cT.bb bounding box of the target in the format 
%                     [topLeftX, topLeftY, bottomRightX, bottomRightY]
%   + cT.meanDepthObj mean depth of the tracker object
%   + cT.stdDepthObj depth's standard deviation of the tracker object
%   + cT.LabelRegions cluster labels of the segmented target region
%   + cT.regionIndex= label of the object cluster
%   + cT.Centers depth centers of the clusters
%   + cT.LUT=[] LUT
%   + cT.occBB=[0 0 0 0]; occluding bounding box in the format
%   [topLeftX, topLeftY, bottomRightX, bottomRightY]
%   + cT.totalOcc=0;  total occlusion flag
%   + cT.underOcclusion=0;  under occlusion flag
%   +cT.conf maximum response of the DSKCF for the current frame
%
%   models in the frequency domain for the KCFbased tracking by using color
%   and depth features (see [1] for mor details)
%   +model_alphaf = []; 
%   +model_alphaDf = [];
%   +model_xf = [];
%   +model_xDf = [];
%
%   As the occluder is not tracked considering change of scale (see [1])
%   the data structure contains also the following fields
%
%   +window_sz      size of the patch for DSKCF tracking
%   +output_sigma   vector where sigma parameter is stored see [1]
%   +yf             DSKCF training labels
%   +cos_window     cosine window to smooth signals in the Fourier domain
%   +target_sz      target size
%
%
%   +pT contains same information of cT, but they
%   it is relative to the target tracked in the previous frame.
%
%   See also WRAPPERDSKCF, INITDSKCFTRACKER
%
% [1] S. Hannuna, M. Camplani, J. Hall, M. Mirmehdi, D. Damen, T.
% Burghardt, A.Paiement, L. Tao, DS-KCF: A ~real-time tracker for RGB-D
% data, Journal of Real-Time Image Processing
%
%
%  University of Bristol 
%  Massimo Camplani and Sion Hannuna
%  
%  massimo.camplani@bristol.ac.uk 
%  hannuna@compsci.bristol.ac.uk

tracker_occ=[];

%% 目标的位置尺寸 current target position and bounding box
tracker_occ.cT.posX=0;%column in the image plane
tracker_occ.cT.posY=0;%row in the image plane
tracker_occ.cT.h=0;%height of the target
tracker_occ.cT.w=0;%width in the image planeof the target
tracker_occ.cT.bb=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker_occ.cT.conf=0;
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
tracker_occ.model_alphaf = []; 
tracker_occ.model_alphaDf = [];
tracker_occ.model_xf = [];
tracker_occ.model_xDf = [];


%previous target entries
tracker_occ.pT=tracker_occ.cT;


