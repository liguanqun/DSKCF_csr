

function imgOUT=roiFromBB(imgIN,bbIn)

imgOUT=imgIN(bbIn(2):bbIn(4),bbIn(1):bbIn(3),:);
end