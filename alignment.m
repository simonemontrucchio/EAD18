clear all; close all;

%% 0. APERTURA DEI FILE AUDIO

esempi = 1;     %mettere su 1 per usare i file di esempio forniti dal professore, su 2 per usare i file di esempio da noi generati

if (esempi == 1)
    [segnaleAudio, fs_audio] =audioread('audioEsterno.wav');    % apertura file audio ESTERNO
    sAudio_length = length(segnaleAudio);

    [segnaleVideo, fs_video] = audioread('audioInterno.wav');   % apertura file audio INTERNO
    sVideo_length = length(segnaleVideo);
end

if (esempi == 2)
    [segnaleAudio, fs_audio] =audioread('audioEsterno48s.wav');  % apertura file audio ESTERNO
    sAudio_length = length(segnaleAudio);

    [segnaleVideo, fs_video] = audioread('audioInterno44.wav');  % apertura file audio INTERNO
    sVideo_length = length(segnaleVideo);
end


%eventuale pareggiamento frequenze dei due segnali con ricampionamento
if (fs_video ~= fs_audio)
    [p,q] = rat(fs_audio / fs_video);
    segnaleVideo = resample(segnaleVideo, p, q);
    sprintf('Attenzione: il segnale audio interno era a frequenza %d Hz ed è stato portato alla stessa frequenza del segnale audio esterno (%d Hz).', fs_video, fs_audio)
    fs_video = fs_audio;
    sVideo_length = length(segnaleVideo);
end


%% 1. TUNING PARAMETRI

blocco_minimo_secondi = 10;     %durata in secondi del blocco per la cross corelazione generale
ratio = 50;                     %rapporto tra la durata del file di partenza e la durata della finestra di correlazione generale. es: 50:1
frame_estranei_secondi = 5;     %durata in secondi del blocco per la cross corelazione per la rimozione dei silenzi


%eventuale rimozione fine di pezzi estranei
flag = true;                    %viene fatta solo se il flag è true, altrimenti si basa solo su cross correlazione
fps_video = 25;                 %frame al secondo (del video in cui si vuole inserire l'audio)
factor = 10;                    %scendo sotto a 10 o aumentando molto (magari fino a 100) aumenta l'imprecisione

%cross correlazione iniziale su numero di campioni pari alla differenza di durata dei segnali o almeno blocco_minimo_secondi
campioni_per_correlazione = abs(sVideo_length - sAudio_length); 
if (campioni_per_correlazione < blocco_minimo_secondi * fs_audio)
    campioni_per_correlazione = blocco_minimo_secondi * fs_audio;
end

%cross correlazione di tutto il segnale su blocchi di durata pari a 1/ratio o almeno blocco_minimo_secondi
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

%Plot cross-correlazione. Mostra la posizione del massimo.
figure
plot(delay,CrossCorr,[campioniRitardo campioniRitardo],[-0.5 1],'r:')
text(campioniRitardo+100,0.5,['Campioni di ritardo: ' int2str(campioniRitardo)])
ylabel('CrossCorr')
axis tight
title('Cross-Correlazione per allineamento iniziale')

%allineamento audio INTERNO
if (campioniRitardo>=0)
        segnaleAudioTagliato = segnaleAudio(campioniRitardo:end);
end
if (campioniRitardo<0)
        segnaleAudioTagliato = segnaleAudio(-campioniRitardo:end);
end 

campioniRitardoIniziale = campioniRitardo;


%% 3. ALLINEAMENTO BLOCCO PER BLOCCO CONTRO DERIVA

frame_campioni = frame_allineamento_secondi*fs_audio;
n_blocchi = floor(sVideo_length / frame_campioni);
ritardi = zeros(1, n_blocchi+1);
differenze = zeros(1, n_blocchi+1);
inizio = 1;
fine = frame_campioni;
for  i=1:1:n_blocchi-1
        
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

%parte finale del segnale audio, non compreso nel ciclo
inizio = 1 + frame_campioni * (n_blocchi-1);
fine = sVideo_length;

[CrossCorrFrame, delayFrame] = xcorr(segnaleVideo(inizio:fine),segnaleAudioTagliato(inizio:fine));
CrossCorrFrame = CrossCorrFrame/max(CrossCorrFrame); %normalizzo la cross correlazione

[Max, MaxIndex] = max(CrossCorrFrame); %trovo il massimo e il rispettivo indice
campioniRitardo = delayFrame(MaxIndex);
ritardi(1, n_blocchi+1) = campioniRitardo;
differenze(1, n_blocchi+1) = ritardi(1,n_blocchi) - campioniRitardo;

%allineo l'ultimo pezzo di segnale
if (campioniRitardo>=0)
    segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio+campioniRitardo:fine+campioniRitardo);
