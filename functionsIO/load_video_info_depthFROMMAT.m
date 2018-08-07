function [img_files, depth_files, pos, target_sz, init_rect, ground_truth,video_path, depth_path] = load_video_info_depthFROMMAT(base_path, video)
% LOAD_VIDEO_INFO_DEPTHFROMMAT.m is a automatically generates the relevant information for the video in the given path
%
%   LOAD_VIDEO_INFO_DEPTHFROMMAT loads all the relevant information for the
%   sequence depth and video data in the given path for the Princeton RGB-D
%   dataset [1]. This function have been created starting grom
%   load_video_info of the KCF matlab library presented by Joao F.
%   Henriques, in http://www.isr.uc.pt/~henriques/. A similar function need
%   to be implemented if another dataset that uses another naming
%   convention is processed. See for example LOAD_VIDEO_INFO_BOBOTRESULTS
%   for the BOBOT-D dataset [2]
%
%   INPUT:
%  -base_path name of the top folder where sequences are stored
%  -video name of the sequence that will be processed
%  -newOrder boolean type to select the realigned frame order (see [3]) or
%  the one proposed in [1]
%
%   OUTPUT
%  -img_files the list of Color data files (images in the folder are
%  supposed to be *.png) 
%  -depth_files the list of Depth data files (images in the folder are
%  supposed to be  16 bit *.png)
%  -pos initial DS-KCF tracker position pos=[y x] where x is the column
%  index and y is the row index of the image
%  -target_sz initial target size target_sz=[height,width]
%  -ground_truth ground truth information
%  -video_path  absolute path of color data
%  -depth_path  absolute path of depth data
%
%  See also LOAD_VIDEO_INFO_BOBOTRESULTS
%
% [1] S. Song and J. Xiao. Tracking revisited using RGBD camera: Unified
% benchmark and baselines. In Computer Vision (ICCV), 2013 IEEE
% International Conference on, pages 233�240, 2013.
%
%  [2]Germ�n Mart�n Garc�a, Dominik A. Klein, J�rg St�ckler, Simone
%  Frintrop, and Armin B. Cremers DAGM/OAGM Conference, August 28-31, 2012,
%  Graz, Austria
%
%
%  University of Bristol 
%  Massimo Camplani and Sion Hannuna
%  
%  massimo.camplani@bristol.ac.uk 
%  hannuna@compsci.bristol.ac.uk


%full path to the video's files
if base_path(end) ~= '/' && base_path(end) ~= '\',
    base_path(end+1) = '/';
end
video_path = [base_path video '/'];

filename = [video_path 'init.txt'];
f = fopen(filename);
assert(f ~= -1, ['No initial position or ground truth to load ("' filename '").'])

%the format is [x, y, width, height]
try
    init_rect = textscan(f, '%f,%f,%f,%f', 'ReturnOnError',false);
catch  %#ok, try different format (no commas)
    frewind(f);
    init_rect = textscan(f, '%f %f %f %f');
end
init_rect = cat(2, init_rect{:});
fclose(f);


%set initial position and size
target_sz = [init_rect(1,4), init_rect(1,3)];
pos = [init_rect(1,2), init_rect(1,1)] + floor(target_sz/2);

if size(init_rect,1) == 1,
    %we have ground truth for the first frame only (initial position)
    init_rect = [];
else
    %store positions instead of boxes
    init_rect = init_rect(:,[2,1]) + init_rect(:,[4,3]) / 2;
end
% 读 frames.mat  or frames.json
 load([video_path 'frames'])

numOfFrames = frames.length;

ground_truth_file_name =  [video_path video '.txt'];

f = fopen(ground_truth_file_name);

if f ==-1
    disp('there is no groundtruth ');
    ground_truth =[];
else
    i=1;
    disp('there is  groundtruth ');
    ground_truth = zeros(numOfFrames,5);
    while ~feof(f)
        tline=fgetl(f);
        if double(tline(1)>=48&&tline(1)<=57)
            ground_truth(i,:)=str2num(tline);
            
        else
             ground_truth(i,:)=[0,0,0,0,i];
        end
      i =i+1;
    end
     i=i-1;
      if numOfFrames ~= i
          num =min(i,numOfFrames);
        ground_truth = ground_truth(1:num,:);
        numOfFrames =num;      
      end
end

%from now on, work in the subfolder where all the images are


depth_path = [video_path 'depth/'];
video_path = [video_path 'rgb/'];

%general case, just list all images
img_files_ = dir([video_path '*.png']);
assert(~isempty(img_files_), 'No image files to load.')

depth_files_ = dir([depth_path '*.png']);
assert(~isempty(depth_files_), 'No depth files to load.')



for i = 1:numOfFrames
    img_files{i} = sprintf('r-%d-%d.png',frames.imageTimestamp(i), frames.imageFrameID(i));
    depth_files{i} = sprintf('d-%d-%d.png',frames.depthTimestamp(i), frames.depthFrameID(i));
    
end


end

