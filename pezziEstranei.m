function [pezzi] = pezziEstranei(frame_campioni, MaxIndex, frame_estranei_secondi, fs_audio, segnaleVideo, segnaleAudioTagliato, pezzi)

%inizio finestra: frame_estranei_secondi prima del blocco problematico
in = frame_campioni * (MaxIndex-2) - frame_estranei_secondi * fs_audio;

%fine finestra: frame_estranei_secondi dopo il blocco problematico
out = frame_campioni * (MaxIndex-1);
n_frame = floor((out - in) / (frame_estranei_secondi * fs_audio));
out = in +  frame_estranei_secondi * fs_audio * (n_frame+1);

passo = frame_estranei_secondi * fs_audio;

ritardi_finestra = zeros(1, n_frame+1);
differenze_finestra = zeros(1, n_frame+1);
pos = 1;

%allineo il frame corrente
for  i=in:passo:out
        
    [CrossCorrFrame, delayFrame] = xcorr(segnaleVideo(i:i+passo),segnaleAudioTagliato(i:i+passo));
    CrossCorrFrame = CrossCorrFrame/max(CrossCorrFrame); %normalizzo la cross correlazione

    [Max, MaxIndex] = max(CrossCorrFrame); %trovo il massimo e il rispettivo indice
    campioniRitardo = delayFrame(MaxIndex);
  
        ritardi_finestra(1, pos+1) = campioniRitardo;
    differenze_finestra(1, pos+1) = ritardi_finestra(1,pos) - campioniRitardo;
    
    pos = pos + 1;
end


%Plot di tutti i ritardi causati dalla deriva e dai pezzi estranei nella finestra
figure
plot(1:length(ritardi_finestra), ritardi_finestra);
title('Deriva dei frame nel macro blocco selezionato')

 
%Plot delle differenze nei ritardi successivi tra frame per trovare i pezzi estranei nella finestra
figure
plot(1:length(differenze_finestra), differenze_finestra);
title('Differenza di ritardi tra frame successivi: probabili pezzi estranei')

[MaxF, MaxIndexF] = max(differenze_finestra); % trovo il frame in cui è stato inserito il "pezzo estraneo"

Sp = size(pezzi);
pezzi(1,Sp(1,2)+1) = in + passo * (MaxIndexF - 2);  %inizio del frame con pezzo estraneo
pezzi(2,Sp(1,2)+1) = in + passo * (MaxIndexF - 1);  %fine del frame con pezzo estraneo
pezzi(3,Sp(1,2)+1) = MaxF;                          %durata presunta (in campioni) del pezzo estraneo

end