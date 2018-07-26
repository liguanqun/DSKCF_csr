function tracker = create_DSKCF_CSR_tracker(frameCurr,pos,target_sz,DSKCFWparameters)
       
% target_sz  [h,w]  !!!!
    init_mask = ones(target_sz);
    c = pos;
    bb = [pos pos+target_sz([2 1])];
    % filter parameters
    padding = DSKCFWparameters.padding;  % padding
    learning_rate = DSKCFWparameters.learning_rate;  % learning rate for updating filter
    feature_type = DSKCFWparameters.feature_type;

    % load and store pre-computed lookup table for colornames
    w2c = [];
    if sum(strcmp(feature_type, 'cn'))
        w2c = load('w2crs.mat');
        w2c = w2c.w2crs;
    end


    
        % features parameters
    cell_size = 1.0;
    if sum(strcmp(feature_type, 'hog'))
        cell_size = min(4, max(1, ceil((bb(3)*bb(4))/400)))
    end

    % size parameters 尺寸参数
    % reference target size: [width, height]
    base_target_sz = [target_sz(2), target_sz(1)];
    % reference template size: [w, h], does not change during tracking
    %相关的模板尺寸 ，跟踪过程中不改变
    template_size = floor(base_target_sz + padding*sqrt(prod(base_target_sz)));
    template_size = mean(template_size);
    template_size = [template_size, template_size];

    % rescale template after extracting to have fixed area
    %把尺寸调整到固定的尺寸 200＊200
    rescale_ratio = sqrt((200^2) / (template_size(1) * template_size(2)));
    if rescale_ratio > 1  % if already smaller - do not rescale
        rescale_ratio = 1;
    end
    
%调整之后的模板尺寸<=200*200  
    rescale_template_size = floor(rescale_ratio * template_size)




   % create gaussian shaped labels
    sigma = DSKCFWparameters.sigma;
    Y = fft2(gaussian_shaped_labels_csr(1,sigma, floor(rescale_template_size([2,1]) / cell_size)));

    %store pre-computed cosine window
    cos_win = hann(size(Y,1)) * hann(size(Y,2))';

    % scale adaptation parameters (from DSST)
    currentScaleFactor = DSKCFWparameters.currentScaleFactor;
    n_scales = DSKCFWparameters.n_scales;
    scale_model_factor = DSKCFWparameters.scale_model_factor;
    scale_sigma_factor = DSKCFWparameters.scale_sigma_factor;
    scale_step = DSKCFWparameters.scale_step;
    scale_model_max_area = DSKCFWparameters.scale_model_max_area;
    scale_sigma = sqrt(n_scales) * scale_sigma_factor;
    scale_lr = DSKCFWparameters.scale_lr;   % learning rate parameter

    %label function for the scales
    ss = (1:n_scales) - ceil(n_scales/2);
    ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
    ysf = single(fft(ys));


    if mod(n_scales,2) == 0
        scale_window = single(hann(n_scales+1));
        scale_window = scale_window(2:end);
    else
        scale_window = single(hann(n_scales));
    end

    ss = 1:n_scales;
    scaleFactors = scale_step.^(ceil(n_scales/2) - ss);

    template_size_ = template_size;
    if scale_model_factor^2 * prod(template_size_) > scale_model_max_area
        scale_model_factor = sqrt(scale_model_max_area/prod(template_size_));
    end

    scale_model_sz = floor(template_size_ * scale_model_factor);
    scaleSizeFactors = scaleFactors;
    min_scale_factor = scale_step ^ ceil(log(max(5 ./ template_size_)) / log(scale_step));
    max_scale_factor = scale_step ^ floor(log(min([size(img,1) size(img,2)] ./ base_target_sz)) / log(scale_step));

        %initialize depth distributions 初始化深度的分布
        [p,meanDepthObj,stdDepthObj,LabelRegions,regionIndex,Centers,LUT] = ...
            initDistributionFast(bb,frameCurr.depth16Bit,frameCurr.depthNoData);
        
        %for the first frame copy everything also in the current target
        %第一张图像 当前图像和前一张图像的参数相同
        trackerDSKCF_struct.currentTarget=trackerDSKCF_struct.previousTarget;






end