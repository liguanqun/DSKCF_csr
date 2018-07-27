
function [ response, maxResponse, maxPositionImagePlane] = maxResponseDSKCF_CSR...
( patch,patch_depth,prevPos,cell_size, cos_window,w2c,chann_w, H ,nRows,nCols)

  f = get_DSKCF_CSR_feature(patch, patch_depth, cell_size,cos_window, w2c);

  response = real(ifft2(fft2(f).*conj(H)));

maxResponse=max(response(:));
[vert_delta, horiz_delta] = find(response == maxResponse, 1);
if vert_delta > size(response,1) / 2,  %wrap around to negative half-space of vertical axis
    vert_delta = vert_delta - size(response,1);
end
if horiz_delta > size(response,2) / 2,  %same for horizontal axis
    horiz_delta = horiz_delta - size(response,2);
end
maxPositionImagePlane = prevPos + cell_size * [vert_delta - 1, horiz_delta - 1];

maxPositionImagePlane(maxPositionImagePlane<1)=1;
if(maxPositionImagePlane(1)>nRows)
    maxPositionImagePlane(1)=nRows;
end
if(maxPositionImagePlane(2)>nCols)
    maxPositionImagePlane(2)=nCols;
end

