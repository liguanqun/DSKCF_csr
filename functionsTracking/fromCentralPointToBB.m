
function bb=fromCentralPointToBB(centerX,centerY,width,height,maxX,maxY)

bb(1)=max(1,centerX-width/2);%column indexes
bb(2)=max(1,centerY-height/2);%row indexes
bb(3)=min(maxX,centerX+width/2);%column indexes
bb(4)=min(maxY,centerY+height/2);%row indexes
bb=floor(bb(:));
end