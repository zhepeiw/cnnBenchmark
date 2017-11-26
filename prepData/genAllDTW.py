import glob
import sys
import librosa
import audioUtils
import numpy as np

BASE_DIRECTORY_REFTONAME = './ourquery_lists'
BASE_DIRECTORY_QUERYAUDIO = '/home/zhwang/data/Paired/prepped'
BASE_DIRECTORY_REFAUDIO = '/home/nbanerjee/Prep_Dataset/References' 

OUTPUT_PREFIX = "./output-DTW/DTW_aligned"

# artists = ['bigkrit', 'chromeo', 'deathcabforcutie', 'foofighters', 'kanyewest', 'maroon5', 'onedirection', 't.i', 'taylorswift', 'tompetty']
artists = ['kanyewest', 'maroon5', 'onedirection', 't.i', 'taylorswift', 'tompetty']

for artist in artists:
    # Get query to ref file
    queryToRefFiles = glob.glob(BASE_DIRECTORY_REFTONAME + "/{:}_ourquerytoref.list".format(artist))
    try:
        assert len(queryToRefFiles) == 1
    except AssertionError:
        print("Warning: Can't find the query to ref file for {:}".format(artist), file=sys.stderr)
        continue
    queryToRefFile = queryToRefFiles[0]
    print("queryToRefFile = {:}".format(queryToRefFile), file=sys.stderr)

    # get all query audio file list
    audioList = glob.glob(BASE_DIRECTORY_QUERYAUDIO + "/{:}/*".format(artist))
    print("audioList = {:}".format(audioList), file=sys.stderr)

    # Preprocess list of ref files
    refFiles = glob.glob(BASE_DIRECTORY_REFTONAME + "/{:}_reftoname.txt".format(artist))
    try:
        assert len(refFiles) == 1
    except AssertionError:
        print("Warning: Can't find the ref to name file for {:}".format(artist), file=sys.stderr)
        continue
    refFileName = refFiles[0]
    print("RefFileName for {:} is {:}".format(artist, refFileName), file=sys.stderr)

    queryIdxToFullName = {}
    print("Preprocess RefFile for {:}".format(artist), file=sys.stderr)
    with open(refFileName, 'r') as refFile:
        for line in refFile:
            line = line.strip().split('_')
            idx = int(line[0])
            refFileName = "_".join(line[1:])
            queryIdxToFullName[idx] = refFileName
            print("\tIndex = {:2d} corresponds to [{:}]".format(idx, refFileName), file=sys.stderr)

    print("End preprocessing RefFile for {:}".format(artist), file=sys.stderr)
    # End preprocessing list of ref files
    

    # Process each query
    with open(queryToRefFile, 'r') as queryFile:
        for line in queryFile:
            line = line.strip().split(' ')
            if(len(line) == 1):
                print("Warning: Query {:} cannot find a match".format(line[0]), file=sys.stderr)
                continue
            
            print("Performing a DTW on Query {:}-{:}".format(artist,line[0]), file=sys.stderr)

            # Get query file 
            queryFileName = BASE_DIRECTORY_QUERYAUDIO + '/{:}/{:}_ourquery{:}.wav'.format(artist,artist,line[0])
            try:
                assert len(glob.glob(queryFileName)) == 1
            except AssertionError:
                print("\tQuery {:} doesn't exist".format(queryFileName), file=sys.stderr)
                continue

            print("\tqueryFileName = {:}".format(queryFileName), file=sys.stderr)
            
            # Get corresponding ref file
            refFileName = BASE_DIRECTORY_REFAUDIO + "/*/{:}".format(queryIdxToFullName[int(line[1])])
            try:
                assert len(glob.glob(refFileName)) == 1
                refFileName = glob.glob(refFileName)[0]
            except AssertionError:
                print("\tReference {:} for query {:} doesn't exist".format(line[1], line[0]), file=sys.stderr)
            print("\trefFileName = {:}".format(refFileName), file=sys.stderr)


            # Perform DTW
            queryTrack, fs = audioUtils.loadFile(queryFileName, audioReader=librosa.load)
            refTrack, fs2 = audioUtils.loadFile(refFileName, audioReader=librosa.load)
            queryTrack += np.finfo(np.float32).eps   # To prevent all-0 vector
            refTrack += np.finfo(np.float32).eps     # To prevent all 0 vector 
            path, offsets, _, _ = audioUtils.getDTWpath(queryTrack, refTrack, fs, metric='cosine')
            alignedRefTrack, _ = audioUtils.getAlignedAlbumTrack(path, offsets, refTrack, fs)
            stereo, fs = audioUtils.generateStereoRefTrack(queryTrack, alignedRefTrack, fs)
            audioUtils.writeFile(stereo, fs, OUTPUT_PREFIX + "-{:}-query{:}-cosine.wav".format(artist, line[0]))
    
