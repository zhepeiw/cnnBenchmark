function [score,offset,optshift] = subseqLinearMatch(Q,Rmult)
% [score,offset] = subseqLinearMatch(Q,Rmult)
%
%  This function performs subsequence linear match between the specified query
%  fingerprint sequence and multiple pitch-shifted reference fingerprint sequences.
%
%  score: optimal subsequence linear match score
%  offset: offset (in hops) of beginning of matching segment
%  optshift: optimal pitch shift
%
%  2016-07-08 TJ Tsai ttsai@g.hmc.edu

nbits = size(Q,1);
N = size(Q,2);
M = size(Rmult,2);
numPitchShifts = size(Rmult,3);

% matchScores: rows correspond to different pitch shifts,
% columns correspond to different frame offsets
numFrameShifts = M - N + 1;
Qblock = repmat(Q,1,1,numPitchShifts);
costMatrix = zeros(numPitchShifts,numFrameShifts);
for i=1:numFrameShifts
    Rblock = Rmult(:,i:(i+N-1),:);
    XORblock = xor(Qblock,Rblock);
    curScores = sum(sum(XORblock,1),2);
    costMatrix(:,i) = curScores(:);
end

[minCosts,minIdxs] = min(costMatrix,[],2);
[bestCost,optshiftIdx] = min(minCosts);
offset = minIdxs(optshiftIdx) - 1;
if optshiftIdx <= (numPitchShifts+1)/2,
    optshift = optshiftIdx - 1;
else
    optshift = -1*optshiftIdx + (numPitchShifts+1)/2;
end
score = 1 - (bestCost/(nbits*N)); % match score (as opposed to a cost measure)
