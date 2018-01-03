clear all; close all;

%% 0. APERTURA DEI FILE AUDIO

[segnaleAudio, fs_audio] =audioread('audioWav.wav');  % apertura file audio ESTERNO
%sprintf('fs segnale audio ESTERNO: %d', fs_audio)
sAudio_length = length(segnaleAudio);      % da il numero di campioni
%sprintf('Lunghezza segnale audio ESTERNO: %d', sAudio_length)

[segnaleVideo, fs_video] = audioread('video.wav');    % apertura file audio INTERNO
%sprintf('fs segnale audio INTERNO: %d', fs_video)
sVideo_length = length(segnaleVideo);      % da il numero di campioni
%sprintf('Lunghezza segnale audio INTERNO: %d', sVideo_length)

%eventuale pareggiamento frequenze dei due segnali
if (fs_video ~= fs_audio)
    [p,q] = rat(fs_audio / fs_video);
    segnaleVideo = resample(segnaleVideo, p, q);
    sprintf('Attenzione: il segnale video era a frequenza %d Hz ed è stato portato alla stessa frequenza del segnale audio (%d Hz).', fs_video, fs_audio)
    fs_video = fs_audio;
    sVideo_length = length(segnaleVideo);
end


%% 1. TUNING PARAMETRI

blocco_minimo_secondi = 10;     %durata in secondi del blocco per la cross corelazione generica
frame_silenzi_secondi = 5;      %durata in secondi del blocco per la cross corelazione di rimozione dei silenzi
ratio = 50;                     %rapporto tra la durata del file di partenza e la durata della finestra di correlazione. es: 50:1


%cross correlazione iniziale su numero di campioni pari alla differenza di
%durata dei segnali o almeno blocco_minimo_secondi
campioni_per_correlazione = abs(sVideo_length - sAudio_length); 
if (campioni_per_correlazione < blocco_minimo_secondi * fs_audio)
    campioni_per_correlazione = blocco_minimo_secondi * fs_audio;
end

%cross correlazione di tutto il segnale su blocchi di durata pari a 1/ratio
%o almeno blocco_minimo_secondi
frame_allineamento_secondi = round(sVideo_length / fs_video / ratio);
if (frame_allineamento_secondi < blocco_minimo_secondi)
    frame_allineamento_secondi = blocco_minimo_secondi;
end


%% 2. CROSS CORRELAZIONE PER ALLINEAMENTO INIZIALE

inizio = 1;
fine = campioni_per_correlazione;
[CrossCorr, delay] = xcorr(segnaleVideo(inizio:fine),segnaleAudio(inizio:fine));
CrossCorr = CrossCorr/max(CrossCorr); %normalizzo la cross correlazione

[Max, MaxIndex] = max(CrossCorr); %trovo il massimo e il rispettivo indice
campioniRitardo = delay(MaxIndex);

%Plot the cross-correlation. Display the location of the maximum.
figure
plot(delay,CrossCorr,[campioniRitardo campioniRitardo],[-0.5 1],'r:')
text(campioniRitardo+100,0.5,['Lag: ' int2str(campioniRitardo)])
ylabel('CrossCorr')
axis tight
title('Cross-Corrlengthelation')

%audio senza ritardo
if (campioniRitardo>=0)
        segnaleAudioTagliato = segnaleAudio(campioniRitardo:end);
end
if (campioniRitardo<0)
        segnaleAudioTagliato = segnaleAudio(-campioniRitardo:end);
end 
sAudioTagliato_length=length(segnaleAudioTagliato); 
campioniRitardoIniziale = campioniRitardo;



%% 3. ALLINEAMENTO BLOCCO PER BLOCCO CONTRO DERIVA

frame_campioni = frame_allineamento_secondi*fs_audio;
n_blocchi = floor(sVideo_length / frame_campioni);
%n_frame
ritardi = zeros(1, n_blocchi+1);
differenze = zeros(1, n_blocchi+1);
inizio = 1;
fine = frame_campioni;
for  i=1:1:n_blocchi-1
    %i      %conta lo scorrere dei blocchi
    
    [CrossCorrFrame, delayFrame] = xcorr(segnaleVideo(inizio:fine),segnaleAudioTagliato(inizio:fine));
    CrossCorrFrame = CrossCorrFrame/max(CrossCorrFrame); %normalizzo la cross correlazione

    [Max, MaxIndex] = max(CrossCorrFrame); %trovo il massimo e il rispettivo indice
    campioniRitardo = delayFrame(MaxIndex);
    ritardi(1, i+1) = campioniRitardo;
    differenze(1, i+1) = ritardi(1,i) - campioniRitardo;
    
    %allineo il frame corrente
    if (campioniRitardo>=0)
        segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio+campioniRitardo:fine+campioniRitardo);
    end
    if (campioniRitardo<0)
            segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio-campioniRitardo:fine-campioniRitardo);
    end 

    
    %aggiorno gli estremi per il frame successivo
    inizio = inizio + frame_campioni;
    fine = fine + frame_campioni;