end
if (campioniRitardo<0)
        segnaleAudioSenzaDeriva(inizio:fine) = segnaleAudioTagliato(inizio-campioniRitardo:fine-campioniRitardo);
end 
    
%Plot di tutti i disallineamenti causati dalla deriva e dai silenzi
figure
plot(1:length(ritardi), ritardi);
title('Deriva dei macro blocchi')
 
[Max, MaxIndex] = max(differenze); % trovo il blocco in cui è stato inserito il "pezzo estraneo"
%Plot delle differenze nei disallineamenti successivi  per trovare i pezzi estranei
figure
plot(1:length(differenze), differenze);
title('Differenza di ritardi tra macro-blocchi successivi: probabili pezzi estranei')

sAudioSenzaDeriva_length = length(segnaleAudioSenzaDeriva);


%% 4. RIMOZIONE PEZZI ESTRANEIE E ALLINEAMENTO CORRETTO DEI MACRO BLOCCHI INTERESSATI

segnaleAudioSenzaPezziEstranei = segnaleAudioSenzaDeriva;
pezzi = zeros(3,1);
tagli = zeros(2,1);

[MaxD, MaxIndexD] = max(differenze);
soglia = max(fs_audio,MaxD)/10;
iter = 1;

for i=1:1:length(differenze)
    
    %se trovo un macro blocco con una differenza tra ritardi successivi superiore alla soglia, probabilmente contiene un pezzo estraneo da correggere
        if (differenze(1, i) > soglia)
            sprintf('Il macro blocco %d contiene un pezzo estraneo. Viene chiamata su questo macro blocco la funzione per i pezzi estranei.', i) 
            iter = iter + 1;

            %rimozione fine solo se il flag è su true
            if ( flag == true)
                %individuazione pezzo estraneo
                [pezzi] = pezziEstranei(frame_campioni, MaxIndex, frame_estranei_secondi, fs_audio, segnaleVideo, segnaleAudioTagliato, pezzi);

                %rimozione pezzo estraneo da traccia originale
                [segnaleAudioTagliato, tagli] = rimozionePezziEstranei(iter, fps_video, fs_audio, segnaleVideo, segnaleAudioTagliato, pezzi, tagli, factor);
            end

            %allineamento dopo rimozione pezzo estraneo
            [segnaleAudioSenzaPezziEstranei] = allineamentoSenzaPezziEstranei(frame_campioni, MaxIndex, frame_estranei_secondi, fs_audio, segnaleVideo, segnaleAudioTagliato, segnaleAudioSenzaPezziEstranei);

        end
end


%% 5. GENERAZIONE DATI OUTPUT

%info sul disallineamento iniziale
if (campioniRitardoIniziale>=0)
        sprintf('Inizialmente la seconda traccia partiva con un ritardo di %d campioni, cioè circa %d secondi', campioniRitardoIniziale, round(abs(campioniRitardoIniziale)/fs_audio))
end
if (campioniRitardoIniziale<0)
        sprintf('Inizialmente la seconda traccia partiva con un anticipo di %d campioni, cioè circa %d secondi', abs(campioniRitardoIniziale), round(abs(campioniRitardoIniziale)/fs_audio))
end 

%info su pezzi estranei
S = size(pezzi);
if (S(1,2) > 1)
    for i=2:1:S(1,2)
        inizio = (pezzi(1,i)+tagli(1,i))/fs_audio;
        fine = (pezzi(1,i)+tagli(2,i))/fs_audio;
        durata = tagli(2,i) - tagli(1,i);
        hms_i = fix(mod(inizio, [0, 3600, 60]) ./ [3600, 60, 1]);
        hms_o = fix(mod(fine, [0, 3600, 60]) ./ [3600, 60, 1]);
        sprintf('Un pezzo estraneo di durata probabile %.02f sec si trovava tra %02d:%02d:%02d e %02d:%02d:%02d', durata/fs_audio, hms_i(1,1), hms_i(1,2), hms_i(1,3), hms_o(1,1), hms_o(1,2), hms_o(1,3))
	end
end
if (S(1,2) == 1)
    	sprintf('Non sono stati rilevati pezzi estranei nel segnale audio esterno.')
end

%info su deriva
[MaxDifferenze, MaxIndexDifferenze] = max(differenze);
campioniDeriva = sum(differenze);
campioniDeriva = campioniDeriva - MaxDifferenze;
sprintf('La deriva causava un ritardo totale di %d campioni, cioè circa %d millisecondi (su un file di circa %d minuti)', campioniDeriva, round(campioniDeriva/fs_audio*1000), round(sAudioSenzaDeriva_length/fs_audio/60))


%% 6. SCRITTURA FILE OUTPUT

%normalizzo guadagno del segnale prima di salvarlo
audio_output = segnaleAudioSenzaPezziEstranei / max(abs(segnaleAudioSenzaPezziEstranei));

audiowrite('audioAligned.wav', audio_output, fs_audio);