clc;clear all;close all;


currentFolder=pwd();
disp(currentFolder);
%%add the DS-KCFresults

dskcfPath{1}='/';
dskcfPath{2}='/functionsDepthSeg';
dskcfPath{3}='/functionsIO';
dskcfPath{4}='/functionsOcclusions';
dskcfPath{5}='/functionsScaleChange';
dskcfPath{6}='/functionsTracking';
dskcfPath{7}='/functionsShape';
dskcfPath{8}='/CSR';
dskcfPath{9}='/CSRfeature';
dskcfPath{10}='/CSRutils';
dskcfPath{11}='/DS_CSR';
dskcfPath{11}='/testDS-KCFScripts';
for i=1:length(dskcfPath)
    cd([currentFolder dskcfPath{i}]);
    tmpPath=cd();
    %addpath(genpath(tmpPath));
    addpath(tmpPath);
    cd(currentFolder);
end

cd(currentFolder)


%now select the data folder
 rootSourceFolder=('/media/orbbec/7024AED824AEA1181/EvaluationSet');
  %rootSourceFolder=('/home/orbbec/data');
cd(rootSourceFolder);
rootSourceFolder=pwd();


%select all the videos in the folder
dirInfo = dir();
isDir = [dirInfo.isdir];
listAllVideos = {dirInfo(isDir).name};
listAllVideos = listAllVideos(3:end);

%If you don't want to precess all the video set this to false
processAllVideos=true;

%eventually select your subset of videos
if(processAllVideos==false)
    %insert video names manually!!!!
    %            listVideos{1}='child_no1';
    %            listVideos{1}='new_ex_occ4';
    %               listVideos{1}='bear_front';
    listVideos{1}='cup_book';
    %          listVideos{1}='face_occ5';
    %     listVideos{1}='zcup_move_1';
    %     listVideos{1}='face_occ5';
    %   listVideos{1}='basketball1'; 
else
    listVideos=listAllVideos;
end

show_visualization=false; %show the tracking results live in a matlab figure
save_result_into_txt = true ;
tmp_path = '/home/orbbec/dskcf_result_save/DSKCF_simaple/occ_dskcf_no_abs_conf/';
%% SETTING TRACKER'S PARAMETERS
 padding =2.3;  %extra area surrounding the target
%lambda = 1e-4;  %regularization
output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)
%Set the scale Sq in [1]  尺度设置
scales = 0.4:0.1:2.2;

interp_factor = 0.02;
cell_size = 4;

w2c = [];
w2c = load('w2crs.mat');
w2c = w2c.w2crs;

%copy the parameters to the struct
DSpara.hog_orientations=9; %feature selection for tracking
%DSpara.kernel=kernel; %kernel size and type
DSpara.interp_factor=interp_factor; %interpolation factor  插值系数 即学习率
DSpara.cell_size=cell_size; %HOG parameters
DSpara.padding=padding;
%DSpara.lambda=lambda;
DSpara.output_sigma_factor=output_sigma_factor;
DSpara.scales=scales; % fixed scales
DSpara.w2c = w2c;


% for DSKCF of occ
kernel_type='gaussian';
kernel.type = kernel_type;
kernel.sigma = 0.5;
kernel.poly_a = 1;
kernel.poly_b = 9;

%Different features that can be used
features.rawDepth= false;
features.rawColor=false;
features.rawConcatenate=false;
features.rawLinear=false;
features.hog_color = false;
features.hog_depth = false;
features.hog_linear = false;
features.hog_concatenate = true;
features.hog_orientations = 9;

%copy the parameters to the struct
DSpara_Occ.features=features; %feature selection for tracking
DSpara_Occ.kernel=kernel; %kernel size and type
DSpara_Occ.interp_factor=interp_factor; %interpolation factor
DSpara_Occ.cell_size=cell_size; %HOG parameters
DSpara_Occ.padding=1.5;
DSpara_Occ.lambda= 1e-4; 
DSpara_Occ.output_sigma_factor=output_sigma_factor;
DSpara_Occ.scales=scales; % fixed scales

%% PROCESSING LOOP

numVideo=length(listVideos);

    

    
    %mkdir(tmp_path);
    
    %For each selected sequence start to process!!!!!!
    for i=1:numVideo
        
        disp(['current padding is ' num2str(padding) '   video is  '   listVideos{i}]);
        
        %  tmpDestFolder=generateFolderResults(rootDestFolder,listVideos{i},feature_type);
        
        %转为matlab的坐标
        %格式 ground_truth = [x,y,w,h]
        %target_sz = [h, w];
        %pos = [x,y] + floor(target_sz/2);
        [img_files, depth_files, pos, target_sz, init_rect,ground_truth video_path, depth_path] = ...
            load_video_info_depthFROMMAT(rootSourceFolder, listVideos{i});
        
        
        %call tracker wrapper function with all the relevant parameters
        [dsKCFoutput] =   wrapperDSKCF_CSR(video_path, depth_path,img_files, depth_files, pos, ...
            target_sz, ground_truth,DSpara,DSpara_Occ,show_visualization,save_result_into_txt,listVideos{i},tmp_path );
        
        
        %Results using Sr in [1] use this for your comparison
        % trackRes=[dsKCFoutput];
        %save([tmpDestFolder '/' listVideos{i} '.txt'], 'trackRes','-ascii');
        
        
    end
    