end

inizio = 1 + frame_campioni * (n_blocchi-1);
fine = sVideo_length;
%parte finale del file
[CrossCorrFrame, delayFrame] = xcorr(segnaleVideo(inizio:fine),segnaleAudioTagliato(inizio:fine));
CrossCorrFrame = CrossCorrFrame/max(CrossCorrFrame); %normalizzo la cross correlazione

[Max, MaxIndex] = max(CrossCorrFrame); %trovo il massimo e il rispettivo indice
campioniRitardo = delayFrame(MaxIndex);
ritardi(1, n_blocchi+1) = campioniRitardo;
differenze(1, n_blocchi+1) = ritardi(1,n_blocchi) - campioniRitardo;

%allineo il frame corrente
if (campioniRitardo>=0)
    segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio+campioniRitardo:fine+campioniRitardo);
end
if (campioniRitardo<0)
        segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio-campioniRitardo:fine-campioniRitardo);
end 
    
%Plot di tutti i disallineamenti causati dalla deriva e dai silenzi
figure
plot(1:length(ritardi), ritardi);
title('Deriva')
 
[Max, MaxIndex] = max(differenze); % trovo il blocco in cui è stato inserito il "pezzo estraneo"
%Plot delle differenze nei disallineamenti successivi  per trovare i pezzi estranei
figure
plot(1:length(differenze), differenze);
title('Blocchi con pezzi estranei')
%sprintf('Il pezzo estraneo si trova tra il secondo %d e il secondo %d, nel blocco %d', (MaxIndex-2)*frame_campioni/fs_audio, (MaxIndex-1)*frame_campioni/fs_audio, MaxIndex-1)

sAudioSenzaDeriva_length = length(segnaleAudioSenzaDeriva);


%% 4. ALLINEAMENTO CORRETTO BLOCCHI CON PEZZO ESTRANEO

segnaleAudioSenzaPezziEstranei = segnaleAudioSenzaDeriva;
pezzi = zeros(2,1);

[MaxD, MaxIndexD] = max(differenze);
soglia = MaxD / 10;

for i=1:1:length(differenze)
    
    %se trovo un blocco con una differenza tra ritardi successivi superiore
    %alla soglia, probabilmente contiene un pezzo estraneo da correggere
    if (differenze(1, i) > soglia)
        sprintf('Il blocco %d contiene un pezzo estraneo. Viene chiamata su questo blocco la funzione per i pezzi estranei.', i)   
        [segnaleAudioSenzaPezziEstranei, pezzi] = pezziEstranei(frame_campioni, MaxIndex, frame_silenzi_secondi, fs_audio, segnaleVideo, segnaleAudioTagliato, segnaleAudioSenzaPezziEstranei, pezzi);
    end
end

sAudioSenzaPezziEstranei_length = length(segnaleAudioSenzaPezziEstranei);


%% 5. GENERAZIONE DATI OUTPUT

%info sul disallineamento iniziale
if (campioniRitardoIniziale>=0)
        sprintf('Inizialmente la seconda traccia partiva con un ritardo di %d campioni, cioè %d secondi.', campioniRitardoIniziale, round(abs(campioniRitardoIniziale)/fs_audio))
end
if (campioniRitardoIniziale<0)
        sprintf('Inizialmente la seconda traccia partiva con un anticipo di %d campioni, cioè %d secondi.', abs(campioniRitardoIniziale), round(abs(campioniRitardoIniziale)/fs_audio))
end 


%info su pezzi estranei
if (length(pezzi) > 1)
    for i=2:1:length(pezzi)
    	sprintf('Un pezzo estraneo si trovava tra il secondo %d e il secondo %d.', pezzi(1,i)/fs_audio, pezzi(2,i)/fs_audio)
    end
end


%info su deriva
[MaxDifferenze, MaxIndexDifferenze] = max(differenze);
campioniDeriva = sum(differenze);
campioniDeriva = campioniDeriva - MaxDifferenze;
sprintf('La deriva causa un ritardo totale di %d campioni, cioè circa %d millisecondi (su un file di circa %d minuti).', campioniDeriva, round(campioniDeriva/fs_audio*1000), round(sAudioSenzaDeriva_length/fs_audio/60))


%% 6. SCRITTURA FILE OUTPUT

%normalizzo guadagno del file prima di salvarlo
audio_output = segnaleAudioSenzaPezziEstranei / max(abs(segnaleAudioSenzaPezziEstranei));

audiowrite('AudioAligned.wav', audio_output, fs_audio);