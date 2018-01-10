# Clip Alignment
Progetto realizzato per il corso di Elaborazione dell'Audio Digitale del [Politecnico di Torino](https://www.polito.it) tenuto dal professor Antonio Servetti.


## Descrizione

Il codice implementato in linguaggio Matlab (R2017b) ha lo scopo di allineare due tracce audio:
* Audio Interno (cioè la traccia incorporata alla traccia video)
*	Audio Esterno (cioè la traccia registrata esternamente, che si presuppone avere una qualità migliore e per questo la si vuole sostituire a quella interna, dopo averla allineata)

I problemi che il codice risolve sono di tre tipi:
1. Disallineamento iniziale delle due tracce
2. Disallineamento di deriva causato da una non perfetta sincronizzazione dei clock dei dispositivi di registrazione
3. Eventuali “pezzi estranei” (ad esempio silenzi dovuti a dei “freeze” nella registrazione) nella seconda traccia

Il codice restituisce in output:
* la traccia audio esterna, allineata correttamente rispetto a quella interna
* alcune informazioni sull’operazione eseguita (disallineamento iniziale, eventuali “pezzi estranei” e loro posizione e durata probabile, disallineamento di deriva)

#### Esempio informazioni di output

```m
>> alignment

ans = 'Attenzione: il segnale audio interno era a frequenza 44100 Hz ed è stato portato alla stessa frequenza del segnale audio esterno (48000 Hz).'

ans = 'Il macro blocco 14 contiene un pezzo estraneo. Viene chiamata su questo macro blocco la funzione per i pezzi estranei.'

ans = 'Fatti 1250 tentativi di rimozione di un pezzo estraneo tra 10-Jan-2018 15:44:55 e 10-Jan-2018 15:46:06'

ans = 'Inizialmente la seconda traccia partiva con un anticipo di 279008 campioni, cioè circa 6 secondi'

ans = 'Un pezzo estraneo di durata probabile 1.00 sec si trovava tra 00:02:00 e 00:02:01'

ans = 'La deriva causava un ritardo totale di 94 campioni, cioè circa 2 millisecondi (su un file di circa 5 minuti)'
 
```

## Procedura di installazione

1. scaricare i 4 file *.m
2. aprire il file _alignment.m_ in Matlab 
3. inserire nella stessa cartella dei file *.m le due tracce audio che si vogliono allineare (la traccia audio integrata nel video deve essere estratta a parte dall’utente, utilizzando un software a piacere, ad esempio FFmpeg https://www.ffmpeg.org/), chiamandole audioInterno.wav e audioEsterno.wav (oppure cambiare nel file Matlab _alignment.m_ le due tracce audio, facendo attenzione ai formati supportati dalla funzione audioread https://it.mathworks.com/help/matlab/import_export/supported-file-formats.html)  
4. Nella scheda Editor eseguire il codice cliccando su Run
5. La traccia audio allineata ottenuta in output deve essere sostituita a quella integrata nel video a parte dall’utente (utilizzando un software a piacere, ad esempio FFmpeg https://www.ffmpeg.org/)


## Test

Per testare il funzionamento del codice, seguire la procedura di installazione presentata al punto 2), eventualmente modificando la variabile `esempi` presente all’inizio del file _alignment.m_
*	`esempi == 1` utilizzerà le tracce audio di esempio (di circa 1 ora) fornite in aula, già estratte dal file video, che sono disponibili [QUI](https://drive.google.com/open?id=1Nxh1MmflR_YBGZzhxb7OEsWoLk-XBmhD)
*	`esempi == 2` utilizzerà delle tracce audio di esempio (di circa 5 minuti) realizzate a parte, scaricabili da questo stesso repository di Github (_audioInterno44.wav_ e _audioEsterno48s.wav_)

## Contributors
[Selene Di Viesti](https://github.com/SeleneDiViesti)

[Simone Montrucchio](https://github.com/simonemontrucchio)

