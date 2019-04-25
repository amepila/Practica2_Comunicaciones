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

disp('Grabando Señal...');      % Mensaje de inicio de grabacion
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