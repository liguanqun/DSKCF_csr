function [tracker_Occ,newPos]=singleFrameDSKCF_CSR_occluder(firstFrame, im,depth,tracker_Occ,DSpara)


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
%     [response, maxResponse,newPos]=maxResponseDSKCF(...
%         patch,patch_depth, DSpara.features,DSpara.kernel, pos,DSpara.cell_size, tracker_Occ.cos_window,...
%         tracker_Occ.model_xf,tracker_Occ.model_alphaf, tracker_Occ.model_xDf,tracker_Occ.model_alphaDf,...
%         nRows,nCols);
                 [response,newPos,tracker_Occ.channel_discr]=detect_csr(patch,patch_depth, pos,DSpara.cell_size, ...
              tracker_Occ.yf,DSpara.w2c ,tracker_Occ.chann_w, tracker_Occ.H, tracker_Occ.use_channel_wl );

    %update tracker struct, new position etc
    tracker_Occ.cT.posX=newPos(2);
    tracker_Occ.cT.posY=newPos(1);
    
    tracker_Occ.cT.bb=fromCentralPointToBB(tracker_Occ.cT.posX,tracker_Occ.cT.posY,...
        tracker_Occ.cT.w,tracker_Occ.cT.h, nCols,nRows);
    
    tracker_Occ.cT.conf=max(response(:));
    
end

%obtain a subwindow for training at newly estimated target position
patch = get_subwindow(im, newPos, tracker_Occ.window_sz);
patch_depth = get_subwindow(depth, newPos, tracker_Occ.window_sz);

%update occluder model....
% [tracker_Occ.model_alphaf, tracker_Occ.model_alphaDf, tracker_Occ.model_xf, tracker_Occ.model_xDf]=...
%     modelUpdateDSKCF(firstFrame,patch,patch_depth,DSpara.features,DSpara.cell_size,tracker_Occ.cos_window,...
%     DSpara.kernel,tracker_Occ.yf,DSpara.lambda,tracker_Occ.model_alphaf,tracker_Occ.model_alphaDf,...
% tracker_Occ.model_xf, tracker_Occ.model_xDf,0,DSpara.interp_factor);

     [tracker_Occ.chann_w, tracker_Occ.H,response_init]=update_csr(firstFrame,tracker_Occ.use_channel_wl,patch,patch_depth,DSpara.cell_size,DSpara.w2c,...
         tracker_Occ.cos_window, tracker_Occ.yf,tracker_Occ.H,tracker_Occ.chann_w,tracker_Occ.mask,tracker_Occ.channel_discr,...
        0,DSpara.interp_factor);


