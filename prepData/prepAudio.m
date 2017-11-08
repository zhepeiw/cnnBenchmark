function prepAudio (artist,fileList,songList, outdir)

% prepAudio convert all songs in the fileList to be in mono channel
% and has fs = 22050 Hz. It also renames the song to be in the format
% "artist_song_(1 or 2).wav" (since one song will correspond to 2
% live recordings.)
% 
% Input:
% - artist: a string contains name of the artist
% - fileList: a .list file that contains path to all files we want to prep.
% - songList: a cell array of song name strings. The order of the song name
%             must corresponds to the order of file paths in fileList.
% - outdir: the directory where you want the prepped audio to be saved at.

fid = fopen(fileList);
curfile = fgetl(fid);
songcount = 1;
i = 1;

while ischar(curfile)
    [y,fs] = audioread(curfile);
    y = sum(y,2)./2; % mono
    y = resample(y,22050,fs);
    newFileName = strcat(outdir,'/',artist,'_',char(songList(songcount)),'_',int2str(i),'.wav');
    audiowrite(newFileName,y,22050); 
    i = i+1;
    if i == 3
        songcount = songcount + 1;
        i = 1;
    end
    curfile = fgetl(fid);
end

end