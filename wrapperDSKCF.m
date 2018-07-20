function [dsKCFoutput] =  wrapperDSKCF(video_path, depth_path, img_files, depth_files, pos, target_sz, ...
    DSKCFparameters, show_visualization,video)
% WRAPPERDSKCF.m is the wrapper function for the DS-KCF tracker [1]

%   INPUT:
%  -video_path absolute path where color data is stored -depth_path
%  absolute path where depth data is stored 
%  -img_files the list of Color data files (N is the number of frame to be
%  processed) -depth_files  the list of Depth data files (N is the number
%  of frame to be processed)
%  -pos initial DS-KCF tracker position pos=[y x] where x is the column
%  index and y is the row index of the image
%  -target_sz initial target size target_sz=[height,width]
%  -DSKCFparameters structure containing DSKCF parameters, see the test
%  script testDS-KCFScripts\runDSKCF.m
%  -show_visualization flag to show the tracking results live in a matlab
%  figure
%  -dest_path absolute path of the destination folder where tracker's
%  output is saved
%
%   OUTPUT
%  -dsKCFoutput tracker's output using scale factor Sr in [1]. This a Nx5
%  vector containing in each row the tracker results for the corresponding
%  frame. In particular the output is formatted as suggested in the
%  princetonRGB-D dataset in [3]. For each row the first four columns
%  contain the bounding box information in the format [topLeftX, topLeftY,
%  bottomRightX, bottomRightY]. Note that in case of lost target the row
%  contains NaN values. The fifth column contains a flag to indicate
%  occlusions cases.
%


%As suggested in the original code of KCF resize target and image....
resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold
%目标过大就缩小2倍
if resize_image,
    pos = floor(pos / 2);
    target_sz = floor(target_sz / 2);
end


%window size, taking padding into account
DSKCFparameters.window_sz = floor(target_sz * (1 + DSKCFparameters.padding));

%initialize the scale parameters for the DSKCF algorithm accortind to the
%selected Sq (see [1]) information contained in DSKCFparameters
%初始化 尺度数据结构，包括 回归目标函数 cos 窗函数 目标大小等  scales = 0.4:0.1:2.2;
scaleDSKCF_struct=initDSKCFparam(DSKCFparameters,target_sz,pos);

%initialize shape struct
shapeDSKCF_struct=initDSKCFshape(5,0);

%check if the scale is properly initialized.... 
if(isempty(scaleDSKCF_struct))
    disp('Scale structure initialization failed, tracking aborted');
    dsKCFoutput=[];
    return;
end

%note: variables ending with 'f' are in the Fourier domain.



%init variables
positions = zeros(numel(img_files), 2); % where store tracker centroids
dsKCFoutput = zeros(numel(img_files), 2);


%auxiliary variables to compute the final results of the tracker, in fact
%DS-KCF tracking core returns only the centroid of the target, we need also
%to store the size of it to return proper output parameters
sizeSr = zeros(numel(img_files), 2);


frameCurr=[]; %contains depth and color data of the current frame depth16Bit
%contains the 16bits depth information in mm. depth contains
%the normalize depth data as a grayscale image coded with 8bits
%depthNoData is the mask to identify missing depth data
%rgb is the color image and gray is the grayscale version of it

framePrev=[]; %contains the same information of frameCurr but related
%to the previous frame


occlusionState=[];% vector containing flags about the detected occlusion state
%%%% TO BE CHECKED
nanPosition=[];


segmentedSize=[];

