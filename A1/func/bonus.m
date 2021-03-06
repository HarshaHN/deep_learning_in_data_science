% DD2424 Deep Learning in Data Science from Prof. Josephine Sullivan
% Bonus 01 Assignment dated March 19 2019 
% Author: Harsha HN harshahn@kth.se
% Optimize the performance of the network
% Exercise 2

function bonus
    close all; clear all; clc;

    k = 10; %class 
    d = 32*32*3; %image size
    N = 10000; %Num of image

    %Load the datasets
    [X1, Y1, ~] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_1.mat');
    %[X2, Y2, ~] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_2.mat');
    %[X3, Y3, ~] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_3.mat');
    %[X4, Y4, ~] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_4.mat');
    [X5, Y5, ~] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_5.mat');    
    Xv= X5(:,9001:10000); Yv = Y5(:,9001:10000);
    X = [X1, X5(:, 1:9000)]; clear X1 X5;
    Y = [Y1, Y5(:, 1:9000)]; clear Y1 Y5;    
    [Xt, ~, yt] = LoadBatch('../Datasets/cifar-10-batches-mat/test_batch.mat');
    % X: 3072x10,000, Y: 10x10,000, y: 1x10,000

    % Initialization of parameters & hyperparameters
    [W, b] = InitParam(k, d); lambda = 0.01; % W: 10x3072, b: 10x1
    GDparams.n_batch = 100; GDparams.eta = 0.1; GDparams.n_epochs = 40;
    J_train = zeros(1, GDparams.n_epochs); J_val = zeros(1, GDparams.n_epochs);
    
    %Training
    for e = 1:GDparams.n_epochs %Epochs
        GDparams.eta = 0.9*GDparams.eta;
        %Random shuffle
        rng(400); shuffle = randperm(N);
        trainX = X(:, shuffle); trainY = Y(:, shuffle);

        %Batchwise parameter updation
        ord = 1:N/GDparams.n_batch; %ord = randperm(N/GDparams.n_batch);
        for j=1:max(ord) 
            j_start = (ord(j)-1)*GDparams.n_batch + 1;
            j_end = ord(j)*GDparams.n_batch;
            inds = j_start:j_end;
            Xbatch = trainX(:, inds);
            Ybatch = trainY(:, inds);
            [W, b] = MiniBatchGD(Xbatch, Ybatch, GDparams, W, b, lambda);
        end

        %Evaluate losses
        J_train(e) = ComputeCost(X, Y, W, b, lambda);
        J_val(e) = ComputeCost(Xv, Yv, W, b, lambda);
    end

    %Plot of cost on training & validation set
    figure(1); plot(J_train); hold on; plot(J_val); hold off; 
    xlim([0 e]); ylim([min(min(J_train), min(J_val)) max(max(J_train), max(max(J_val)))]);
    title('Total loss'); xlabel('Epoch'); ylabel('Loss'); grid on;
    legend({'Training loss','Validation loss'},'Location','northeast');

    %Accuracy on test set
    A = ComputeAccuracy(Xt, yt, W, b)*100; 
    sprintf('Accuracy on test data is %2.2f %',A)

    %Class templates
    s_im{10} = zeros(32,32,3);
    for i=1:10
        im = reshape(W(i, :), 32, 32, 3);
        s_im{i}= (im - min(im(:))) / (max(im(:)) - min(im(:)));
        s_im{i} = permute(s_im{i}, [2, 1, 3]);
    end
    figure(2); title('Class Template images'); montage(s_im, 'Size', [1,10]);
end

function [X, Y, y] = LoadBatch(filename)
    %Load .mat files into workspace
    A = load(filename); 
    X = double(A.data')./255;% dxN 3072x10,000
    Y = bsxfun(@eq, 1:10, A.labels+1)';% KxN 10x10,000
    y = (A.labels + 1)';% 1xN 1x10,000

end

function [W, b] = InitParam(k, d)
    %Initialisation of model parameters
    % W: Kxd, b: Kx1
    W = zeros(k,d);
    rng(400);
    for i=1:k
        W(i,:) = 0.01.*randn(1,d);
    end
    b = 0.01.*randn(k,1); %W = 0.01.*randn(10,3072);
    % W: 10x3072, b: 10x1

end

function P = EvaluateClassifier(X, W, b)
    %Linear equation and softmax func
    s = W*X + b; % Kxd*dxN + Kx1 = KxN
    P = softmax(s); % KxN

end

function [grad_W, grad_b] = ComputeGradients(X, Y, P, W, lambda)
    %Compute the gradients through back propagation
    % Y or P: KxN, X: dxN, W: Kxd, b: Kx1
    
    %Initialize
    LossW = 0; Lossb = 0;
    
    %Update loop
    N = size(X, 2);
    for i = 1:N % ith image
        g = -(Y(:,i)-P(:,i))'; %NxK
        LossW = LossW + g' * X(:,i)';
        Lossb = Lossb + g';
    end
    
    R = 2*W;
    Jw = (1./size(X, 2)) * (LossW) + lambda.*R;
    Jb = (1./size(X, 2)) * (Lossb);
    
    grad_W = Jw; %Kxd.
    grad_b = Jb; %Kx1
    
end

function [Wstar, bstar] = MiniBatchGD(X, Y, GDparams, W, b, lambda)
    
    %Predict
    P = EvaluateClassifier(X, W, b);
 
    %Compute gradient
    [grad_W, grad_b] = ComputeGradients(X, Y, P, W, lambda);
    
    %Update the parameters W, b
    Wstar = W - GDparams.eta * grad_W;
    bstar = b - GDparams.eta * grad_b;
    
end

function J = ComputeCost(X, Y, W, b, lambda)
    % Compute cost
    % Y: KxN, X: dxN, W: W: Kxd, b: Kx1, lambda

    P = EvaluateClassifier(X, W, b); %KxN
    L = -log(Y' * P); %NxN
    totalLoss = trace(L); %sum(diag(L))
    R = sumsqr(W); %sum(sum(W.*W));
    J = (totalLoss)./ size(X, 2) + lambda.*R;

end

function A = ComputeAccuracy(X, y, W, b)
    % y: 1xN, X: dxN, W: Kxd, b: Kx1, lambda    
    P = EvaluateClassifier(X, W, b); %KxN
    [~, argmax] = max(P);
    c = (argmax == y);
    A = sum(c)/size(c,2);
end

function [rerr] = rerr(ga, gn)
    %Compute relative error
    rerr = sum(sum(abs(ga - gn)./max(eps, abs(ga) + abs(gn))))./ numel(ga);
end
