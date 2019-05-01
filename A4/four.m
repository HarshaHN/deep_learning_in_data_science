% DD2424 Deep Learning in Data Science from Prof. Josephine Sullivan
% 04 Assignment dated April 29 2019 
% RNN to synthesize english text character-by-character
%-------------------------------------------------------
%Code Author: Harsha HN
%-------------------------------------------------------

function four
    close all; clear; clc; 
    %TotalTime = tic;
    
    %% 0.1 Read in the data
    bookFname = 'data/Goblet.txt';
    fid = fopen(bookFname, 'r');
    bookData = fscanf(fid, '%c'); fclose(fid);
    bookChars = unique(bookData); K = length(bookChars); bookN = length(bookData);
    
    % Character - index mapping
    char_to_ind = containers.Map('KeyType','char','ValueType','int32');
    ind_to_char = containers.Map('KeyType','int32','ValueType','char');
    for i = 1:K
        char_to_ind(bookChars(i)) = i;
        ind_to_char(i) = bookChars(i);
    end
    
    %% 0.2 Data to vectors
    disp('***Data pre-processing begins***')
    %Character to index
    bookInd = zeros(bookN,1);
    for i = 1:bookN
        bookInd(i, 1) = char_to_ind(bookData(i));
    end
    
    % Input and label
    trainX = bookInd(1:bookN-1);
    trainY = bookInd(2:bookN);
%{
    %Input (character) encoding into KxbookN
    trainX_hot = zeros(K, bookN); %h0 = zeros(m, 1);   
    for i = 1:bookN-1
        trainX_hot(:, i) = bsxfun(@eq, 1:K, trainX(i))';
    end
    trainY_hot = [X_hot(:,2:end), bsxfun(@eq, 1:K, trainX(i+1))'];
%}    
    disp('***Data pre-processing completed***')
    
    %% 0.3 Set hyper-parameters & initialize the RNN's parameters
    m = 100; %Dim of hidden state
    GDparams.eta = 0.1; GDparams.n_epochs = 1;
    GDparams.seqlength = 25; GDparams.batches = bookN/GDparams.seqlength;
    %GDparams.rho = 0.9; GDparams.n_epochs = ceil(30000/GDparams.batches);
    
    %Weight initialization
    sig = .01; RNN.b = zeros(m,1); RNN.c = zeros(K,1);
    RNN.U = randn(m, K)*sig; RNN.W = randn(m, m)*sig; RNN.V = randn(K, m)*sig;
    
    %% 0.4 Synthesize text from your randomly initialized RNN
%{
    h0 = rand(m, 1); x0 = 'h'; seqlength = 25;
    
    in.ht = h0; in.x = char_to_ind(x0); out = char; out(1) = x0;
    for j = 1:seqlength
        [P, in] = GenFP(RNN, in); out(j+1) = ind_to_char(in.x);
        ixs = find(cumsum(P) - rand >0); in.x = ixs(1);
    end
    disp(out)
%}    
    
    %% 0.5 Implement the forward & backward pass of back-prop
    disp('***Training begins!***'); 
    sprintf('Number of epochs: %d\n Seq len: %d, Batches: %d, updates: %d',GDparams.n_epochs, GDparams.seqlength, GDparams.batches, GDparams.n_epochs*GDparams.batches)
    
    for e = 1:GDparams.n_epochs %Epochs
        EpochTime = tic;       
%
        %Batchwise parameter updation
        ord = randperm(GDparams.batches); %Random shuffle of batches

        for j=1:GDparams.batches 
            %uTime = tic; %Update time
            t = t + 1; % Increment update count
            j_end = ord(j)*GDparams.n_batch;
            j_start = j_end-GDparams.n_batch +1;
            inds = j_start:j_end;
            Xbatch = rtrainX(:,:,inds);
            VXbatch = rVX(:,:,inds); Ybatch = rtrainY(inds);

            %Updates
            %GDparams.eta = cyclic(t, ns, etaMax, etaMin); n(t) = GDparams.eta;
            [RNN, ~] = MiniBatchGD(X, Y, RNN, GDparams);
        end
 %}
        sprintf('Epoch %d in %d, Total updates %d', e, toc(EpochTime), t)
        time=time+toc(EpochTime);
    end
    %% Evaluation
    h0 = zeros(m, 1);
    [J, Ypred] = ComputeLoss(RNN, X, Y, h0);
    
    %% sprintf('Total time is %d', toc(TotalTime)); 
    
end

