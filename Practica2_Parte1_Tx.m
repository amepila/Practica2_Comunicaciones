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
%           frecuencia. Vamos a emplear tres t�cnicas diferentes. 
%
%% a) Impulso conformado por un segundo de 0 1 0 

Pulse = zeros(1,2*fs+1) % Vector de ceros con duracion de 2s
Pulse(fs) = 1;          % A la mitad del vector ponemos un solo pulso
soundsc(Pulse,fs);      % Reproducimos con una frecuencia de 96kHz

%% c) Como segunda t�cnica, utilizaremos una se�al que tiene el mismo 
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

%% f) Genere una senal �chirp� (-1 volt a 1 volt) de frecuencias 
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
Fs = 96000;                     % Frecuencia de muestreo
B = 1800;                       % Frecuencia maxima
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
% Preambulo de 4 octetos
bit = [1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1];

%% Concatenacion de bits a enviar: 
%   Utilizar la imagen de la Lena recortada concatenada con un header 
%   y generar una senal Polar utilizando el pulso base

load lena512.mat                    % Carga de la imagen de la lena
lenarec = lena512(252:284,318:350); % Recorte de la imagen a 32x32 pixeles
imshow(uint8(lenarec));             % Visualizacion de la imagen recortada
b = de2bi(lenarec, 8, 'left-msb');  % Conversion a una matriz de bits
b = b';                             % Transpuesta de la matrix
bits = b(:);                        % Conversion a vector
[w h] = size(lenarec);              % Obtencion de dimensiones de la imagen

% Creacion de header con informacion de las dimensiones de la imagen
header = [de2bi(w,8,'left-msb'),de2bi(h,8,'left-msb')];
header = cast(header,'int8');       % Casteo del header a signado de 8-bits
bits = [header,bits'];              % Concatenacion de info con el header

%% Generacion de senal Polar con pulso base 
%   Se utiliza el codigo de linea Polar NRZ

pnrz1 = bits;                       % Se guarda la informacion
pnrz1(pnrz1 == 0) = -1;             % Valores en 0 se transforman en -1
pnrz = zeros(1,(numel(bits))*mp);   % Creacion del vector para Pulse-train
pnrz(1:mp:end) = pnrz1;             % Tren de pulsos con la informacion
signalPNRZ = conv(pnrz, Prc);       % Convolucion con pulso base
stem(signalPNRZ(1:mp*100))          % Verificacion de primeras muestras

%% Adicion de silencio al inicio y transmision
%   Agregar medio segundo de silencio al inicio y al momento de transmision

silence = zeros(1, Fs/2);                   % Silencio de medio segundo
signalPNRZ_silence = [silence, signalPNRZ]; % Senal con silencio al inicio
stem(signalPNRZ_silence(1:mp*1500))         % Verificacion de silencio

%% Diagrama de ojo de la senal en Tx
%   Se ignora el silencio inicial

eyediagram(signalPNRZ, 2*mp)                    % Diagrama de ojo
%% Densidad espectral de potencia en Tx
%   Se ignora el silencio inicial

pwelch(signalPNRZ,[500],[300],[500],Fs,'power') % Densidad espectral
%% Transmision y verificacion de la senal en Tx 
%   En el dominio del tiempo y dominio de la frecuencia








