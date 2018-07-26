
clc
clear all
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
rootSourceFolder=('/media/orbbec/7024AED824AEA1181/EvaluationSet');
%rootSourceFolder=('/home/orbbec/data');
cd(rootSourceFolder);
rootSourceFolder=pwd()


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
    %listVideos{1}='bear_front';
    %listVideos{1}='new_ex_occ4';
    %listVideos{2}='zcup_move_1';
    listVideos{1}='face_occ2';    
    %listVideos{1}='face_occ5';    
else
    listVideos=listAllVideos;
end

show_visualization=false; %show the tracking results live in a matlab figure


%% SETTING TRACKER'S PARAMETERS
padding = 1.5;  %extra area surrounding the target
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




%% PROCESSING LOOP

numVideo=length(listVideos);


%For each selected sequence start to process!!!!!!
for i=1:numVideo
    
listVideos{i}
  %  tmpDestFolder=generateFolderResults(rootDestFolder,listVideos{i},feature_type);
    
%格式 ground_truth = [x,y,w,h]
%  target_sz = [h, w];
%pos = [x,y] + floor(target_sz/2);
        [img_files, depth_files, pos, target_sz, ground_truth, video_path, depth_path] = ...
            load_video_info_depthFROMMAT(rootSourceFolder, listVideos{i});
    
    
    %call tracker wrapper function with all the relevant parameters
    [dsKCFoutput] =   wrapperDSKCF_CSR(video_path, depth_path,img_files, depth_files, pos, ...
        target_sz, DSpara,show_visualization,listVideos{i} );
   


    %Results using Sr in [1] use this for your comparison
   % trackRes=[dsKCFoutput];
    %save([tmpDestFolder '/' listVideos{i} '.txt'], 'trackRes','-ascii');

end