%%FRAME BY FRAME TRACKING.....
for frame = 1:numel(img_files),
    %load images
    im = imread([video_path img_files{frame}]);
    depth = imread([depth_path depth_files{frame}]);
    
    %% inserting type control for depth image
    if(isa(depth,'uint16'))
        
        depth = bitor(bitshift(depth,-3), bitshift(depth,16-3));
    
        %depth data in mm
        depth16Bit = depth;
        
        %Normalize depth data as a grayscale image [0 255]
        depth = double(depth);
        depth(depth==0) = 10000;
        depth = (depth-500)/8500;%only use the data from 0.5-8m
        depth(depth<0) = 0;
        depth(depth>1) = 1;
        depth = uint8(255*(1 - depth));
    end
    
    %resize images
    if size(im,3) > 1,
        imRGB=im;
        im = rgb2gray(im);
    else
        imRGB=im;
        imRGB(:,:,2)=im;
        imRGB(:,:,3)=im;
    end
    
    if resize_image,
        im = imresize(im, 0.5);
        imRGB = imresize(imRGB, 0.5);
        depth = imresize(depth, 0.5);
        depth16Bit = depth16Bit((1:2:end),(1:2:end));
    end
    
    
    
    %start measuring the time!!!!
    tTotal=tic();
    firstFrame=frame==1;
    
    %Insert current frame data
    frameCurr.rgb   = imRGB;
    frameCurr.gray   = im;
    frameCurr.depth = double(depth);
    frameCurr.depthNoData=depth16Bit==0;%代表 Mask 深度值为0处的值为1 否则为0
    frameCurr.depth16Bit=depth16Bit;
   
    %for the first frame initialize the structures
    %第一张图像 用来初始化
    if(firstFrame)
        segmentedMASK=repmat(0,size(frameCurr.depth));%
        trackerDSKCF_struct=initDSKCFtracker();
        %check if the scale is properly initialized....
        if(isempty(trackerDSKCF_struct))
            disp('DS-KCF tracker structure initialization failed, tracking aborted');
            dsKCFoutput=[];
            return;
        end
        %%INITIALIZE HISTOGRAMS....
        framePrev.rgb   = imRGB;
        framePrev.gray   = im;
        framePrev.depth = depth;
        framePrev.depthNoData=depth16Bit==0;
        framePrev.depth16Bit=depth16Bit;
        %初始化目标的  [x,y,w,h]
        trackerDSKCF_struct.previousTarget.posX=pos(2);
        trackerDSKCF_struct.previousTarget.posY=pos(1);
        trackerDSKCF_struct.previousTarget.h=scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(1);
        trackerDSKCF_struct.previousTarget.w=scaleDSKCF_struct.target_sz(scaleDSKCF_struct.i).target_sz(2);
      %目标的矩形框 [x,y,x+w,y+h]
        trackerDSKCF_struct.previousTarget.bb=fromCentralPointToBB...
            (trackerDSKCF_struct.previousTarget.posX,trackerDSKCF_struct.previousTarget.posY,...
            trackerDSKCF_struct.previousTarget.w,trackerDSKCF_struct.previousTarget.h,size(im,2),size(im,1));
        trackerDSKCF_struct.currentTarget.meanDepthObj=0;% mean depth of the tracker object
        %initialize depth distributions 初始化深度的分布
        [trackerDSKCF_struct.previousTarget.meanDepthObj,trackerDSKCF_struct.previousTarget.stdDepthObj,...
            trackerDSKCF_struct.previousTarget.LabelRegions,...
            trackerDSKCF_struct.previousTarget.regionIndex,...
            trackerDSKCF_struct.previousTarget.Centers,...
            trackerDSKCF_struct.previousTarget.LUT] = ...
            initDistributionFast(trackerDSKCF_struct.previousTarget.bb,framePrev.depth16Bit,framePrev.depthNoData);
        
        %for the first frame copy everything also in the current target
        %第一张图像 当前图像和前一张图像的参数相同
        trackerDSKCF_struct.currentTarget=trackerDSKCF_struct.previousTarget;
        
        %set the depth of the initial target in the scale data structure
        %给尺度数据结构里的 初始深度 和当前深度赋值
        scaleDSKCF_struct.InitialDepth = trackerDSKCF_struct.previousTarget.meanDepthObj;
        scaleDSKCF_struct.currDepth    = trackerDSKCF_struct.previousTarget.meanDepthObj;
        
        %initialize structures for the occluder object
        %遮挡物体的跟踪结构跟 目标的跟踪结构 不同，增加了一些关于遮挡物的数据
        trackerDSKCF_structOccluder=initDSKCFtracker_occluder();
        %跟踪器的参数相同
        DSKCFparameters_Occluder=DSKCFparameters;%these need to be resetted eventually in some parts
        
        %figure initialization
        if(show_visualization)
            
            myFigColor=figure();
            myFigDepth=figure();
            set(myFigDepth,'resize','off');
            set(myFigColor,'resize','off');
        end
        
        %take segmentation results for the first frame
        trackerDSKCF_struct.currentTarget.segmentedBB=trackerDSKCF_struct.currentTarget.bb';
    end %    if(firstFrame)

    %DS-KCF tracker code need as input the position expressed as [y x],
    %remember this particular while reading the code!!!!!

    [pos,trackerDSKCF_struct,trackerDSKCF_structOccluder,scaleDSKCF_struct,...
        DSKCFparameters_Occluder,segmentedMASK,shapeDSKCF_struct]=...
        singleFrameDSKCF(firstFrame,pos,frameCurr,trackerDSKCF_struct,DSKCFparameters,...
        scaleDSKCF_struct,trackerDSKCF_structOccluder,DSKCFparameters_Occluder,shapeDSKCF_struct);
    

    %Compose the Occlusion state vector for results
    occlusionState=[occlusionState ;trackerDSKCF_struct.currentTarget.underOcclusion];
    

    
    %% Just visualize......
    if ( show_visualization==true)
        
        %eventually re-scale the images
        if(resize_image)
            imRGB = imresize(imRGB, 2);
            depth = imresize(depth, 2);
        end
        
        %empty tracking, so mark this frame
        if(isempty(pos))
            bbToPlot=[];

        else
     
            
            %use the Sr scale factor (see [1] for more details)
            sr = scaleDSKCF_struct.InitialDepth / scaleDSKCF_struct.currDepth;
            
            targ_sz = round(scaleDSKCF_struct.InitialTargetSize * sr);
            
            %calculate the corresponding bounding box for Plotting!!!!
            %in this case we need [topLeftX, topLeftY,W,H]
            bbToPlot = [pos([2,1]) - targ_sz([2,1])/2, targ_sz([2,1])];
            if(resize_image)
                bbToPlot=bbToPlot*2;
            end
        end
        
        bbOCCToPlot=[];
        if(trackerDSKCF_struct.currentTarget.underOcclusion)
            widthOCC=trackerDSKCF_struct.currentTarget.occBB(3)-trackerDSKCF_struct.currentTarget.occBB(1);
            heightOCC=trackerDSKCF_struct.currentTarget.occBB(4)-trackerDSKCF_struct.currentTarget.occBB(2);
            bbOCCToPlot=[trackerDSKCF_struct.currentTarget.occBB(1:2); widthOCC; heightOCC]';
            if(resize_image)
                bbOCCToPlot=bbOCCToPlot*2;
            end
        end
        frame =frame
        
        
        if(frame==1)
            manualBBdraw_OCC_WithLabelsVisualize(imRGB,bbToPlot,bbOCCToPlot,'r','y',4,'DS-KCF','Occluder',myFigColor);
            positionColor=get(gcf,'OuterPosition');
            positionColor(1)=positionColor(1)-floor(positionColor(3)/2) -25;
            set(gcf,'OuterPosition',positionColor);
            manualBBdraw_OCC_WithLabelsVisualize(depth,bbToPlot,bbOCCToPlot,'r','y',4,'DS-KCF','Occluder',myFigDepth);
            positionDepth=get(gcf,'OuterPosition');
            positionDepth(1)=positionDepth(1)+floor(positionDepth(3)/2) +25;
            set(gcf,'OuterPosition',positionDepth);
        else
            %myFigColor=figure();
            %myFigDepth=figure();
            clf(myFigColor);
            manualBBdraw_OCC_WithLabelsVisualize(imRGB,bbToPlot,bbOCCToPlot,'r','y',4,'DS-KCF','Occluder',myFigColor);
            
            clf(myFigDepth);
            manualBBdraw_OCC_WithLabelsVisualize(depth,bbToPlot,bbOCCToPlot,'r','y',4,'DS-KCF','Occluder',myFigDepth);
            drawnow
            pause(0.05)
        end
           
    end
    %% Visualize and save.....

    %% just save images
