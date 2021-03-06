function [dsKCFoutput] =  wrapperDSKCF_CSR(video_path, depth_path, img_files, depth_files,...
                                        pos, target_sz,DSpara, show_visualization,video)

     resize_image = (sqrt(prod(target_sz)) >= 100);  %diagonal size >= threshold
%目标过大就缩小2倍
if resize_image,
    pos = floor(pos / 2);
    target_sz = floor(target_sz / 2);
end
  

%搜索窗口的尺寸，把padding算上
DSpara.window_sz = floor(target_sz * (1 + DSpara.padding));

%初始化 尺度数据结构，包括 回归目标函数 cos 窗函数 目标大小等  scales = 0.4:0.1:2.2;
scale_struct=initDSKCFparam(DSpara,target_sz,pos);

%检查尺度DSKCF的参数结构体是否正确的初始化
if(isempty(scale_struct))
    disp('Scale structure initialization failed, tracking aborted');
    dsKCFoutput=[];
    return;
end

 dsKCFoutput=[];

frameCurr=[];
%     frameCurr.rgb   = imRGB;
%     frameCurr.gray   = im;
%     frameCurr.depth = double(depth);
%     frameCurr.depthNoData=depth16Bit==0;%代表 Mask 深度值为0处的值为1 否则为0
%     frameCurr.depth16Bit=depth16Bit;

framePrev=[]; %


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
        tracker=initDSKCF_CSRtracker();
        %check if the scale is properly initialized....
        if(isempty(tracker))
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
        tracker.pT.posX=pos(2);
        tracker.pT.posY=pos(1);
        tracker.pT.h=scale_struct.target_sz(scale_struct.i).target_sz(1);
        tracker.pT.w=scale_struct.target_sz(scale_struct.i).target_sz(2);
      %目标的矩形框 [x,y,x+w,y+h]
        tracker.pT.bb=fromCentralPointToBB(tracker.pT.posX,tracker.pT.posY, tracker.pT.w,tracker.pT.h,size(im,2),size(im,1));
        tracker.cT.meanDepthObj=0;% mean depth of the tracker object
        %initialize depth distributions 初始化深度的分布
        [tracker.pT.meanDepthObj,tracker.pT.stdDepthObj,tracker.pT.LabelRegions, ...
            tracker.pT.regionIndex,tracker.pT.Centers, tracker.pT.LUT] = ...
            initDistributionFast(tracker.pT.bb,framePrev.depth16Bit,framePrev.depthNoData);
        
        % mask init
        mask =tracker.pT.LabelRegions;
        mask(mask ~= tracker.pT.regionIndex)=0;
         mask(mask==tracker.pT.regionIndex)=1;
         tracker.mask =mask;
        %for the first frame copy everything also in the current target
        %第一张图像 当前图像和前一张图像的参数相同
        tracker.cT=tracker.pT;
        
        %set the depth of the initial target in the scale data structure
        %给尺度数据结构里的 初始深度 和当前深度赋值
        scale_struct.InitialDepth = tracker.pT.meanDepthObj;
        scale_struct.currDepth    = tracker.pT.meanDepthObj;
        
        %initialize structures for the occluder object
        %遮挡物体的跟踪结构跟 目标的跟踪结构 不同，增加了一些关于遮挡物的数据
        tracker_Occ=initDSKCF_CSRtracker_occluder();
        %跟踪器的参数相同
        DSpara_Occ=DSpara;%these need to be resetted eventually in some parts
        
        %figure initialization
        if(show_visualization)
            
            myFigColor=figure();
            myFigDepth=figure();
            myFigMask=figure();
            set(myFigDepth,'resize','off');
            set(myFigColor,'resize','off');
            set(myFigMask,'resize','off');
        end
        
        %take segmentation results for the first frame
        tracker.cT.segmentedBB=tracker.cT.bb';
    end %    if(firstFrame)

    %DS-KCF tracker code need as input the position expressed as [y x],
    %remember this particular while reading the code!!!!!

    [pos,tracker,tracker_Occ,scale_struct,DSpara_Occ]=...
        singleFrameDSKCF_CSR(firstFrame,frame,pos,frameCurr,tracker,DSpara, scale_struct,tracker_Occ,DSpara_Occ);

    
     frame =frame
    
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
            sr = scale_struct.InitialDepth / scale_struct.currDepth;
            targ_sz = round(scale_struct.InitialTargetSize * sr);         
            %calculate the corresponding bounding box for Plotting!!!!
            %in this case we need [topLeftX, topLeftY,W,H]
            bbToPlot = [pos([2,1]) - targ_sz([2,1])/2, targ_sz([2,1])];
            if(resize_image)
                bbToPlot=bbToPlot*2;
            end
        end
        
        bbOCCToPlot=[];
        if(tracker.cT.underOcclusion)
            widthOCC=tracker.cT.occBB(3)-tracker.cT.occBB(1);
            heightOCC=tracker.cT.occBB(4)-tracker.cT.occBB(2);
            bbOCCToPlot=[tracker.cT.occBB(1:2); widthOCC; heightOCC]';
            if(resize_image)
                bbOCCToPlot=bbOCCToPlot*2;
            end
        end
        
        
        
        if(frame==1)
            manualBBdraw_OCC_WithLabelsVisualize(imRGB,bbToPlot,bbOCCToPlot,'r','y',2,'DS-KCF','Occluder',myFigColor,frame);
            manualBBdraw_OCC_WithLabelsVisualize(depth,bbToPlot,bbOCCToPlot,'r','y',2,'DS-KCF','Occluder',myFigDepth,frame);
            figure(myFigMask)
            imshow(tracker.mask*255);
