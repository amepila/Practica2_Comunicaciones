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
time = 6;                 % Tiempo expresada en segundos

% Creacion de objeto para guardar la grabacion de audio
recObj = audiorecorder(Fs, mpbits, nChannels, ID);

%% Grabacion de audio

disp('Grabando Senal...');      % Mensaje de inicio de grabacion
recordblocking(recObj, time);   % Grabacion de audio determinada por time
disp('Fin de la grabacion');    % Mensaje de final de grabacion
%% Recuperacion de los datos

%play(recObj);                          % Primer testeo de audio recibido
signal_received = getaudiodata(recObj); % Obtencion de senal recibida
signal_received = -signal_received;
save('signal_received.mat','signal_received');
plot(signal_received,'r')               % Graficacion de senal recibida
ylabel('Amplitud')                      % Eje Y como amplitud de la senal
xlabel('Tiempo (ms)')                   % Eje X como tiempo en ms
title('Senal Recibida')                 % Titulo de la senal recibida
%% Espectro de frecuencia de la senal recibida
grid on
%pwelch(signal_received,[500],[300],[500],Fs,'power'); % Analisis con pwelch
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
plot(signalPNRZ(1:mp*5000))                     % Verificacion de primeras muestras

%% Graficacion del pulso antes del match filter
%   Se muestra la senal recibida antes de pasar por el match filter
var1 = (sign(signal_received(start:mp:end))+1)/2;
%% Graficacion del pulso despues del match filter
start = 6.556e4;
%   Se muestra la senal recibida antes de pasar por el match filter
bits_recovered = (sign(signalPNRZ(start:mp:end))+1)/2;
%%  Diagrama de ojo de senal convolucionada
%   Se muestra el diagrama despues de pasar la senal convolucionada
eyediagram(signalPNRZ, 2*mp);                   % Diagrama de ojo
%% Densidad espectral de potencia en Rx
%   Se despliega la densidad espectral despues del match filter
pwelch(signalPNRZ,[500],[300],[500],Fs,'power') % Densidad espectral
%% Recuperacion de la Lena recortada en escala de grises

% header_signal = zeros(1,56);                        % Creacion de vector del header
% header_signal = signalPNRZ(start:mp:(start+(56*mp)));% Vector del header
% header_signal(header_signal >= 0) = 1;              % Umbral de decision para 1
% header_signal(header_signal < 0) = 0;               % Umbral de decision para 0

header_signal = bits_recovered(1:56);

preamble = header_signal(1:32);     % Preambulo de la senal
height = bi2de(header_signal(33:40)','left-msb');      % Alto de la imagen recibida
weight = bi2de(header_signal(41:48)','left-msb');      % Ancho de la imagen recibida
pixBit = bi2de(header_signal(49:56)','left-msb');      % Pixeles por bit de la imagen
%%

% %recovered_signal = zeros(1,height*weight*pixBit);   % Creacion de vector de la imagen
% recovered_signal = signalPNRZ(start+57:mp:end);
% recovered_signal(recovered_signal >= 0) = 1;
% recovered_signal(recovered_signal < 0) = 0;

len = height*weight*pixBit;
payLoad = bits_recovered(numel(header_signal) + 1 :len + numel(header_signal));
columns = len/8;

matrix = reshape(payLoad',[8, columns]);
matrix = matrix';

image = bi2de(matrix,'left-msb');
image = image';
image = reshape(image, [height, weight]);
imshow(uint8(image));

%%
load lena512.mat                    % Carga de la imagen de la lena
lenarec = lena512(252:284,318:350); % Recorte de la imagen a 32x32 pixeles
imshow(uint8(lenarec));             % Visualizacion de la imagen recortada
b = de2bi(lenarec, 8, 'left-msb');  % Conversion a una matriz de bits
b = b';                             % Transpuesta de la matrix
bits = b(:);                        % Conversion a vector
sum(xor(bits, payLoad))

6556
7.779e4