%%   把跟踪的pos保存下来
    %now generate the results, starting from the tracker output!!!
    % the object has being tracked....
   
    if(isempty(pos)==false)   %跟踪成功
        %accumulate the position of the DS-KCF tracker remember format [y x]
        positions(frame,:) = pos;

         nanPosition=[nanPosition; 0];
        %use the Sr scale factor (see [1] for more details) sr连续尺度系数 保存尺度的大小，即 目标的size
        sr = scaleDSKCF_struct.InitialDepth / scaleDSKCF_struct.currDepth;
        targ_sz = round(scaleDSKCF_struct.InitialTargetSize * sr);
        %invert the coordinate as you need to combine this with positions
        %根据pose和尺度 可以推算出目标框
        srVector(frame,:) = targ_sz([2,1]);
        
        %保存
          bbToPlot = [pos([2,1]) - targ_sz([2,1])/2, targ_sz([2,1])];
          if(resize_image)
                bbToPlot=bbToPlot*2;
            end
            
             a=[bbToPlot 0] ;
             name = ['/home/orbbec/dskcf_result_save/' video '.txt'];
             fp=fopen(name,'a');
             fprintf(fp,'%d,%d,%d,%d,%d\r\n',a);%注意：\r\n为换
             fclose(fp);     
        
    else         %跟踪失败   使用上一次跟踪的结果，pose 和 size 
        nanPosition=[nanPosition; 1];
        
        pos=positions(frame-1,:);
        positions(frame,:) = pos;
            
        tmpSize=srVector(frame-1,:);
        srVector(frame,:) = tmpSize;
        %保存
        name = ['/home/orbbec/dskcf_result_save/' video '.txt'];
        fp=fopen(name,'a');       
        fprintf(fp,'%s\r\n','NaN,NaN,NaN,NaN,1'); 
        fclose(fp);
       % disp('NaN,NaN,NaN,NaN,1');
        
        
    end
    
    %Update PAST Target data structure
    %更新以往的数据结构，把当前的Target赋值给以往的Target
    if(frame>1)
        %previous target entries
        trackerDSKCF_struct.previousTarget=trackerDSKCF_struct.currentTarget;
    end
    
    
end

if resize_image,
    positions = positions * 2;
    srVector= srVector*2;
end

%now generate the final results, this are in the format requested by the
%Princeton RGB-D dataset in the format [topLeftX, topLeftY, bottomRightX,
%bottomRightY]. Then move from the change from the center + target size
%format to the above mentioned one
dsKCFoutput=[positions(:,[2,1]) - srVector/2, positions(:,[2,1]) + srVector/2];

%now set to NaN the output for the frames where the tracker was not
%available
dsKCFoutput(nanPosition>0,:)=NaN;

%add the occlusion state vector.
dsKCFoutput=[dsKCFoutput, occlusionState];

end

