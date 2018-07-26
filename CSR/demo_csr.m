function demo_csr()

% set this to tracker directory
tracker_path = '/home/orbbec/git_ws/csr-dcf-master';
% add paths
addpath(tracker_path);
addpath(fullfile(tracker_path, 'mex'));
addpath(fullfile(tracker_path, 'utils'));
addpath(fullfile(tracker_path, 'features'));

visualize_tracker = true;
use_reinitialization = true;

% choose name of the VOT sequence
sequence_name = 'child_no1';    

% path to the folder with VOT sequences
base_path = '/home/orbbec/data';
base_path = fullfile(base_path, sequence_name);

rgb_path = fullfile(base_path, 'rgb');
rgb_dir = dir(fullfile(rgb_path,'*.png'));

nameCell = cell(length(rgb_dir),1);
for i = 1:length(rgb_dir)
    disp(rgb_dir(i).name)
    nameCell{i} = rgb_dir(i).name;
end
rgb_dir = sort_nat(nameCell);


% initialize bounding box - [x,y,width, height]
gt8 = dlmread(fullfile(base_path, 'init.txt'));
base_path =[base_path '/' sequence_name '.txt'];
gt = read_vot_regions(base_path);


start_frame = 1;
n_failures = 0;
time = zeros(numel(rgb_dir), 1);
n_tracked = 0;

if visualize_tracker
    figure(1); clf;
end

frame = start_frame;
while frame <= numel(rgb_dir),  % tracking loop
	% read frame
    impath = fullfile(rgb_path, rgb_dir{frame});
    img = imread(impath);
    
    tic()
	% initialize or track
	if frame == start_frame
        
        bb = gt8(1,:) + 1;  % add 1: ground-truth top-left corner is (0,0)
		tracker = create_csr_tracker(img, bb);
      %  bb = gt(frame,:);  % just to prevent error when plotting
        
    else
        
		[tracker, bb] = track_csr_tracker(tracker, img);
        
    end
    time(frame) = toc();
    
    n_tracked = n_tracked + 1;
    
    % visualization and failure detection
    if visualize_tracker
        
        figure(1); if(size(img,3)<3), colormap gray; end
        imagesc(uint8(img))
        hold on;
        rectangle('Position',bb,'LineWidth',1,'EdgeColor','b');
        rectangle('Position',gt(frame,:),'LineWidth',1,'EdgeColor','r');
        text(15, 25, num2str(n_failures), 'Color','r', 'FontSize',  15, 'FontWeight', 'bold');
        
        if use_reinitialization  % detect failures and reinit
            area = rectint(bb, gt(frame,:))
            pause;
            if area < eps && use_reinitialization
                disp('Failure detected. Reinitializing tracker...');
                frame = frame + 4;  % skip 5 frames at reinit (like VOT)
                start_frame = frame + 1;
                n_failures = n_failures + 1;
            end
        end

        hold off;
        if frame == start_frame
            truesize;
        end
        drawnow; 
    end
    
    frame = frame + 1;

end

fps = n_tracked / sum(time);
fprintf('FPS: %.1f\n', fps);

end  % endfunction