import scipy.io.wavfile
import sys
import numpy as np
from scipy.spatial.distance import hamming
import librosa

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

def generateStereoRefTrack(concertTrack, albumTrack, fs, segmentLength=2, silenceLength=0.5):
    leftChannel = np.array([])
    rightChannel = np.array([])

    concertTrackLength = concertTrack.shape[0]
    albumTrackLength = albumTrack.shape[0]
    minLength = min(concertTrackLength, albumTrackLength)

    # Make sure they are the same length
    concertTrack = concertTrack[:minLength]
    albumTrack = albumTrack[:minLength]

    currentIndex = 0
    while currentIndex + int(fs * segmentLength) < concertTrackLength:
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

def getDTWpath(concertTrack, albumTrack, fs, chunkLength=6.0, hop_size=512, metric='mahalanobis'):
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


    X_2_chroma = librosa.feature.chroma_cqt(y=albumTrack, sr=fs,
                                            hop_length=hop_size, # number of samples between consecutive frames
                                            n_chroma=12    # number of chroma bins to produce
                                            )
    prefix = 0
    DTW_path = []
    offsetChunks = []

    albumTrackChroma = X_2_chroma
    concertTrackChromas = []
    for i in range(len(concertChunks)):
        X_1_chroma = librosa.feature.chroma_cqt(y=concertChunks[i], sr=fs,
                                                hop_length=hop_size, # number of samples between consecutive frames
                                                n_chroma=12,    # number of chroma bins to produce
                                                )
        concertTrackChromas.append(X_1_chroma)

        # X = long sequence
        # Y = relatively short sequence
        D, wp = librosa.core.dtw(X=X_1_chroma, Y=X_2_chroma, metric=metric, subseq=True)

        for (concertChunkPath, albumTrackPath) in wp[::-1,:]:
            newPoint = (concertChunkPath + prefix, albumTrackPath)
            DTW_path.append(newPoint)

        prefix += X_1_chroma.shape[1]
        offsetChunks.append(wp[-1][1] * hop_size / fs)
    return DTW_path, offsetChunks, concertTrackChromas, albumTrackChroma

def getAlginedAlbumTrack(offsets, albumTrack, fs, chunkLength=6.0):
    output = np.array([])
    for offset in offsets:
        startingIndex = int(offset * fs)
        endingIndex   = int((offset + chunkLength) * fs)
        output = np.concatenate((output, albumTrack[startingIndex:endingIndex]))
    return output, fs

def getChroma(sig, fs, hop_size=512, n_chroma=12):
    return librosa.feature.chroma_cqt(y=sig, sr=fs, hop_size=hop_size, n_chroma=n_chroma)