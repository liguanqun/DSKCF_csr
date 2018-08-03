
close all;clear all;clc;
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


for i=1:length(dskcfPath)
    cd([currentFolder dskcfPath{i}]);
    tmpPath=cd();
    %addpath(genpath(tmpPath));
    addpath(tmpPath);
    cd(currentFolder);
end

cd(currentFolder)

%insert here the absolute path here you want to save your results or use
%the relative path DS-KCFresults 
rootDestFolder=('DS-KCFresults');

mkdir(rootDestFolder);
cd(rootDestFolder);
%take absolute value and create the results folder
rootDestFolder=cd();


cd(currentFolder)

%now select the data folder
rootSourceFolder=('/media/orbbec/7024AED824AEA1181/EvaluationSet/');
%rootSourceFolder=('/home/orbbec/data');
cd(rootSourceFolder);
rootSourceFolder=pwd();


%select all the videos in the folder
dirInfo = dir();            
isDir = [dirInfo.isdir];             
listAllVideos = {dirInfo(isDir).name};   
listAllVideos = listAllVideos(3:end);

%If you don't want to precess all the video set this to false
processAllVideos=false;

%eventually select your subset of videos
if(processAllVideos==false)
    %insert video names manually!!!!
     listVideos{1}='basketball2';
%     listVideos{1}='new_ex_occ4';
    %listVideos{2}='zcup_move_1';
   % listVideos{1}='child_no1';    
%      listVideos{1}='face_occ5';    
else
    listVideos=listAllVideos;
end

show_visualization=true ; %show the tracking results live in a matlab figure
save_result_to_txt =false;

%% SETTING TRACKER'S PARAMETERS
%  the struct "DSKCFparameters" is built to contains all the parameters it
%  will be created at the end of the section
kernel_type='gaussian';

%change only this flag for feature selection, the rest is automatic!!!!
feature_type = 'hog_concatenate';
kernel.type = kernel_type;

%Different features that can be used
features.rawDepth= false;
features.rawColor=false;
features.rawConcatenate=false;
features.rawLinear=false;
features.hog_color = false;
features.hog_depth = false;
features.hog_concatenate = false;
features.hog_linear = false;


padding = 1.5;  %extra area surrounding the target
lambda = 1e-4;  %regularization
output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)

%Set the scale Sq in [1]  尺度设置
scales = 0.4:0.1:2.2;


%Note this switch is not necessary, you can eventually 
switch feature_type


    case 'hog_concatenate'
        interp_factor = 0.02;
        
        kernel.sigma = 0.5;
        
        kernel.poly_a = 1;
        kernel.poly_b = 9;
        
        features.hog_concatenate = true;
        features.hog_orientations = 9;
        cell_size = 4;

    otherwise
        error('Unknown feature.')
end

%copy the parameters to the struct
DSpara.features=features; %feature selection for tracking
DSpara.kernel=kernel; %kernel size and type
DSpara.interp_factor=interp_factor; %interpolation factor
DSpara.cell_size=cell_size; %HOG parameters
DSpara.padding=padding;
DSpara.lambda=lambda; 
DSpara.output_sigma_factor=output_sigma_factor;
DSpara.scales=scales; % fixed scales

%% PROCESSING LOOP

numVideo=length(listVideos);


%For each selected sequence start to process!!!!!!
for i=1:numVideo
    
listVideos{i}
  %  tmpDestFolder=generateFolderResults(rootDestFolder,listVideos{i},feature_type);
    
%格式 ground_truth = [x,y,w,h]
%  target_sz = [h, w];
%pos = [x,y] + floor(target_sz/2);
        [img_files, depth_files, pos, target_sz,init_rect, ground_truth, video_path, depth_path] = ...
            load_video_info_depthFROMMAT(rootSourceFolder, listVideos{i});
    
    
    %call tracker wrapper function with all the relevant parameters
    [dsKCFoutput] =   wrapperDSKCF(video_path, depth_path,img_files, depth_files, pos, ...
        target_sz,ground_truth, DSpara,show_visualization,save_result_to_txt,listVideos{i} );
   


    %Results using Sr in [1] use this for your comparison
   % trackRes=[dsKCFoutput];
    %save([tmpDestFolder '/' listVideos{i} '.txt'], 'trackRes','-ascii');

end