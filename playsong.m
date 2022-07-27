function PlaySong(melody,durations)
notes = {'A' 'B' 'C' 'D' 'E' 'F' 'G'}; %notes which will be used
a = [];
freq = [440.00 493.88 261.60 293.66 329.63 349.23 391.99];
for k = 1:numel(melody); %for loop which will create the melody
note = 0:0.00025:durations(k); %note duration (which can be edited for length)
a = [a sin(2*pi*freq(strcmp(notes,melody{k}))*note)]; %a will create the melody given variables defined above
end
    sound(a);
    
end