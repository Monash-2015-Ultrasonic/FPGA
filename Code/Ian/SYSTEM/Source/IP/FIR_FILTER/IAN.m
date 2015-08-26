clear; close all; clc;

%%

logfile = fopen('./test3.log');
M = textscan(logfile,'%s');
fclose(logfile);
clear logfile;

if (ispc),
    dataBin = hexToBinaryVector(M{1,1});
    if (size(dataBin) > 12),
        dataDec = bi2de(dataBin(:, end-11:end), 'left-msb');
    else
        dataDec = bi2de(dataBin, 'left-msb');
    end
elseif (isunix),
    dataBin = dec2bin(hex2dec(M{1,1}), 16);
    dataDec = bin2dec(dataBin(:, end-11:end));
end
clear M;
clear dataBin;

%dataDec = dataDec ./ 4096 * 5;

data = dataDec(3000:11000) - 1528;% - floor(4095/2);

dataCoeff = importdata('FIR_FILTER_coef_int.txt');

%data = dataCoeff;
%data = flipud(data);
%data = [zeros(100,1); data; zeros(200,1); data; flipud(data); zeros(200,1); data.*randi(10, length(data), 1)./10; zeros(100,1)];

%data = 0.5*data;
data = [data; 0.25*flipud(dataCoeff); 0.25*dataCoeff; zeros(500,1); flipud(dataCoeff); dataCoeff];

%data = [zeros(500,1); flipud(dataCoeff); dataCoeff; zeros(500,1)];

%%

%     %
%     %open and read data from file
%     %
%     file_name = ['FIR_FILTER_input.txt'];
%     infile = fopen (file_name, 'r');
%     % read in data from the file
%     data = fscanf(infile, '%d');
%     fclose(infile);

FIR_FILTER_model

%%
%dataCoeff = importdata('FIR_FILTER_coef_int.txt');
%dataIn = importdata('FIR_FILTER_input.txt');
dataIn = data;
dataOut = importdata('FIR_FILTER_model_output.txt');

%dOut_sq = dataOut.^2;
%E = sum(dOut_sq);
%maxDataOut = 186533673;

subplot(3,1,1);
plot(dataCoeff);
subplot(3,1,2);
plot(dataIn);
subplot(3,1,3);
%plot((dataOut) ./ maxDataOut);
plot(dataOut);
