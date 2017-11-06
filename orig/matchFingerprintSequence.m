function R = matchFingerprintSequence(Q,DB);
% R = matchQuery(Q,DB)
%     Matches a given query fingerprint sequence against a database of 
%     fingerprint sequences.
%
%     Rows of R are of the format:
%      songID  matchScore offset pitchShiftInfo
%
%     offset indicates the offset between the query and reference (in sec)
%     pitchShiftInfo specifies the best relative pitch shift
%     Rows are sorted in decreasing order of matchScore.
%
% 2016-07-08 TJ Tsai ttsai@g.hmc.edu

% Subsequence linear match
R = zeros(length(DB),4);
for i=1:length(DB)
    [score,offset,pitchshift] = subseqLinearMatch(Q,DB{i});
    R(i,:) = [i score offset pitchshift];
end
[vv,xx] = sort(R(:,2),'descend');
R = R(xx,:);
