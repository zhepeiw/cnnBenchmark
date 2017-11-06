filename = 'audio/taylorswift_test/taylorswift_test';
outname = 'audio/taylorswift_validation/taylorswift_val';
mkdir('audio/taylorswift_validation');
refNum = [2, 11, 13, 14, 26, 36, 43, 51, 54, 65];

for i = 1:10
    file = strcat(filename,int2str(refNum(i)),'.wav');
    [y,fs] = audioread(file);
    y = resample(y,22050,fs);
    for j = 1:10
        qnum = (i-1)*10 + j;
        queryname = strcat(outname,int2str(qnum),'.wav');
        k = j*2;
        qfile = y((k-1)*6*22050 + 1:k*6*22050);
        audiowrite(queryname,qfile,22050);
    end
end