function tracker=initDSKCFtracker()
% INITDSKCFTRACKER.m initializes the data structure for DS-KCF tracker [1]
% 
%   INITDSKCFTRACKER function initializes the data structure of the
%   DS-KCF tracker. In particular
%
%   INPUT: none
%
%   OUTPUT
%   -trackerDSKCF_struct data structure that contains DS-KCF tracker data
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
%   +previousTarget contains same information of cT, but they
%   it is relative to the target tracked in the previous frame.
%
%  See also WRAPPERDSKCF, INITDSKCFTRACKER_occluder
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

tracker=[];

% current target position and bounding box
tracker.cT.posX=0;%column in the image plane
tracker.cT.posY=0;%row in the image plane
tracker.cT.h=0;%height of the target
tracker.cT.w=0;%width in the image planeof the target
tracker.cT.bb=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker.cT.conf=0;
%current target depth distribution info
tracker.cT.meanDepthObj=0;% mean depth of the tracker object
tracker.cT.stdDepthObj=0;% depth's standard deviation of the tracker object
tracker.cT.LabelRegions=[];%cluster labels of the segmented target region
tracker.cT.regionIndex=0;%label of the object cluster
tracker.cT.Centers=[];%depth centers of the clusters
tracker.cT.LUT=[];%LUT
tracker.cT.segmentedBB=[];%bounding box of the corresponding sgmented region
%current target depth occluding info
tracker.cT.occBB=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker.cT.totalOcc=0; % total occlusion flag
tracker.cT.underOcclusion=0; % under occlusion flag
%target model alpha and X, see [1] for more details
tracker.model_alphaf = []; 
tracker.model_alphaDf = [];
tracker.model_xf = [];
tracker.model_xDf = [];


%previous target entries
tracker.pT=tracker.cT;


