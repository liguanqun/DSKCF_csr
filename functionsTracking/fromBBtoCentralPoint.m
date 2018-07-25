function [centerX,centerY,width,height]=fromBBtoCentralPoint(bb)

width=bb(3)-bb(1);
height=bb(4)-bb(2);
centerX=floor(bb(1)+width/2);%column indexes
centerY=floor(bb(2)+height/2);%row indexes

end