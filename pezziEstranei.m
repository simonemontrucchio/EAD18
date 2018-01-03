function [segnaleAudioSenzaPezziEstranei, pezzi] = pezziEstranei(frame_campioni, MaxIndex, frame_silenzi_secondi, fs_audio, segnaleVideo, segnaleAudioTagliato, segnaleAudioSenzaPezziEstranei, pezzi)

%inizio finestra frame_silenzi_secondi prima del blocco problematico
in = frame_campioni * (MaxIndex-2) - frame_silenzi_secondi * fs_audio;

%fine finestra frame_silenzi_secondi dopo il blocco problematico
out = frame_campioni * (MaxIndex-1);
n_frame = floor((out - in) / (frame_silenzi_secondi * fs_audio));
out = in +  frame_silenzi_secondi * fs_audio * (n_frame+1);

passo = frame_silenzi_secondi * fs_audio;

ritardi_finestra = zeros(1, n_frame+1);
differenze_finestra = zeros(1, n_frame+1);
pos = 1;

%allineo il frame corrente
for  i=in:passo:out
    %i      %conta lo scorrere dei frame
    
    [CrossCorrFrame, delayFrame] = xcorr(segnaleVideo(i:i+passo),segnaleAudioTagliato(i:i+passo));
    CrossCorrFrame = CrossCorrFrame/max(CrossCorrFrame); %normalizzo la cross correlazione

    [Max, MaxIndex] = max(CrossCorrFrame); %trovo il massimo e il rispettivo indice
    campioniRitardo = delayFrame(MaxIndex);
    
    ritardi_finestra(1, pos+1) = campioniRitardo;
    differenze_finestra(1, pos+1) = ritardi_finestra(1,pos) - campioniRitardo;
    
    %allineo il frame corrente
    if (campioniRitardo>=0)
        segnaleAudioSenzaPezziEstranei(i:i+passo) = segnaleAudioTagliato(i+campioniRitardo:i+passo+campioniRitardo);
    end
    if (campioniRitardo<0)
        segnaleAudioSenzaPezziEstranei(i:i+passo) = segnaleAudioTagliato(i-campioniRitardo:i+passo-campioniRitardo);
    end 
    
    pos = pos + 1;
end


% %Plot di tutti i disallineamenti causati dalla deriva e dai silenzi nella
% %finestra
% figure
% plot(1:length(ritardi_finestra), ritardi_finestra);
% title('Deriva finestra')
%  
% % %Plot delle differenze nei disallineamenti successivi  per trovare i pezzi estraneinella
% %finestra
% figure
% plot(1:length(differenze_finestra), differenze_finestra);
% title('Frame con pezzi estranei finestra')

[MaxF, MaxIndexF] = max(differenze_finestra); % trovo il frame in cui è stato inserito il "pezzo estraneo"

pezzi(1,length(pezzi)) = in + passo * (MaxIndexF - 3);
pezzi(2,length(pezzi))  = in + passo * (MaxIndexF - 2);

end