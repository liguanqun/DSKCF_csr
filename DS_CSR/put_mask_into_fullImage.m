function mask= put_mask_into_fullImage(pos,im,mask)


 tmp = zeros(size(im,1),size(im,2));
 
xs = floor( pos(1) - size(mask,1)/2 ) : floor( pos(1) - size(mask,1)/2 ) + size(mask,1) -1;
ys = floor( pos(2) - size(mask,2)/2 ) : floor( pos(2) - size(mask,2)/2 ) + size(mask,2) -1 ;

xs(xs<1) =1;
ys(ys<1)=1;
xs(xs>size(im,1))=size(im,1);
ys(ys>size(im,2)) =size(im,2);

tmp(xs,ys) =mask(:,:);

mask =tmp;


end

