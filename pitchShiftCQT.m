function B = pitchShiftCQT(A,shiftBins)
% function B = pitchShiftCQT(A,shift)
%
%   Given CQT data struct A, returns a pitch-shifted version.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu
B = A;
B.c = circshift(A.c,shiftBins);
if shiftBins > 0
    B.c(1:shiftBins,:) = 0;
elseif shiftBins < 0
    B.c((end+shiftBins+1):end,:) = 0;
end
