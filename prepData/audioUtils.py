import scipy.io.wavfile
import sys
import numpy as np
import librosa
import csv
import scipy.signal

def trim(sig, fs, startTime=None, endTime=None, verbose=False):
    """
    Trim the beinning and endding of the audio

    Parameters:
        sig - np.ndarray
        fs - frame rate e.g. 22050 Hz
        startTime - e.g. (0,24) # (minute, second)
        endTime   - e.g. (4,16) # (minute, second)
    """
    if(startTime is None):  startTimeIdx = 0
    else:                   startTimeIdx = round((startTime[0] * 60 + startTime[1]) * fs)

    if(endTime is None):    endTimeIdx = None
    else:                   endTimeIdx = round((endTime[0] * 60 + endTime[1]) * fs)

    if(verbose):
        print("signal shape = {:} frame rate = {:}".format(sig.shape, fs), file=sys.stderr)
        print("startTimeIdx = {:} endTimeIdx = {:}".format(startTimeIdx, endTimeIdx), file=sys.stderr)

    return sig[startTimeIdx:endTimeIdx], fs


def generateChunks(sig, fs, chunkLengthSec, verbose=False):
    """
    Trim the beinning and endding of the audio

    Parameters:
        sig - np.ndarray
        fs - frame rate e.g. 22050 Hz
        chunkLengthSec - the length of chunk in seconds
    """
    chunkLengthSize = int(chunkLengthSec * fs)

    chunkIdx = 0
    currentEnding = 0
    output = []
    while currentEnding + chunkLengthSize < sig.shape[0]:
        output.append(sig[currentEnding:currentEnding + chunkLengthSize])
        if(verbose): print("[{:3d}] idx = [{:7d},{:7d})".format(chunkIdx, currentEnding, currentEnding + chunkLengthSize), file=sys.stderr)
        chunkIdx += 1
        currentEnding += chunkLengthSize

    if(verbose): print("[{:3d}] idx = [{:7d},{:7d})".format(chunkIdx, currentEnding, sig.shape[0]), file=sys.stderr)
    output.append(sig[currentEnding: sig.shape[0]])
    return output

def combine(leftChannel, rightChannel, fs):
    """
    Combine two single-channel audio signals into one double-channel audio signal.
    """
    leftChannel = leftChannel.reshape(-1,1)
    rightChannel = rightChannel.reshape(-1,1)
    stereo = np.concatenate((leftChannel, rightChannel), axis=1)
    return stereo, fs

def generateStereoRefTrack(concertTrack, albumTrack, fs, segmentLength=2, silenceLength=0.25, verbose=False):
    leftChannel = np.array([])
    rightChannel = np.array([])

    concertTrackLength = concertTrack.shape[0]
    albumTrackLength = albumTrack.shape[0]
    if(verbose): print("lenconcert = {:} lenalbum = {:}".format(concertTrackLength, albumTrackLength))
    minLength = min(concertTrackLength, albumTrackLength)

    # Make sure they are the same length
    concertTrack = concertTrack[:minLength]
    albumTrack = albumTrack[:minLength]

    currentIndex = 0
    while currentIndex + int(fs * segmentLength) < minLength:
        segmentEndIndex = currentIndex + int(fs * segmentLength)

        # Add left channel
        currentSegmentLeft = concertTrack[currentIndex:segmentEndIndex]
        leftChannel = np.concatenate((leftChannel, currentSegmentLeft))

        # Add right channel
        cutoffIndex = currentIndex + int(fs * (segmentLength - silenceLength))
        albumSegment = albumTrack[currentIndex:cutoffIndex]
        remaining = np.zeros(segmentEndIndex - cutoffIndex)
        rightChannel = np.concatenate((rightChannel, albumSegment, remaining))

        currentIndex = segmentEndIndex
        if(verbose): print("left = {:} right = {:}".format(leftChannel.shape, rightChannel.shape))

    assert(leftChannel.shape[0] == rightChannel.shape[0])

    return combine(leftChannel, rightChannel, fs)

