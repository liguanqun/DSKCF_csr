
function [ response, maxResponse, maxPositionImagePlane] = maxResponseDepthWeightDSKCF...
( patch,patch_depth,depth16Bit, features,kernel,pos,cell_size, cos_window,...
model_xf,model_alphaf,model_xDf,model_alphaDf,meanDepthObj,stdDepthObj)
%MAXRESPONSEDEPTHWEIGHTDSKCF function for calculating the DSKCF response %
%
%MAXRESPONSEDEPTHWEIGHTDSKCF.m is a function used for calculating the DSKCF response
%by weighting it with the depth values and the target depth distribution
%For more information about the DSKCF response see [1]. Please note that
%this function was partially built extending the KCF tracker code presented
%by Joao F. Henriques, in http://www.isr.uc.pt/~henriques/.
%
%
%  INPUT:
%  -patch patch of the color data
%  -patch_depth patch of the depth data
%  - depth16Bit   depth image
%  -features struct containing feature info.
%  -cell_size HOG parameter
%  -cos_window cosine window to smooth data in the Fourier domain
%  -kernel struct containing kernel information
%  - model_alphaf, model_alphaDf, model_xf, model_xDf are the models to be
%  updated (for depth and color if the two features are used indipendently)
%  -meanDepthObj mean depth value of the target object
%  -pos is the position of the tracked target in the previous frame [y
%  x] format (read as ([row column]))
%
%  OUTPUT
%  - response response of DSKCF
%   -maxResponse maximum value of the DSKCF response
%   -maxPositionImagePlane vector containing the position in the image
%   plane of the target's centroid. It is in the format [y, x] (read also as
%   [rowIndex, columIndex])


if(features.hog_linear)
    
    [zf zDf]=get_features_depth(patch,patch_depth, features, cell_size, cos_window);
    zf=fft2(zf);
    zDf=fft2(zDf);
    %calculate response of the classifier at all shifts
    switch kernel.type
        case 'gaussian',        
            kzf = gaussian_correlation(zf, model_xf, kernel.sigma);
            kzDf = gaussian_correlation(zDf, model_xDf, kernel.sigma);
          
        case 'polynomial',
            kzf = polynomial_correlation(zf, model_xf, kernel.poly_a, kernel.poly_b);
            kzDf = polynomial_correlation(zDf, model_xDf, kernel.poly_a, kernel.poly_b);
        case 'linear',
            kzf = linear_correlation(zf, model_xf);
            kzDf = linear_correlation(zDf, model_xDf);
    end
    response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection
    responseD = real(ifft2(model_alphaDf .* kzDf));
    
    %COMBINATION OF RESPONSES LINEAR...
    response=response+responseD;
    response=response./2;
    
    %Combination of Response....select maximmun
    %maxResponseRGB=max(response(:));
    %[maxResponseD,index]=max(responseD(:));
    %if(maxResponseD>maxResponseRGB)
    %    response(index)=maxResponseD;
    %end
else
            
    [zf dummyValue]=get_features_depth(patch,patch_depth, features, cell_size, cos_window);
    zf=fft2(zf);
    
    %calculate response of the classifier at all shifts
    switch kernel.type
        case 'gaussian',
            kzf = gaussian_correlation(zf, model_xf, kernel.sigma);
        case 'polynomial',
            kzf = polynomial_correlation(zf, model_xf, kernel.poly_a, kernel.poly_b);
        case 'linear',
            kzf = linear_correlation(zf, model_xf);
    end
    response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection
   % response_shift = fftshift(response);

end

%now select the maximum adding a depth weight
%the number of candidate is set to 10 根据深度值的分布 对 response 加权
[maxResponse,maxPositionImagePlane]=bestResponses(depth16Bit,response,10,...
    cell_size,pos,meanDepthObj,stdDepthObj);
