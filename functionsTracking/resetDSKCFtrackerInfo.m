function tracker=resetDSKCFtrackerInfo(tracker)
% RESETDSKCFTRACKERINFO.m re-initializes the data structure for DS-KCF tracker before processing a new frame[1]
% 
%   RESETDSKCFTRACKERINFO re-initializes the data structure for DS-KCF
%   tracker before processing a new frame[1]
%
%   INPUT: 
%   -trackerDSKCF_structIN tracker data structure
%   OUTPUT
%  -trackerDSKCF_struct data structure with re-set tracking info
%   
%  [1] S. Hannuna, M. Camplani, J. Hall, M. Mirmehdi, D. Damen, T.
%  Burghardt, A. Paiement, L. Tao, DS-KCF: A real-time tracker for RGB-D
%  data, Journal of Real-Time Image Processing
% See also SINGLEFRAMEDSKCF
%
%  University of Bristol 
%  Massimo Camplani and Sion Hannuna
%  
%  massimo.camplani@bristol.ac.uk 
%  hannuna@compsci.bristol.ac.uk

%trackerDSKCF_struct=trackerDSKCF_structIN;
tracker.cT.occBB=[0 0 0 0]; % in the format [topLeftX, topLeftY, bottomRightX, bottomRightY]
tracker.cT.totalOcc=0; % total occlusion flag
tracker.cT.underOcclusion=0; % under occlusion flag
tracker.cT.conf=0;

