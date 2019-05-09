%% Sistemas de Comunicaciones Digitales - Practica 2 Transmision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Autores: 
%   Jose Andres Hernandez Hernandez ie704453
%   Robin Salgado de Anda           ie686481
%   Isaac Yael Vazquez Gonzalez     ie703092
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parte 1 - Caracterizacion del Canal del Comunicacion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Paso 1: Generacion de una senal senoidal de 5kHz de frecuencia y 1 de
%           amplitud. Reproducir el sonido de manera que se transmita al 
%           receptor de manera que se encuentren los valores de volumen y 
%           sensibilidad adecuados para el sistema

close all; clc; clear all;      % Borramos todo
fs = 96e3;                      % Frecuencia de muestre a 96kHz
mp = 16;                        % 16-bits por muestra
Amp = 1                         % Amplitud de senoidal
f = 5000;                       % Frecuencia de senoidal
T = 1;                          % Cantidad de segundos limite
t = 0:1/fs:T;                   % Vector de tiempo
y = sin(2*pi*f*t);              % Funcion de senoidal
plot(t,y)                       % Grafica de la senal senoidal
soundsc(y,fs)                   % Reproduccion de audio

%% Paso 2: Identificar el canal, es decir, obtener su respuesta en 
%           frecuencia. Vamos a emplear tres tecnicas diferentes. 
%
%% a) Impulso conformado por un segundo de 0 1 0 

Pulse = zeros(1,2*fs+1) % Vector de ceros con duracion de 2s
Pulse(fs) = 1;          % A la mitad del vector ponemos un solo pulso
soundsc(Pulse,fs);      % Reproducimos con una frecuencia de 96kHz

%% c) Como segunda tecnica, utilizaremos una senal que tiene el mismo 
%       espectro que el impulso: el ruido gaussiano

Ruido = randn(1,5*fs);              % Vector de ruido gaussiano de 5s
pwelch(Ruido,[],[],[],fs,'power');  % Lo analizamos con pwelch
soundsc(Ruido,fs);                  % Lo reproducimos

%% e) Genera una senal que sea la suma de senoidales de misma amplitud y 
%       con frecuencias de 500:500:2000

time = 0:1/fs:2;                        % Vector de tiempo de 2s
sen1 = sin(2*pi*500 *time);             % Senoidal de 500Hz
sen2 = sin(2*pi*1000*time);             % Senoidal de 1kHz
sen3 = sin(2*pi*1500*time);             % Senoidal de 1.5kHz
sen4 = sin(2*pi*2000*time);             % Senoidal de 2kHz

senTotal = sen1 + sen2 + sen3 + sen4;   % Suma de senoidales
soundsc(senTotal,fs);                   % Lo reproducimos

%% f) Genere una senal chirp (-1 volt a 1 volt) de frecuencias 
%       500:500:20000      

t = 0:1/fs:2;                   % Vector de tiempo de 2s con pasos de 1/fs 
y = chirp(t,500,2,20e3);        % Senal chirp de 2s segundos de 500 a 20kHz

% Analisis de la densidad espectral de potencia
pwelch(y, [500], [300], [500], fs, 'power');  
soundsc(y,fs);                  % Reproducimos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parte 2 - Transmision en Banda Base
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generacion de pulso SRRC con r = 0.5 y frecuencia maxima B = 1800Hz. 
%   Fs = 96000 Hz en Tx

close all; clc; clear all;      % Borramos todo
Fs = 96e3;                      % Frecuencia de muestreo
B = 7200;                       % Frecuencia maxima
beta = 0.5;                     % Beta del pulso
Rb = 2*B/(1+beta);              % Bit Rate
E = 1/Rb;                       % Energia
mp = Fs/Rb;                     % Muestras por bit
Tp = 1/Rb;                      % Periodo de bit
Ts = 1/Fs;                      % Intervalo de muestreo
D = Tp/Ts;                      % Duracion de pulso 
type = 'srrc';                  % Tipo de pulso

