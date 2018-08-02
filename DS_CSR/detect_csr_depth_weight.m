function [maxResponse,response,maxResponse_chann,pos,channel_discr]=detect_csr_depth_weight(patch,patch_depth,depth16Bit,pos,cell_size, cos_window,...
    w2c,chann_w, H,use_channel_wl ,meanDepthObj,stdDepthObj)

f = get_DSKCF_CSR_feature(patch, patch_depth, cell_size,cos_window, w2c);

if use_channel_wl
    response_chann = real(ifft2(fft2(f).*conj(H)));
     response_chann_sum = real(ifft2(sum(fft2(f).*conj(H), 3)));
    response = sum(bsxfun(@times, response_chann, reshape(chann_w, 1, 1, size(response_chann,3))), 3);
else
    response = real(ifft2(sum(fft2(f).*conj(H), 3)));
end

maxResponse_chann =max(response_chann_sum(:));

% disp(['max response 2 frame',num2str(max(response(:)) , '%.5f')]);
[maxResponse,pos]=bestResponses(depth16Bit,response,10,...
    cell_size,pos,meanDepthObj,stdDepthObj);



% calculate detection-based weights
if use_channel_wl
    channel_discr = ones(1, size(response_chann, 3));
    for i = 1:size(response_chann, 3)
        norm_response = normalize_img(response_chann(:, :, i));
        local_maxs_sorted = localmax_nonmaxsup2d(squeeze(norm_response(:, :)));
        
        if local_maxs_sorted(1) == 0, continue; end;
        channel_discr(i) = 1 - (local_maxs_sorted(2) / local_maxs_sorted(1));
        
        % sanity checks
        if channel_discr(i) < 0.5, channel_discr(i) = 0.5; end;
    end
else  
    channel_discr =[];
end

% % find position of the maximum
% [row, col] = ind2sub(size(response),find(response == max(response(:)), 1));
% 
% % subpixel accuracy: response map is smaller than image patch -
% % due to HoG histogram (cell_size > 1)
% v_neighbors = response(mod(row + [-1, 0, 1] - 1, size(response,1)) + 1, col);
% h_neighbors = response(row, mod(col + [-1, 0, 1] - 1, size(response,2)) + 1);
% row = row + subpixel_peak(v_neighbors);
% col = col + subpixel_peak(h_neighbors);
% 
% % wrap around
% if row > size(response,1) / 2,
%     row = row - size(response,1);
% end
% if col > size(response,2) / 2,
%     col = col - size(response,2);
% end

% displacement
%     d = cell_size * [col - 1, row - 1];
% d = cell_size * [row - 1, col - 1];
% % new object center
% pos = pos + d;





end
function delta = subpixel_peak(p)
%parabola model (2nd order fit)
delta = 0.5 * (p(3) - p(1)) / (2 * p(2) - p(3) - p(1));
if ~isfinite(delta), delta = 0; end
end  % endfunction

function dupl = duplicate_frames(img, img_prev)
dupl = false;
I_diff = abs(single(img) - single(img_prev));
if mean(I_diff(:)) < 0.5
    dupl = true;
end
end  % endfunction

function [local_max] = localmax_nonmaxsup2d(response)
BW = imregionalmax(response);
CC = bwconncomp(BW);

local_max = [max(response(:)) 0];
if length(CC.PixelIdxList) > 1
    local_max = zeros(length(CC.PixelIdxList));
    for i = 1:length(CC.PixelIdxList)
        local_max(i) = response(CC.PixelIdxList{i}(1));
    end
    local_max = sort(local_max, 'descend');
end
end  % endfunction

function out = normalize_img(img)
min_val = min(img(:));
max_val = max(img(:));
if (max_val - min_val) > 0
    out = (img - min_val)/(max_val - min_val);
else
    out = zeros(size(img));
end
end  % endfunction

