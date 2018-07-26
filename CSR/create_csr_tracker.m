function tracker = create_csr_tracker(img, init_bbox, init_params)

    if nargin < 3
        init_params = read_default_csr_parameters();
    end

    % transform polygon to axis-aligned bbox
    if numel(init_bbox) > 4,
        bb8 = round(init_bbox(:));
        x1 = round(min(bb8(1:2:end)));
        x2 = round(max(bb8(1:2:end)));
        y1 = round(min(bb8(2:2:end)));
        y2 = round(max(bb8(2:2:end)));
        bb = round([x1, y1, x2 - x1, y2 - y1]);
        
        init_mask = poly2mask(bb8(1:2:end)-bb(1), bb8(2:2:end)-bb(2), bb(4), bb(3));
    else
        bb = round(init_bbox);
        init_mask = ones(bb(4), bb(3));
    end


    % filter parameters
    padding = init_params.padding;  % padding
    learning_rate = init_params.learning_rate;  % learning rate for updating filter
    feature_type = init_params.feature_type;

    % load and store pre-computed lookup table for colornames
    w2c = [];
    if sum(strcmp(feature_type, 'cn'))
        w2c = load('w2crs.mat');
        w2c = w2c.w2crs;
    end

    % segmentation parameters分割相关的参数
    hist_lr = init_params.hist_lr;
    nbins = init_params.nbins;  % N bins for segmentation
    seg_colorspace = init_params.seg_colorspace;     % 'rgb' or 'hsv'
    use_segmentation = init_params.use_segmentation;  % false to disable use of segmentation
   %膨胀可能需要
    mask_diletation_type =  init_params.mask_diletation_type;  %  for function strel (square, disk, ...)
    mask_diletation_sz = init_params.mask_diletation_sz;

    % check if grayscale image (only 1 channel) or
    % check if grayscale image (3 the same channels)
    img0 = bsxfun(@minus, double(img), mean(img,3));
    if size(img,3) < 3 || sum(abs(img0(:))) < 10
        use_segmentation = false;
        % also do not use colornames
        [isused_cn, cn_idx] = ismember('cn', feature_type);
        if isused_cn
            feature_type(cn_idx) = [];
        end
    end

    % features parameters
    cell_size = 1.0;
    if sum(strcmp(feature_type, 'hog'))
        cell_size = min(4, max(1, ceil((bb(3)*bb(4))/400)))
    end

    % size parameters 尺寸参数
    % reference target size: [width, height]
    base_target_sz = [bb(3), bb(4)];
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

    % position of the target center
    c = bb([1,2]) + base_target_sz/2;

    % create gaussian shaped labels
    sigma = init_params.y_sigma;
    Y = fft2(gaussian_shaped_labels(1,sigma, floor(rescale_template_size([2,1]) / cell_size)));

    %store pre-computed cosine window
    cos_win = hann(size(Y,1)) * hann(size(Y,2))';

    % scale adaptation parameters (from DSST)
    currentScaleFactor = init_params.currentScaleFactor;
    n_scales = init_params.n_scales;
    scale_model_factor = init_params.scale_model_factor;
    scale_sigma_factor = init_params.scale_sigma_factor;
    scale_step = init_params.scale_step;
    scale_model_max_area = init_params.scale_model_max_area;
    scale_sigma = sqrt(n_scales) * scale_sigma_factor;
    scale_lr = init_params.scale_lr;   % learning rate parameter

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

    % create dummy mask (approximation for segmentation)
    % size of the object in feature space
    %创建一个假的mask，当分割出错的时候使用
    obj_size = floor(rescale_ratio * (base_target_sz/cell_size));
    x0 = floor((size(Y,2)-obj_size(1))/2);
    y0 = floor((size(Y,1)-obj_size(2))/2);
    x1 = x0 + obj_size(1);
    y1 = y0 + obj_size(2);
    target_dummy_mask = zeros(size(Y));
    target_dummy_mask(y0:y1, x0:x1) = 1;
    target_dummy_mask = single(target_dummy_mask);

    target_dummy_area = sum(target_dummy_mask(:));
    
    if use_segmentation
        % convert image in desired colorspace
        if strcmp(seg_colorspace, 'rgb')
            seg_img = img;
        elseif strcmp(seg_colorspace, 'hsv')
            seg_img = rgb2hsv(img);
            seg_img = seg_img * 255;
        else
            error('Unknown colorspace parameter');
        end

        % object rectangle region (to zero-based coordinates)
        obj_reg = [bb(1), bb(2), bb(1)+bb(3), bb(2)+bb(4)] - [1 1 1 1];

        % extract histograms
        hist_fg = mex_extractforeground(seg_img, obj_reg, nbins);
        hist_bg = mex_extractbackground(seg_img, obj_reg, nbins);

        % extract masked patch: mask out parts outside image
        [seg_patch, valid_pixels_mask] = get_patch(seg_img, c, currentScaleFactor, template_size);

        % segmentation
        [fg_p, bg_p] = get_location_prior([1 1 size(seg_patch, 2) size(seg_patch, 1)], base_target_sz, [size(seg_patch,2), size(seg_patch, 1)]);
        [~, fg, ~] = mex_segment(seg_patch, hist_fg, hist_bg, nbins, fg_p, bg_p);

        % cut out regions outside from image
        mask = single(fg).*single(valid_pixels_mask);
        mask = binarize_softmask(mask);

        % use mask from init pose
        init_mask_padded = zeros(size(mask));
        pm_x0 = floor(size(init_mask_padded,2) / 2 - size(init_mask,2) / 2);
        pm_y0 = floor(size(init_mask_padded,1) / 2 - size(init_mask,1) / 2);
        init_mask_padded(pm_y0:pm_y0+size(init_mask,1)-1, pm_x0:pm_x0+size(init_mask,2)-1) = init_mask;
        mask = mask.*single(init_mask_padded);

        % resize to filter size
        mask = imresize(mask, size(Y), 'nearest');

        % check if mask is too small (probably segmentation is not ok then)
        %检查分割的目标面积是否太小
        if mask_normal(mask, target_dummy_area)
            if mask_diletation_sz > 0
                D = strel(mask_diletation_type, mask_diletation_sz);
                mask = imdilate(mask, D);%膨胀操作
            end
        else
            mask = target_dummy_mask;
        end

    else
        mask = target_dummy_mask;
    end

    % 提取特征
    f = get_csr_features(img, c, currentScaleFactor, template_size, ...
                rescale_template_size, cos_win, feature_type, w2c, cell_size);

    %创建滤波器 使用分割的mask
    H = create_csr_filter(f, Y, single(mask));

    % 预计算 channel 的权值
    response = real(ifft2(fft2(f).*conj(H)));
    chann_w = max(reshape(response, [size(response,1)*size(response,2), size(response,3)]), [], 1);
    % normalize: sum = 1
    chann_w = chann_w / sum(chann_w);

    %一个尺度搜索的模型
    xs = get_scale_subwindow(img, c([2,1]), base_target_sz([2,1]), ...
        currentScaleFactor * scaleSizeFactors, scale_window, scale_model_sz([2,1]), []);
    % 在尺度的维度上fft
    xsf = fft(xs,[],2);
    new_sf_num = bsxfun(@times, ysf, conj(xsf));
    new_sf_den = sum(xsf .* conj(xsf), 1);

    % store all important const's and variables to the tracker structure
    %% DSpara 不变常量
    tracker.feature_type = feature_type;                                              %DSpara
    tracker.padding = padding;                                                              %DSpara
    tracker.learning_rate = learning_rate;  % filter learning rate           %DSpara
    tracker.cell_size = cell_size;                                                            %DSpara
    tracker.weight_lr = init_params.channels_weight_lr;                    %DSpara  = learning_rate
    tracker.nbins = nbins;                                                               % DSpara   hog.nbina   
    tracker.w2c = w2c;                                                                   %常量  DSpara    
   %% 目标的位置尺寸
    tracker.obj_size = obj_size;                                                    %  目标size 也是mask的大小  tracker
    tracker.c = c;                                                                          % 目标中心  tracker
    tracker.bb = bb;                                                                            %目标矩形  tracker
    tracker.template_size = template_size;                                   %常量 目标的大小  长宽一致  tracker or DSpara
    tracker.rescale_template_size = rescale_template_size;             %常量 调整之后的尺寸<=200 tracker or DSpara
    tracker.rescale_ratio = rescale_ratio;                                     %  尺寸调整比例 常量  tracker or DSpara  
    tracker.base_target_sz = base_target_sz;                            % tracker  
    
  %% 滤波器相关的

    tracker.chann_w = chann_w;                                                          %  权值 放在tracker里带着
    tracker.Y = Y;                                                                                  %目标函数，根据尺度更新，需要放在tracker里带着
    tracker.H = H;                                                                                  %tracker
    tracker.mask = mask;                                                              % mask tracker  
    tracker.H_prev = H;                                                              % H_prev  tracker
    tracker.img_prev = img;                                                         %img_prec  frameCurr
     tracker.cos_win = cos_win;                                                        %目标cos_win  tracker       
    
  %% no need  
      tracker.use_channel_weights = init_params.use_channel_weights; %不需要   %   true   
    tracker.mask_diletation_type = mask_diletation_type;                %不需要     %膨胀操作的类型 
    tracker.mask_diletation_sz = mask_diletation_sz;                        %不需要     %膨胀操作的 尺寸
    tracker.target_dummy_mask = target_dummy_mask;                   %不需要    %创建一个假的mask，当分割出错的时候使用
    tracker.target_dummy_area = target_dummy_area;                      %不需要
    tracker.use_segmentation = use_segmentation;                          %不需要

    

    tracker.currentScaleFactor = currentScaleFactor;                  %不需要  %当前的尺度系数

    if use_segmentation                                                              %不需要 true
        tracker.hist_fg = hist_fg;                                                      %不需要
        tracker.hist_bg = hist_bg;                                                    %不需要
        tracker.hist_lr = hist_lr;                                                     %不需要
        tracker.seg_colorspace = seg_colorspace;                           %不需要
    end
    tracker.ysf = ysf;                                                                   %不需要          尺度搜索
    tracker.sf_num = new_sf_num;                                            %不需要尺度搜索
    tracker.sf_den = new_sf_den;                                              %不需要尺度搜索
    tracker.scale_lr = scale_lr;                                                   %不需要   尺度搜索 DSST

    tracker.scaleSizeFactors = scaleSizeFactors;                          %不需要          尺度搜索
    tracker.scale_window = scale_window;                                  %不需要          尺度搜索
    tracker.scale_model_sz = scale_model_sz;                              %不需要          尺度搜索
    tracker.scaleFactors = scaleFactors;                                       %不需要          尺度搜索
    tracker.min_scale_factor = min_scale_factor;                            %不需要          尺度搜索
    tracker.max_scale_factor = max_scale_factor;                          %不需要          尺度搜索

    


end  % endfunction
