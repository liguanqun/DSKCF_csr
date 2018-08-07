function modifiedImage=show_with_ground_trurh(img,bb,bbOCC,bb_truth,myColor,myColorOCC,lWidth,myText1,myText2,myFigNumber,frame)

imageSize=[size(img,2),size(img,1)];

figure(myFigNumber)
%myFig=figure('visible','off');
%set(myFig,'resize','off');
hold on;
imshow(img);
if(isempty(myText1)==false)
    text(25,15,myText1,'color',myColor,'fontsize',10,'fontweight','bold');
end
if(isempty(myText2)==false)
    text(25,30,myText2,'color',myColorOCC,'fontsize',10,'fontweight','bold');
end
if(isempty(frame)==false)
    text(600,15,num2str(frame),'color','b','fontsize',10,'fontweight','bold');
end

if(isempty(bb)==false & isnan(bb)==false)
    if(bb(1)>imageSize(1) | bb(2)>imageSize(2))
        bb=[];
    else
        bb(bb(1:2)<0)=1;
        if(bb(1)+bb(3)>imageSize(1))
            bb(3)=imageSize(1)-bb(1);
        end
        
        if( bb(2)+bb(4)>imageSize(2))
            bb(4)=imageSize(2)-bb(2);
        end
        
        rectangle('Position', bb,'LineWidth',lWidth,'edgecolor',myColor);
    end
end
if(isempty(bb_truth)==false & isnan(bb_truth)==false)
    if(bb_truth(1)>imageSize(1) | bb_truth(2)>imageSize(2))
        bb_truth=[];
    else
        bb_truth(bb_truth(1:2)<0)=1;
        if(bb_truth(1)+bb_truth(3)>imageSize(1))
            bb_truth(3)=imageSize(1)-bb_truth(1);
        end
        
        if( bb_truth(2)+bb_truth(4)>imageSize(2))
            bb_truth(4)=imageSize(2)-bb_truth(2);
        end
        
        rectangle('Position', bb_truth,'LineWidth',lWidth,'edgecolor','b');
    end
end

if(isempty(bbOCC)==false & isnan(bbOCC)==false)
    
    if(bbOCC(1)>imageSize(1) | bbOCC(2)>imageSize(2))
        bbOCC=[];
    else
        bb(bbOCC(1:2)<0)=1;
        if(bbOCC(1)+bbOCC(3)>imageSize(1))
            bbOCC(3)=imageSize(1)-bbOCC(1)+1;
        end
        
        if( bbOCC(2)+bbOCC(4)>imageSize(2))
            bbOCC(4)=imageSize(2)-bbOCC(2)+1;
        end
        rectangle('Position', bbOCC,'LineWidth',lWidth,'edgecolor',myColorOCC,'lineStyle','--');
    end
end

%F = im2frame(zbuffer_cdata(gcf));
%modifiedImage=imresize(F.cdata,[size(img,1),size(img,2)]);

%close (myFig)
%pause()

