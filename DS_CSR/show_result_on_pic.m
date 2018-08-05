clc;clear all;close all;


currentFolder=pwd();
disp(currentFolder);
%%add the DS-KCFresults

result_Folder = ('/home/orbbec/dskcf_result_save/DSKCF_simaple/testall4');

%now select the data folder
rootSourceFolder=('/media/orbbec/7024AED824AEA1181/EvaluationSet');
%  rootSourceFolder=('/home/orbbec/data');
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
    listVideos{1}='basketball2.2';
    %          listVideos{1}='face_occ5';
    %     listVideos{1}='zcup_move_1';
    %     listVideos{1}='face_occ5';
    %   listVideos{1}='basketball1';
else
    listVideos=listAllVideos;
end


numVideo=length(listVideos);

myfigure =figure();

%For each selected sequence start to process!!!!!!
for i=1:numVideo
    
    listVideos{i}
    
    [img_files, depth_files, pos, target_sz, init_rect,ground_truth video_path, depth_path] = ...
        load_video_info_depthFROMMAT(rootSourceFolder, listVideos{i});
    
    cd(result_Folder);
    result =  load([listVideos{i} '.txt']);
    if numel(img_files) ==size(result,1)
        for j=1:size(result,1)
            disp(['frame is '  num2str(j)]);
            im = imread([video_path img_files{j}]);
            figure(myfigure)
            hold on;
            imshow(im);
            text(25,15,listVideos{i},'color','r','fontsize',10,'fontweight','bold');
             text(600,15,num2str(j),'color','r','fontsize',10,'fontweight','bold');
            bb = result(j,1:4);
            bb([3:4]) =bb([3:4]) -bb([1:2]);
            if(isempty(bb)==false & isnan(bb)==false)
                if(bb(1)>size(im,2) | bb(2)>size(im,1))
                    bb=[];
                else
                    bb(bb(1:2)<0)=1;
                    if(bb(1)+bb(3)>size(im,2))
                        bb(3)=size(im,2)-bb(1);
                    end
                    
                    if( bb(2)+bb(4)>size(im,1))
                        bb(4)=size(im,1)-bb(2);
                    end
                    
                    rectangle('Position', bb,'LineWidth',2,'edgecolor','r');
                end
            end
            pause();
        end
        
    else
        disp('not have the same size ');
    end
    
    
end

