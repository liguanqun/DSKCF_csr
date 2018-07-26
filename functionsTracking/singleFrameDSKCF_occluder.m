function [tracker_Occ,newPos]=singleFrameDSKCF_occluder(firstFrame, im,depth,tracker_Occ,DSpara)
% SINGLEFRAMEDSKCF_OCCLUDER.m functions for tracking occluding object
%
%   SINGLEFRAMEDSKCF_OCCLUDER is the function for tracking the occluding
%   object in the DS-KCF tracker framework (for more details see [1]). This
%   function is based on several data structures where input and output
%   data is stored.Please note that data structures are supposed to be
%   initialized as in wrapperDSKCF and runDSKCF.m test script.
%
%   INPUT:
%   - firstFrame   boolean flag that marks the first frame of the
%   sequence
%   - im    color data
%   - depth    depth data (8bit image)
%   - trackerDSKCF_structOccluder  DS-KCF tracker data structure (see WRAPPERDSKCF,
%   INITDSKCFTRACKER)
%   - DSKCFparameters, parameters structures
%
%
%   OUTPUT
%   -newPos updated position of the DS-KCF tracker while tracking the
%   occluding object newPos=[y x] where x is the column and y is the row
%   index
%   -trackerDSKCF_structOccluder updated data structure for the trackers
%
%  See also MAXRESPONSEDSKCF , SINGLEFRAMEDSKCF, GET_SUBWINDOW,
%  MODELUPDATEDSKCF, FROMCENTRALPOINTTOBB
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


%insert in pos the previous target position...
pos=[tracker_Occ.pT.posY,tracker_Occ.pT.posX];
newPos=pos;
if(firstFrame==false)
    
    %obtain a subwindow for training at newly estimated target position
    patch = get_subwindow(im, pos, tracker_Occ.window_sz);
    patch_depth = get_subwindow(depth, pos, tracker_Occ.window_sz);
    nRows=size(im,1);
    nCols=size(im,2);
    %calculate response of the DS-KCF tracker
    [response, maxResponse,newPos]=maxResponseDSKCF(...
        patch,patch_depth, DSpara.features,DSpara.kernel, pos,DSpara.cell_size, tracker_Occ.cos_window,...
        tracker_Occ.model_xf,tracker_Occ.model_alphaf, tracker_Occ.model_xDf,tracker_Occ.model_alphaDf,...
        nRows,nCols);
        
    %update tracker struct, new position etc
    tracker_Occ.cT.posX=newPos(2);
    tracker_Occ.cT.posY=newPos(1);
    
    tracker_Occ.cT.bb=fromCentralPointToBB(tracker_Occ.cT.posX,tracker_Occ.cT.posY,...
        tracker_Occ.cT.w,tracker_Occ.cT.h, nCols,nRows);
    
    tracker_Occ.cT.conf=maxResponse;
    
end

%obtain a subwindow for training at newly estimated target position
patch = get_subwindow(im, newPos, tracker_Occ.window_sz);
patch_depth = get_subwindow(depth, newPos, tracker_Occ.window_sz);

%update occluder model....
[tracker_Occ.model_alphaf, tracker_Occ.model_alphaDf, tracker_Occ.model_xf, tracker_Occ.model_xDf]=...
    modelUpdateDSKCF(firstFrame,patch,patch_depth,DSpara.features,DSpara.cell_size,tracker_Occ.cos_window,...
    DSpara.kernel,tracker_Occ.yf,DSpara.lambda,tracker_Occ.model_alphaf,tracker_Occ.model_alphaDf,...
tracker_Occ.model_xf, tracker_Occ.model_xDf,0,DSpara.interp_factor);





