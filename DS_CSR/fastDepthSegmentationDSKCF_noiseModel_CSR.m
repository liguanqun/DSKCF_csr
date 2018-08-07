function [L,Cnew,LUT,H,I,LUTCC]=fastDepthSegmentationDSKCF_noiseModel_CSR(im,c,nanMatrix,minimumError,Cinit, findPeak,targetDepth,targetSTD,noiseModelVector)

% Default input arguments
if nargin<2 || isempty(c), c=2; end

% Basic error checking
if nargin<1 || isempty(im)
    error('Insufficient number of input arguments')
end
msg='Revise variable used to specify class centroids. See function documentaion for more info.';
if ~isnumeric(c) || ~isvector(c)
    error(msg)
end
if numel(c)==1 && (~isnumeric(c) || round(c)~=c || c<2)
    error(msg)
end

% Check image format
if isempty(strfind(class(im),'int'))
    error('Input image must be specified in integer format (e.g. uint8, int16)')
end
if sum(isnan(im(:)))~=0 || sum(isinf(im(:)))~=0
    error('Input image contains NaNs or Inf values. Remove them and try again.')
end


histStep=max(2.5*calculateNoiseVar(targetDepth,noiseModelVector(1),noiseModelVector(2),noiseModelVector(3)),targetSTD);

newPointSet=im(~nanMatrix);
Imin=double(min(newPointSet));
Imax=double(max(newPointSet));
I=(Imin:histStep:Imax)';
if(isempty(I))
    L=[];
    Cnew=[];
    LUT=[];
    H=[];
    I=[];
    LUTCC=[];
    return
end

if(I(end)~=Imax || length(I)==1)
    I(end+1)=Imax+histStep;
end
I=I(:);
% Compute intensity histogram
H=hist(double(newPointSet),I);
H=H(:);
maxValue=max(H);

minPeakDistParam=3;
if(length(I)<50)
   minPeakDistParam=2;
end

%[peakDepth,posPeak]=findpeaks([0; H ;0],'MINPEAKDISTANCE',minPeakDistParam,'MINPEAKHEIGHT',0.005*maxValue);
[peakDepth,posPeak]=findpeaks([0; H ;0],'MINPEAKDISTANCE',minPeakDistParam,'MINPEAKHEIGHT',0.01*maxValue);
%不允许只选出一个 peak 极大值会影响 target的 方差，添加一个最远的距离作为peak
if length(posPeak) ==1 && length(I)>50
    posPeak = [posPeak length(H)];
end
% Initialize cluster centroids
if numel(c)>1
    C=c;
    c=numel(c);
else
    dI=(Imax-Imin)/c;
    if(isempty(Cinit))
        C=Imin+dI/2:dI:Imax;
    else
        C=Cinit;
    end
end

if(findPeak)
    if(length(C)==length(posPeak) && C(1)==-1);
        C=I(posPeak-1);
    elseif (length(C)~=length(posPeak))
        c=length(posPeak);
        C=I(posPeak-1);
    end
    C=C';
end



% Update cluster centroids
IH=I.*H; dC=Inf;

C0=C;
Citer=C;
while dC>minimumError
    
    Citer=C;
    
    % Distance to the centroids
    D=abs(bsxfun(@minus,I,C));
    
    % Classify by proximity
    [Dmin,LUT]=min(D,[],2); %#ok<*ASGLU>
    for j=1:c
        C(j)=sum(IH(LUT==j))/sum(H(LUT==j));
        if(isnan(C(j)))
            C(j)=Citer(j);
        end
    end
      
    % Change in centroids 
    dC=max(abs(C-Citer));
    
end

%%correct singleton peaks
if(length(C)==1)
    C=I(posPeak-1);
end

[L,Cnew,LUTCC]=LUT2labelNanSupportCC(im,LUT,nanMatrix,histStep,C);

