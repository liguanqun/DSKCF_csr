function [ out ] = get_DSKCF_CSR_feature(patch, patch_depth, cell_size,cos_window, w2c)

% hog features
nHogChan = 18;

%                        path_hog   + path_hog  + gray   +   cn
 num_feat_ch =   nHogChan + nHogChan +   1     +  size(w2c,2);   
 
 
out_size = floor([size(patch, 1) size(patch, 2)] ./ cell_size);
out = zeros(out_size(1), out_size(2), num_feat_ch);



channel_id = 1;
    %% extract HoG features
    nOrients = 9;
	hog_image = fhog(single(patch), cell_size, nOrients);
    % put HoG features into output structure
    out(:,:,channel_id:(channel_id + nHogChan - 1)) = hog_image(:,:,1:nHogChan);
    channel_id = channel_id + nHogChan;

  	hog_depth = fhog(single(patch_depth), cell_size, nOrients);
    % put HoG features into output structure
    out(:,:,channel_id:(channel_id + nHogChan - 1)) = hog_depth(:,:,1:nHogChan);
    channel_id = channel_id + nHogChan;  
    
  %%  prepare grayscale patch
	if size(patch,3) > 1
		gray_patch = rgb2gray(patch);
	else
		gray_patch = patch;
    end
    % resize it to out size
	gray_patch = imresize(gray_patch, out_size);
    % put grayscale channel into output structure
    out(:, :, channel_id) = single((gray_patch / 255) - 0.5);
    channel_id = channel_id + 1;
      
    
%%  extract ColorNames features
    CN = im2c(single(patch), w2c, -2);
    CN = imresize(CN, out_size);
    % put colornames features into output structure
    out(:,:,channel_id:(channel_id + size(w2c, 2) - 1)) = CN;
    channel_id = channel_id + size(w2c,2);
    
 %% multiply with cosine window
if ~isempty(cos_window)
    out = bsxfun(@times, out, cos_window);
end 


end

