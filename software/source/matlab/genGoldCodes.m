%Main Program
%Author : Mathuranathan Viswanathan for gaussianwaves.blogspot.com
%Generated Gold Codes by generating two m-sequences d1 and d2.
%Here d2 is the decimated version of d1. For good correlation properties,
%d1 and d2 must be preferred pairs (based on decimation factor q and
%register size n).
%A set of gold sequence contains original d1 and d2 and XORed versions of 
%cyclic shifted versions of d1 and d2, depicted as
%GoldSequences(d1,d2)=[d1,d2,d1+Td2,d1+T^2d2,d1+T^3d2,...d1+T^(N-1)d2]
clc;
clear all;
n=6; %Register size for m-sequence generation
polynomial = [6 1 0]; %Polynomial m-sequence
numOfGoldSeq=6; %Number of Gold sequences to generate
q=5; %Decimation factor for preffered pair generation
%Be careful in chosing q, inappropriate value for q may result in poor 
%cross-correlation valued Gold codes

N=2^n-1;%Length of m-sequence

%d and dDecimated are preferred pair (if and only if the three conditions 
%for preferred-pair generation are satisfied)
%Generate Preferred pairs by decimation
[d,dDecimated]=genDecimatedPNSequence([6 1 0],q);

%Generate Gold code from Preferred Pairs
goldSequences = zeros(2+numOfGoldSeq,N);
goldSequences(1,:)=d;
goldSequences(2,:)=dDecimated;

dDecimatedShifted=dDecimated;

for rows = 3:2+numOfGoldSeq
    goldSequences(rows,:)=xor(d,dDecimatedShifted);
    
    %Cyclic Shifting dDecimated by 1 bit for each Gold Sequence
    dTemp=dDecimatedShifted(end);
    dDecimatedShifted(2:end) = dDecimatedShifted(1:end-1);
    dDecimatedShifted(1)=dTemp;    
    
end

%Cross-Correlation of Gold Sequence 1 with rest of Gold Sequence
h = zeros(1, numOfGoldSeq-1); %For dynamic Legends
s = cell(1, numOfGoldSeq-1);  %For dynamic Legends

for rows=2:2+numOfGoldSeq
    [crossCorrelation,lags]=crossCorr(goldSequences(1,:),goldSequences(rows,:));
    h(rows-1)=plot(lags,crossCorrelation);
    s{rows-1} = sprintf('Sequence-%d', rows);
    hold all;
end

%Dynamic Legends
% Select the plots to include in the legend
index = 1:numOfGoldSeq-1;
% Create legend for the selected plots
legend(h(index),s{index});

title('Cross Correlation of Gold Sequence 1 with other Gold Sequences');
ylabel('Cross Correlation');
xlabel('Lags');
ylim([-0.3 0.3]);