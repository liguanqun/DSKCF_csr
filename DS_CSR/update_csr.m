function [ chann_w,model_H ] = update_csr( firstFrame,patch,patch_depth,cell_size,w2c,...
    cos_window,Y, mask ,scaleUpdate,interp_factor)

    f = get_DSKCF_CSR_feature(patch, patch_depth, cell_size,cos_window, w2c);
   
   obj_size = floor([size(mask, 1) size(mask, 2)] ./ cell_size);   
    mask_rescale =zeros(obj_size);
    
    for i=1:obj_size(1)
        
        for j=1:obj_size(2)
             tmp_1 = cell_size*(i-1) ;
             tmp_2 = cell_size*(j-1);
           for m=1:4
               for n=1:4
                 if  mask(tmp_1+m,tmp_2+n)==1
                     mask_rescale(i,j)=1;
                 end                
               end               
           end
        end        
    end
    
    
    
    
   out_size = floor([size(patch, 1) size(patch, 2)] ./ cell_size);
    x0 = floor((out_size(2)-obj_size(2))/2);
    y0 = floor((out_size(1)-obj_size(1))/2);
    x1 = x0 + obj_size(2);
    y1 = y0 + obj_size(1);
    mask_padding = zeros(out_size);
    mask_padding(y0:y1-1, x0:x1-1) = mask_rescale;
    mask_padding = single(mask_padding);
    
    
    %创建滤波器 使用分割的mask
    H = create_csr_filter(f, Y, single(mask_padding));
      
%     f = fft2(f);
    
    % 预计算 channel 的权值
    response = real(ifft2(fft2(f).*conj(H)));
    chann_w = max(reshape(response, [size(response,1)*size(response,2), size(response,3)]), [], 1);
    % normalize: sum = 1
    chann_w = chann_w / sum(chann_w);

        if (firstFrame),  %first frame, train with a single image
        model_H = H;
%         model_f = f;
    else
            %subsequent frames, interpolate model
        if(scaleUpdate)
            
                model_H = updownsample_fourier( model_H,size(H,2),size(H ,1));
%                 model_f_ = f;
%                 for i = 1:size(f,3)
%                     model_f_(:,:,i) = updownsample_fourier( model_f(:,:,i),size(f,2),size(f ,1));
%                 end
%                 model_f =  model_f_;
                
              model_H = (1 - interp_factor) * model_H + interp_factor * H;
%               model_f = (1 - interp_factor) * model_f + interp_factor * f;
     else
            model_H = (1 - interp_factor) * model_H + interp_factor * H;
%             model_f = (1 - interp_factor) * model_f + interp_factor * f;
        end
        end
    
        
 
end

