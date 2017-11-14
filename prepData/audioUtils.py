import scipy.io.wavfile
import sys
import numpy as np
from scipy.spatial.distance import hamming

def trim(sig, fs, startTime, endTime, verbose=False):
    """
    Trim the beinning and endding of the audio

    Parameters:
        sig - np.ndarray
        fs - frame rate e.g. 22050 Hz
        startTime - e.g. (0,24) # (minute, second)
        endTime   - e.g. (4,16) # (minute, second)
    """

    startTimeIdx = round((startTime[0] * 60 + startTime[1]) * fs)
    endTimeIdx   = round((endTime[0] * 60 + endTime[1]) * fs)

    if(verbose):
        print("signal shape = {:} frame rate = {:}".format(sig.shape, fs), file=sys.stderr)
        print("startTimeIdx = {:} endTimeIdx = {:}".format(startTimeIdx, endTimeIdx), file=sys.stderr)

    return fs, sig[startTimeIdx:endTimeIdx]


def generateChunks(sig, fs, chunkLengthSec, verbose=False):
    """
    Trim the beinning and endding of the audio

    Parameters:
        sig - np.ndarray
        fs - frame rate e.g. 22050 Hz
        chunkLengthSec - the length of chunk in seconds
    """
    chunkLengthSize = round(chunkLengthSec * fs)

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
    return fs, output

def combine(leftChannel, rightChannel, fs):
    """
    Combine two single-channel audio signals into one double-channel audio signal.
    """
    leftChannel = leftChannel.reshape(-1,1)
    rightChannel = rightChannel.reshape(-1,1)
    stereo = np.concatenate((leftChannel, rightChannel), axis=1)
    return fs, stereo

def writeFile(sig, fs, filename):
    """
        sig - is a numpy array of shape (np.ndarray, number of channel) if there are more than one channel
                or (np.ndarray, ) if there is only one channel
        fs - frame rate (integer)
        filename - file name (string)
    """
    scipy.io.wavfile.write(filename, fs, sig)
    return