[Prc t] = rcpulse(beta, D, Tp, Ts, type, E);    % Generamos el pulso SRRC
stem(Prc)                                       % Graficacion del pulso

%% Concatenacion de bits a enviar: 
%   Utilizar la imagen de la Lena recortada concatenada con un header 
%   y generar una senal Polar utilizando el pulso base

% Preambulo de 4 octetos para que el Rx se enganche con la sincronia.
bit = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1  0 1 0 1 0 1 0 1 1];

load lena512.mat                    % Carga de la imagen de la lena
lenarec = lena512(252:284,318:350); % Recorte de la imagen a 33x33 pixeles
%lenarec = lena512(1:127,1:127);    % Recorte de la imagen a 127x127 pixeles
imshow(uint8(lenarec));             % Visualizacion de la imagen recortada
b = de2bi(lenarec, 8, 'left-msb');  % Conversion a una matriz de bits
b = b';                             % Transpuesta de la matrix
bits = b(:);                        % Conversion a vector
[w h] = size(lenarec);              % Obtencion de dimensiones de la imagen

% Creacion de header con informacion de las dimensiones de la imagen
header = [de2bi(w,8,'left-msb'),de2bi(h,8,'left-msb'),de2bi(8,8,'left-msb')];
header = cast(header,'int8');       % Casteo del header a signado de 8-bits
bits = [bit,header,bits'];          % Concatenacion de info con el header

%% Generacion de senal Polar con pulso base 
%   Se utiliza el codigo de linea Polar NRZ

pnrz1 = bits;                       % Se guarda la informacion
pnrz1(pnrz1 == 0) = -1;             % Valores en 0 se transforman en -1
pnrz = zeros(1,(numel(bits))*mp);   % Creacion del vector para Pulse-train
pnrz(1:mp:end) = pnrz1;             % Tren de pulsos con la informacion
signalPNRZ = conv(pnrz, Prc);       % Convolucion con pulso base

% Normalizacion a potencia unitaria del tren de pulsos
Px = (1/numel(signalPNRZ))*sum(signalPNRZ*signalPNRZ');
signalPNRZ = signalPNRZ/sqrt(Px);   % Tren de pulsos normalizados
var(signalPNRZ)                     % Verificacion de la potencia unitaria
plot(signalPNRZ(1:mp*100))          % Verificacion de primeras muestras

%% Adicion de silencio al inicio y transmision
%   Agregar medio segundo de silencio al inicio y al momento de transmision
soundsc([zeros(1, Fs/2), signalPNRZ], Fs)       % Reproducimos
%% Diagrama de ojo de la senal en Tx
%   Se ignora el silencio inicial
eyediagram(signalPNRZ, 2*mp)                    % Diagrama de ojo
%% Densidad espectral de potencia en Tx
%   Se ignora el silencio inicial
pwelch(signalPNRZ,[500],[300],[500],Fs,'power') % Densidad espectral

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parte 3 - Transmision en Pasa Banda con Modulacion en Amplitud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Paso 1: Modulacion en amplitud

close all; clc; clear all;              % Borramos todo
t = .01;
Fc = 10000;                             % Frecuencia de corte
Fs = 80000;                             % Frecuencia de muestreo
t = [0:1/Fs:0.01]';                     % Vector de tiempo
s = sin(2*pi*300*t)+2*sin(2*pi*600*t);  % Senal original
[num,den] = butter(10,Fc*2/Fs);         % Filtro pasa-bajas (LPF)
sam = ammod(s,Fc,Fs);                   % Modulacion
s1 = amdemod(sam,Fc,Fs,0,0,num,den);    % Demodulacion

% Observe las siguientes gr�ficas
plot(t,s); hold on                      % Grafica de senal original
plot(t,sam);                            % Grafica de senal modulada
%% Comprobacion de la senal original en el dominio de la frecuencia
pwelch(s,[500],[300],[500],Fs,'power')  % Densidad espectral
%% Comprobacion de la senal modulada en el dominio de la frecuencia
pwelch(sam,[500],[300],[500],Fs,'power')% Densidad espectral
%% Comprobacion de la senal demodulada en el dominio de la frecuencia
pwelch(s1,[500],[300],[500],Fs,'power') % Densidad espectral
%% Comprobacion del filtro pasa-bajas en el dominio de la frecuencia
freqz(num,den)                          % Respuesta en frecuencia

%% Paso 2: Transmision en ancho de banda grande
%           Disene una senal de pulsos SRRC con beta = 0.5 con ancho de 
%           de banda B = 7.2kHz. Utilizando AM tipo DSB-SC, module la senal
%           para que quede centrada en 20 kHz. Obtenga su espectro. 
%           Utilice Fs = 96kHz

Fc = 20000;                     % Frecuencia de corte
Fs = 96e3;                      % Frecuencia de muestreo
B = 7200;                       % Frecuencia maxima
beta = 0.5;                     % Beta del pulso
Rb = 2*B/(1+beta);              % Bit Rate
E = 1/Rb;                       % Energia
mp = Fs/Rb;                     % Muestras por bit
Tp = 1/Rb;                      % Periodo de bit
Ts = 1/Fs;                      % Intervalo de muestreo
D = Tp/Ts;                      % Duracion de pulso 
type = 'srrc';                  % Tipo de pulso

[Prc t] = rcpulse(beta, D, Tp, Ts, type, E);    % Generamos el pulso SRRC
plot(t, Prc)                                    % Pulso base

%% Concatenacion de bits a enviar: 
%   Utilizar la imagen de la Lena recortada concatenada con un header 
%   y generar una senal Polar utilizando el pulso base

% Preambulo de 4 octetos para que el Rx se enganche con la sincronia.
bit = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1  0 1 0 1 0 1 0 1 1];

load lena512.mat                    % Carga de la imagen de la lena
%lenarec = lena512(252:284,318:350); % Recorte de la imagen a 33x33 pixeles
lenarec = lena512(1:127,1:127);    % Recorte de la imagen a 127x127 pixeles
imshow(uint8(lenarec));             % Visualizacion de la imagen recortada
b = de2bi(lenarec, 8, 'left-msb');  % Conversion a una matriz de bits
b = b';                             % Transpuesta de la matrix
bits = b(:);                        % Conversion a vector
[w h] = size(lenarec);              % Obtencion de dimensiones de la imagen

% Creacion de header con informacion de las dimensiones de la imagen
header = [de2bi(w,8,'left-msb'),de2bi(h,8,'left-msb'),de2bi(8,8,'left-msb')];
header = cast(header,'int8');       % Casteo del header a signado de 8-bits
bits = [bit,header,bits'];          % Concatenacion de info con el header


%% Generacion de senal Polar con pulso base 
%   Se utiliza el codigo de linea Polar NRZ

pnrz1 = bits;                       % Se guarda la informacion
pnrz1(pnrz1 == 0) = -1;             % Valores en 0 se transforman en -1
pnrz = zeros(1,(numel(bits))*mp);   % Creacion del vector para Pulse-train
pnrz(1:mp:end) = pnrz1;             % Tren de pulsos con la informacion
signalPNRZ = conv(pnrz, Prc);       % Convolucion con pulso base

% Normalizacion a potencia unitaria del tren de pulsos
Px = (1/numel(signalPNRZ))*sum(signalPNRZ*signalPNRZ');
signalPNRZ = signalPNRZ/sqrt(Px);   % Tren de pulsos normalizados
var(signalPNRZ)                     % Verificacion de la potencia unitaria
plot(signalPNRZ(1:mp*100))          % Verificacion de primeras muestras

%% Espectro de frecuencia de senal modulada en amplitud tipo DSB-SC
sam = ammod(signalPNRZ,Fc,Fs);              % Modulacion de la senal
pwelch(sam,[500],[300],[500],Fs,'power');   % Espectro de frecuencias

%% Transmision de senal modulada en amplitud
soundsc(sam,Fs);                  % Lo reproducimos
