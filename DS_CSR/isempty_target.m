function [ is_occ ] = isempty_target( rect )
%ISEMPTY_TARGET Summary of this function goes here
%   Detailed explanation goes here


if   rect([1:4]) ==[0,0,0,0]
    is_occ = 1;
else
    is_occ =0;
end


end

