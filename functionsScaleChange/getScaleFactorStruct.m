function scale_struct=getScaleFactorStruct(estimatedDepthMode,scale_struct) 
% GETSCALEFACTORSTRUCT.m select the target's scale
% 
%   GETSCALEFACTORSTRUCT this functions allows to select the new scales for
%   the DS-KCF tracker's model, according to the actual depth distribution
%   of the target. For more information about scale selection please see
%   [1]
%
%   INPUT:
%  -estimatedDepthMode depth of the target 
%  -scaleDSKCF_struct scale data structure (see INITDSKCFPARAM)
%  
%  OUTPUT
%  -scaleDSKCF_struct updated scale data structure
%
%
%  See also INITDSKCFPARAM
%
%  University of Bristol 
%  Massimo Camplani and Sion Hannuna
%  
%  massimo.camplani@bristol.ac.uk 
%  hannuna@compsci.bristol.ac.uk

scale_struct.updated = 0;

mode1 = estimatedDepthMode;
scale_struct.currDepth = mode1;

sf = scale_struct.InitialDepth / mode1;

% Check for significant scale difference to current scale
scaleOffset =  sf - scale_struct.scales(scale_struct.i);
if abs(scaleOffset) > scale_struct.minStep %% Need to change scale if possible
    if scaleOffset < 0 && scale_struct.i > 1% Getting smaller + check not smallest already
        diffs = scale_struct.scales(1:scale_struct.i) - sf;
        [a ind] = min(abs(diffs));
        if ind ~= scale_struct.i
            scale_struct.iPrev = scale_struct.i;
            scale_struct.i = ind;
            scale_struct.updated = 1;
        end
    elseif  scaleOffset > 0 && scale_struct.i < length(scale_struct.scales) % Getting bigger+ check not at biggest already
        diffs = scale_struct.scales(scale_struct.i:end) - sf;
        [a ind] = min(abs(diffs));
        ind = ind + scale_struct.i - 1;
        if ind ~= scale_struct.i
            scale_struct.iPrev = scale_struct.i;
            scale_struct.i = ind;
            scale_struct.updated = 1;
        end
    end  
end