def loadFile(filename, audioReader=librosa.load):
    if audioReader == librosa.load:
        sig, fs = audioReader(filename)
        return sig, fs
    else:
        fs, sig = audioReader(filename)
        return sig, fs


def writeFile(sig, fs, filename):
    """
        sig - is a numpy array of shape (np.ndarray, number of channel) if there are more than one channel
                or (np.ndarray, ) if there is only one channel
        fs - frame rate (integer)
        filename - file name (string)
    """
    scipy.io.wavfile.write(filename, fs, sig)
    return


def getChroma(sig, fs, hop_size=512, n_chroma=12):
    return librosa.feature.chroma_cqt(y=sig, sr=fs, hop_length=hop_size, n_chroma=n_chroma, norm=2)

def getMFCCdelta2(sig, fs, n_mfcc=20):
    mfcc = librosa.feature.mfcc(y=sig, sr=fs, n_mfcc=n_mfcc)
    mfcc_delta_delta = librosa.feature.delta(mfcc, order=2)
    return mfcc_delta_delta

def getDTWpath(concertTrack, albumTrack, fs, chunkLength=6.0, hop_size=512, metric='cosine', verbose=False, feature="mfcc", full_DTW=False):
    """
    Get subsequence DTW path.

    Parameters:
    concertTrack - (np.ndarray) specifying the sequence of concert track
    albumTrack   - (np.ndarray) specifying the sequence of album track
    fs           - (int) sampling rate
    chunkLength  - (float) length in seconds between consecutive chunks of the concert track
                        to be processed
    hop_size     - (int) used to generate chroma features
    metric       - (string) used to specifiy the distance function for computing DTW
                         recommended: mahalanobis distance
    feature      - (string) mfcc, chroma

    Outputs:
    DTW_path            - [(x,y)] which is an optimal path of subsequence DTW where
                                x is the index of the concert track in chroma feature matrix
                                y is the index of the album track in chroma feature matrix
    offsetChunks        - [float] which is an offset of the starting of each chunk with respect to
                                the starting of the album track. Units are the indices of chroma features matrix.
                                Note: can be converted to seconds by using this formula:
                                        second = offset * hop_size / fs
    concertTrackChromas - [np.ndarray() of shape (12,k)] which is an array of the extracted chroma features
                                for each chunk of concert track
    albumTrackChroma    - np.ndarray() of shape (12,k) which is the extracted chroma feature for the album track
    """
    concertChunks = generateChunks(concertTrack, fs, chunkLength)

    if feature == "chroma":
        X_2 = getChroma(albumTrack, fs)
    elif feature == "mfcc":
        X_2 = getMFCCdelta2(albumTrack, fs)
    else:
        raise ValueError("feature can only be 'chroma' or 'mfcc'")

    if not full_DTW:
        prefix = 0
        DTW_path = []
        offsetChunks = []

        albumTrackFeature = X_2
        concertTrackFeatures = []
        for i in range(len(concertChunks)):
            if feature == "chroma":
                X_1 = getChroma(concertChunks[i], fs)
            elif feature == "mfcc":
                X_1 = getMFCCdelta2(concertChunks[i], fs)

            concertTrackFeatures.append(X_1)

            X_1 += np.finfo(np.float32).eps
            X_2 += np.finfo(np.float32).eps

            # Y = long sequence
            # X = relatively short sequence
            D, wp = librosa.core.dtw(X=X_1, Y=X_2, metric=metric, \
                                    step_sizes_sigma=np.array([[1,1],[1,2],[2,1]]),\
                                    weights_add=np.array([1,1,2]),\
                                    weights_mul=np.array([1,1,1]),\
                                    subseq=True)

            for (concertChunkPath, albumTrackPath) in wp[::-1,:]:
                newPoint = (concertChunkPath + prefix, albumTrackPath)
                DTW_path.append(newPoint)

            offsetChunks.append(prefix)
            if(verbose): print("Chunk {:} offset = {:}[{:}]".format(i, wp[-1][1] * hop_size / fs, prefix))

            prefix += X_1.shape[1]
        return DTW_path, offsetChunks, concertTrackFeatures, albumTrackFeature

    else: 
        if feature == "chroma":
            X_1 = getChroma(concertTrack, fs)
        elif feature == "mfcc":
            X_1 = getMFCCdelta2(concertTrack, fs)

        DTW_path = []

        albumTrackFeature = X_2
        concertTrackFeature = X_1

        # Y = long sequence
        # X = relatively short sequence
        D, wp = librosa.core.dtw(X=X_1, Y=X_2, metric=metric, \
                                step_sizes_sigma=np.array([[1,1],[1,2],[2,1]]),\
                                weights_add=np.array([1,1,2]),\
                                weights_mul=np.array([1,1,1]),\
                                subseq=True)

        for (concertChunkPath, albumTrackPath) in wp[::-1,:]:
            newPoint = (concertChunkPath, albumTrackPath)
            DTW_path.append(newPoint)

        return DTW_path, [0], concertTrackFeature, albumTrackFeature