%             pause()
        else
            %clf(myFigColor);
            manualBBdraw_OCC_WithLabelsVisualize(imRGB,bbToPlot,bbOCCToPlot,'r','y',2,'DS-KCF','Occluder',myFigColor,frame);       
            %clf(myFigDepth);
            manualBBdraw_OCC_WithLabelsVisualize(depth,bbToPlot,bbOCCToPlot,'r','y',2,'DS-KCF','Occluder',myFigDepth,frame);
            figure(myFigMask)
            imshow(tracker.mask*255);
            drawnow
%              pause()
        end
           
    end
    %% Visualize and save.....

    %% just save images
%%   把跟踪的pos保存下来
    %now generate the results, starting from the tracker output!!!
    % the object has being tracked....
   
    if(isempty(pos)==false)   %跟踪成功
        %accumulate the position of the DS-KCF tracker remember format [y x]

        %use the Sr scale factor (see [1] for more details) sr连续尺度系数 保存尺度的大小，即 目标的size
        sr = scale_struct.InitialDepth / scale_struct.currDepth;
        targ_sz = round(scale_struct.InitialTargetSize * sr);
        
        %保存  转为opencv下的矩形
          bbToPlot = [pos([2,1]) - targ_sz([2,1])/2, targ_sz([2,1])];
          if(resize_image)
                bbToPlot=bbToPlot*2;
          end
          %转换为 数据集 要求的结果格式
             a=floor([bbToPlot([1 2]) bbToPlot([1 2])+bbToPlot([3 4])]);
             a=[a 0]
             name = ['/home/orbbec/dskcf_result_save/DSKCF_simaple/' video '.txt'];
             fp=fopen(name,'a');
             fprintf(fp,'%d,%d,%d,%d,%d\r\n',a);%注意：\r\n为换
             fclose(fp);     
%              pause();
    else         %跟踪失败   使用上一次跟踪的结果，pose 和 size 

        %保存
        name = ['/home/orbbec/dskcf_result_save/DSKCF_simaple/' video '.txt'];
        fp=fopen(name,'a');       
        disp('NaN,NaN,NaN,NaN,1');
        fprintf(fp,'%s\r\n','NaN,NaN,NaN,NaN,1'); 
        fclose(fp);
%          pause();
       % disp('NaN,NaN,NaN,NaN,1');    
    end
    
    %更新以往的数据结构，把当前的Target赋值给以往的Target
    if(frame>1)
        %previous target entries
        tracker.pT=tracker.cT;
    end
    
    
end



end
