%% Sistemas de Comunicaciones Digitales - Practica 2 Recepcion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Autores: 
%   Jose Andres Hernandez Hernandez ie704453
%   Robin Salgado de Anda           ie686481
%   Isaac Yael Vazquez Gonzalez     ie703092
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parte 1 - Caracterizacion del Canal del Comunicacion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Definicion de parametros y creacion de objeto para grabacion

clear all; clc; close all;  % Limpieza del entorno
Fs = 96e3;                  % Frecuencia de muestreo a 96kHz
mpbits = 16;                % 16-bits por muestra
nChannels = 1;              % Utilizacion de un canal de audio
ID = -1;                    % Dispositivo de entrada de audio default 
time = 1.2;                 % Tiempo expresada en segundos

% Creacion de objeto para guardar la grabacion de audio
recObj = audiorecorder(Fs, mpbits, nChannels, ID);

%% Grabacion de audio

disp('Grabando Senal...');      % Mensaje de inicio de grabacion
recordblocking(recObj, time);   % Grabacion de audio determinada por time
disp('Fin de la grabacion');    % Mensaje de final de grabacion
%% Recuperacion de los datos

%play(recObj);                          % Primer testeo de audio recibido
signal_received = getaudiodata(recObj); % Obtencion de senal recibida
plot(signal_received,'r')               % Graficacion de senal recibida
ylabel('Amplitud')                      % Eje Y como amplitud de la senal
xlabel('Tiempo (ms)')                   % Eje X como tiempo en ms
title('Senal Recibida')                 % Titulo de la senal recibida
grid on
pwelch(signal_received,[500],[300],[500],Fs,'power'); % Analisis con pwelch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parte 2 - Transmision en Banda Base
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creacion del Match Filter
%   Utilizar la misma Fs que la senal de Tx

Fs = 96e3;                      % Frecuencia de muestreo
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
signalPNRZ = conv(signal_received, Prc)*(1/mp); % Convolucion con pulso base
plot(signalPNRZ(1:mp*1000))                     % Verificacion de primeras muestras

%% Graficacion del pulso antes del match filter
%   Se muestra la senal recibida antes de pasar por el match filter
var1 = (sign(-signal_received(4.228e4:mp:end))+1)/2;
%% Graficacion del pulso despues del match filter
%   Se muestra la senal recibida antes de pasar por el match filter
var2 = (sign(-signalPNRZ(4.228e4:mp:end))+1)/2;
%%  Diagrama de ojo de senal convolucionada
%   Se muestra el diagrama despues de pasar la senal convolucionada
eyediagram(signalPNRZ, 2*mp);                   % Diagrama de ojo
%% Densidad espectral de potencia en Rx
%   Se despliega la densidad espectral despues del match filter
pwelch(signalPNRZ,[500],[300],[500],Fs,'power') % Densidad espectral
%% Recuperacion de la Lena recortada en escala de grises

header_signal = zeros(1,56);                        % Creacion de vector del header
header_signal = signalPNRZ(4.228e4:mp:(4.228e4+56));% Vector del header
header_signal(header_signal >= 0) = 1;              % Umbral de decision para 1
header_signal(header_signal < 0) = 0;               % Umbral de decision para 0

preamble = header_signal(1:32);     % Preambulo de la senal
height = header_signal(33:40);      % Alto de la imagen recibida
weight = header_signal(41:48);      % Ancho de la imagen recibida
pixBit = header_signal(49:56);      % Pixeles por bit de la imagen

recovered_signal = zeros(1,height*weight*pixBit);   % Creacion de vector de la imagen
recovered_signal = signalPNRZ(4.228e4+57:mp:end);
recovered_signal(recovered_signal >= 0) = 1;
recovered_signal(recovered_signal < 0) = 0;

recovered_signal = recovered_signal(1:height*weight*pixBit);
length = numel(recovered_signal);
columns = length/8;
recovered_signal = recovered_signal';

matrix = reshape(recovered_signal,[8, columns]);
matrix = matrix';

image = bi2de(matrix);
image = image';
image = reshape(image, height*weight);
imshow(uint8(image));