def outputDTWPathCSV(DTW_path, outputFile):
    with open(outputFile, 'w') as csvfile:
        writer = csv.writer(csvfile, delimiter=',')
        writer.writerow(["concert","album"])
        for (coord1, coord2) in DTW_path:
            writer.writerow([coord1, coord2])


import bisect
def getAlignedAlbumTrack(DTW_path, offsets, albumTrack, fs, hop_size=512, chunkLength=6.0, verbose=False, full_DTW=False):
    if not full_DTW:
        output = np.array([])
        framePerSeconds = fs//hop_size
        for idx in range(len(offsets)):
            currentTime = chunkLength * idx
            mark1 = (int(framePerSeconds * currentTime + idx), np.inf)
            mark2 = (int(framePerSeconds * (currentTime + chunkLength / 3) + idx), np.inf)
            mark3 = (int(framePerSeconds * (currentTime + chunkLength * 2 / 3) + idx), np.inf)

            time1 = DTW_path[bisect.bisect_left(DTW_path, mark1)-1][1] * hop_size / fs
            time2 = DTW_path[bisect.bisect_left(DTW_path, mark2)-1][1] * hop_size / fs
            time3 = DTW_path[bisect.bisect_left(DTW_path, mark3)-1][1] * hop_size / fs

            index1 = int(time1 * fs)
            index2 = int(time2 * fs)
            index3 = int(time3 * fs)

            target1 = index1 + int(fs * chunkLength / 3)
            target2 = index2 + int(fs * chunkLength / 3)
            target3 = index3 + int(fs * chunkLength / 3)
            if(verbose): print("index = {:} target = {:} {:}".format(index1, target1, (target1-index1)/fs))
            if(verbose): print("index = {:} target = {:} {:}".format(index2, target2, (target2-index2)/fs))
            if(verbose): print("index = {:} target = {:} {:}".format(index3, target3, (target3-index3)/fs))
            output = np.concatenate((output, albumTrack[index1:target1]))
            output = np.concatenate((output, albumTrack[index2:target2]))
            output = np.concatenate((output, albumTrack[index3:target3]))
        return output, fs
    else:
        output = np.array([])
        framePerSeconds = fs // hop_size
        
        # DTW_path is a list of pair of DTW path in the form of (x,y)
        # where x = coordinate for concertTrack
        #       y = coordinate for albumTrack

        currentChunkNo = 0
        currentFrame = 0
        while True:
            # Find the ending of the 6-sec queryChunk in the DTW path array 
            marker = (int((currentChunkNo + 1) * chunkLength * fs / hop_size), np.inf)

            # Obtain the frame index for the albumTrack
            targetFrame = DTW_path[bisect.bisect_left(DTW_path, marker)-1][1]

            start = int(currentFrame * hop_size)
            end   = int(targetFrame * hop_size)
            if(start > end): break 


            resampled = scipy.signal.resample(albumTrack[start:end], int(chunkLength * fs)) 
            if(verbose): print("start = {:} end = {:} length = {:} newLength = {:}".format(start, end, end-start, len(resampled)))

            output = np.concatenate((output, resampled))

            currentFrame = targetFrame + 1
            currentChunkNo += 1

        return output, fs