function [RNNstar, O] = MiniBatchGD(X, Y, RNN, GDparams)
    %Mini batch Gradient Descent Algo
    %Predict
    if nargin < 5
        h0 = zeros(length(RNN.b), 1);   
    end
    [P, H, A, O] = ForwardPass(RNN, X, h0);
 
    %Compute gradient
    [gradRNN] = CompGradients(RNN, X, Y, P, H, A);
%{
    %Sanity check for gradient
    [gn] = NumericalGradient(Xbatch, Ybatch, ConvNet, 1e-4);
    relerr.W = rerr(gradRNN.W, gn{3});
    relerr.F{1} = mean(rerr(gradRNN.F{1}, gn{1})); 
    relerr.F{2} = mean(rerr(gradRNN.F{2}, gn{2}));
%}    
    
    for f1 = fieldnames(gradRNN)'
        %Clip gradients to avoid the exploding gradient problem.
        gradRNN.(f1{:}) = max(min(gradRNN.(f1{:}), 5), -5);
        
        %Update the parameters in RNN
        RNNstar.(f1{:}) = RNN.(f1{:});
    end
    %v{3} = GDparams.rho*v{3} + GDparams.eta * gradConvNet.W;

end

function [gradRNN] = CompGradients(RNN, X, Y, P, H, A)
    %Compute gradients via back propagation w.r.t  RNN: b, c, U, V, W params
    seq = length(X); m = length(H); K = length(RNN.c);
    LV = zeros(size(RNN.V)); Lc = zeros(size(RNN.c)); Gn = zeros(1,m);
    LW = zeros(size(RNN.W)); LU = zeros(size(RNN.U)); Lb = zeros(size(RNN.b));
    
    for i = seq:1
        Yhot = bsxfun(@eq, 1:K, Y(i))';
        %Softmax
        G = -(Yhot - P(:, i))';
        %Output layer
        LV = LV + (G' * H(:,i+1)'); %83*100: 83x1 X 1x100 = 18x55
        Lc = Lc + G'; % 83x1
        
        %Hidden layer
        G = G * RNN.V + Gn * RNN.W; %1x100: 1x83 X 83x100 + 1x100 X 100x100
        Gn = G * diag(1-power(tanh(A(:,i)),2)); %1x100: 1x100 X 100x100;
        Lb = Lb + Gn'; %100x100
        LW = LW + Gn' * H(:,i)'; %100x100: 100x1 X 1x100
        %Xhot = bsxfun(@eq, 1:K, X(i))'; % Gn' * Xhot'
        LU(:, X(i)) = LU(:, X(i)) + Gn'; %100x83: 1x100' X 83x1'
    end
    gradRNN.b = (1/seq)*Lb; gradRNN.c = (1/seq)*Lc;
    gradRNN.U = (1/seq)*LU; gradRNN.V = (1/seq)*LV; gradRNN.W = (1/seq)*LW; 
end

function [P, H, A, O] = ForwardPass(RNN, X, h0)
    seq = length(X); m = length(h0); K = length(RNN.c);
    H = zeros(m, seq+1); P = zeros(K, seq); A = zeros(m, seq); O = zeros(seq, 1);
    
    H(:, 1) = h0;
    for i = 1:seq
        A(:, i) = RNN.W*H(:, i) + RNN.U(:, X(i)) + RNN.b; %mx1: mxm X mx1 + mxK X Kx1
        H(:, i+1) = tanh(A(:, i)); %mx1 
        ot = RNN.V*H(:, i+1) + RNN.c; %Kx1: Kxm X mx1
        P(:, i) = softmax(ot); %Kx1
        [~, O(i)] = max(P(:, i));
    end
end

function [J, Ypred] = ComputeLoss(RNN, X, Y, h0)

    %h0 = zeros();
    [P, ~, ~, Ypred] = ForwardPass(RNN, X, h0);
    
    Loss = 0; seq = length(X);
    for i = 1:seq
        pt = P(:,i); yt = Y(i);
        Loss = Loss - log(pt(yt));
    end
    J = Loss ./ seq;
end

function [P, out] = GenFP(RNN, in)
    at = RNN.W*in.ht + RNN.U(:, in.x) + RNN.b; %mx1: mxm X mx1 + mxK X Kx1
    out.ht = tanh(at); %mx1 
    ot = RNN.V*out.ht + RNN.c; %Kx1: Kxm X mx1
    P = softmax(ot); %Kx1
    [~, out.x] = max(P);
end

function [rerr] = rerr(ga, gn)
    %Compute relative error
    rerr = sum(sum(abs(ga - gn)./max(eps, abs(ga) + abs(gn))))./ numel(ga);
end
