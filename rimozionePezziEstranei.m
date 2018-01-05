function [segnaleAudioTagliato, tagli] = rimozionePezziEstranei(iter, fps_video, fs_audio, segnaleVideo, segnaleAudioTagliato, pezzi, tagli, factor)

%il valore minimo di factor, per avere efficacia, deve essere 10
if (factor < 10)
    factor = 10;
end

%inizio finestra frame_estranei_secondi prima del blocco problematico
in = pezzi(1,iter);
out = pezzi(2, iter);
frame = out-in;
ext = pezzi(3, iter);

sVideo = segnaleVideo(in:out);
sAudio = segnaleAudioTagliato(in:out+ext);

cicli = floor(length(sAudio)/fs_audio*fps_video)*factor;
ritardi_frame = zeros(1, 1);
differenze_frame = zeros(1, 1);
pos = 1;
dt = 1/fs_audio;
passo = floor(fs_audio/fps_video/factor);

tagli_curr = zeros(2, cicli+1);

% figure

for i=1:passo:frame

    sAudio_curr = sAudio([1:i, i+ext:end]);
    
%     subplot(3,3,pos)
%     t = 0:dt:(length(sAudio_curr(2:end))*dt)-dt;
%     plot(t, sVideo*0.25+0.25, t,sAudio_curr(2:end)*0.75-0.25);
%     title(sprintf('audio tentativo %d, da %f a %f', pos, i/fs_audio, (i+ext)/fs_audio))


    [CrossCorrFrame_curr, delayFrame_curr] = xcorr(sVideo(1:end),sAudio_curr(2:end));
    CrossCorrFrame_curr = CrossCorrFrame_curr/max(CrossCorrFrame_curr); %normalizzo la cross correlazione


    [Max_curr, MaxIndex_curr] = max(CrossCorrFrame_curr); %trovo il massimo e il rispettivo indice
    campioniRitardo = delayFrame_curr(MaxIndex_curr);
    
    %vettore differenza tra riferimento e tentativo, e somma e media
    diff = sVideo(1:end) - sAudio_curr(2:end);
    somme(1, pos) =  sum(diff);
    sommeAbs(1, pos) =  sum(abs(diff));
    medie(1, pos) =  mean(diff);
    medieAbs(1, pos) =  mean(abs(diff));
    
%     subplot(3,3,pos)
%     plot(1:length(CrossCorrFrame_curr), CrossCorrFrame_curr)
%     title(sprintf('xcorr tentativo %d, max = %f, lag = %d', pos, Max_curr, campioniRitardo))
%     
%     
%     subplot(3,3,pos)
%     plot(1:length(diff), diff)
%     title(sprintf('differenza n� %d, sum=%f, sumAbs=%f, avg=%f', pos, sum(diff), sum(abs(diff)), mean(diff)))

    
    ritardi_frame(1, pos+1) = campioniRitardo;
    differenze_frame(1, pos+1) = ritardi_frame(1,pos) - campioniRitardo;
    
    tagli_curr(1, pos+1) = i;        %campione inizio taglio
    tagli_curr(2, pos+1) = i+ext;    %campione fine taglio
    
    sprintf('Fine cross correlazione ciclo %d', pos) 
    datestr(now)
    
    pos = pos + 1;


end


%Plot di tutti i disallineamenti causati dalla deriva e dai silenzi nel
%frame
figure
subplot(2,2,1)
plot(1:length(somme), somme)
title('somme su vettore diff, tentativo per tentativo')
subplot(2,2,2)
plot(1:length(sommeAbs), sommeAbs)
title('somme su vettore abs(diff), tentativo per tentativo')
subplot(2,2,3)
plot(1:length(medie), medie)
title('media su vettore diff, tentativo per tentativo')
subplot(2,2,4)
plot(1:length(medieAbs), medieAbs)
title('media su vettore abs(diff), tentativo per tentativo')

[MaxS,IndexS] = max(abs(sommeAbs));
taglio_in = tagli_curr(1, IndexS);
taglio_out = tagli_curr(2, IndexS);

tagli(1, iter) = taglio_in;
tagli(2, iter) = taglio_out;

segnaleAudioTagliato = segnaleAudioTagliato([1:in+taglio_in, in+taglio_out:end]);

end


