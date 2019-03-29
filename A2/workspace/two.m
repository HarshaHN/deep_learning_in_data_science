% DD2424 Deep Learning in Data Science from Prof. Josephine Sullivan
% 02 Assignment dated March 27 2019 
% Author: Harsha HN harshahn@kth.se
% Two layer network
% Exercise 1

function two
    close all; clear all; clc;

    k = 10; %class 
    m = 50; %Nodes in hidden layer
    d = 32*32*3; %image size
    N = 10000; %Num of training samples

    %Load the datasets
    [X, Y, y] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_1.mat');
    [Xv, Yv, yv] = LoadBatch('../Datasets/cifar-10-batches-mat/data_batch_2.mat');
    [Xt, ~, yt] = LoadBatch('../Datasets/cifar-10-batches-mat/test_batch.mat');
    % X: 3072x10,000, Y: 10x10,000, y: 1x10,000

    % Init of parameters
    theta = {};
    [theta{1,1}, theta{2,1}] = InitParam(m, d);% W: mxd, b: mx1
    [theta{1,2}, theta{2,2}] = InitParam(k, m);% W: kxm, b: kx1
    
    %Init of hyperparameters
    lambda = 0; GDparams.eta = 0.01; 
    GDparams.n_batch = 100; GDparams.n_epochs = 400;
    
    %Sample
%     s = GDparams.n_batch; N = s;
%     X = X(:, 1:s); Y = Y(:, 1:s); y = y(:, 1:s);
%     Xv = Xv(:, 1:s); Yv = Yv(:, 1:s); yv = yv(:, 1:s);
    
    %Check the gradients
%     f = 10; n = 2; h = 1e-5;
%     [theta{1,1}, theta{2,1}] = InitParam(m, f);
%     checkX = X(1:f, 1:n); checkY = Y(1:f, 1:n);
%     [FP] = EvalClassfier(checkX, theta);
%     [ga] = CompGradients( checkX, checkY, FP, theta, lambda);
%     nW{1} = theta{1,1}; nW{2} = theta{1,2};
%     nb{1} = theta{2,1}; nb{2} = theta{2,2};
%     [gn] = ComputeGradsNum( checkX, checkY, nW, nb, lambda, h);
%     relerr.w1 = rerr(ga{1,1}, gn{1,1}); relerr.w2 = rerr(ga{1,2}, gn{1,2});
%     relerr.b1 = rerr(ga{2,1}, gn{2,1}); relerr.b2 = rerr(ga{2,2}, gn{2,2});

    %Init of cost 
    J_train = zeros(1, GDparams.n_epochs); 
    J_val = zeros(1, GDparams.n_epochs);
    
    %Training
    for e = 1:GDparams.n_epochs %Epochs

        %Random shuffle
        rng(400); shuffle = randperm(N);
        trainX = X(:, shuffle); trainY = Y(:, shuffle);

        %Batchwise parameter updation
        batches = N/GDparams.n_batch;
        ord = randperm(batches); %Random shuffle of batches
        for j=1:batches 
            j_start = (ord(j)-1)*GDparams.n_batch + 1;
            j_end = ord(j)*GDparams.n_batch;
            inds = j_start:j_end;
            Xbatch = trainX(:, inds);
            Ybatch = trainY(:, inds);
            [theta] = MiniBatchGD(Xbatch, Ybatch, GDparams, theta, lambda);
        end

        %Evaluate losses
        J_train(e) = ComputeCost(X, Y, theta, lambda);
        J_val(e) = ComputeCost(Xv, Yv, theta, lambda);
    end

    %Plot of cost on training & validation set
    figure(1); plot(J_train); hold on; plot(J_val); hold off; 
    xlim([0 e]); ylim([min(min(J_train), min(J_val)) max(max(J_train), max(max(J_val)))]);
    title('Total loss'); xlabel('Epoch'); ylabel('Loss'); grid on;
    legend({'Training loss','Validation loss'},'Location','northeast');

    %Accuracy on test set
    A = ComputeAccuracy(X, y, theta)*100; 
    vA = ComputeAccuracy(Xv, yv, theta)*100; 
    tA = ComputeAccuracy(Xt, yt, theta)*100; 
    sprintf('Accuracy on training set is %2.2f %',A)
    sprintf('Accuracy on validation set is %2.2f %',vA)
    sprintf('Accuracy on test set is %2.2f %',tA)
    
    %Class templates
%     s_im{10} = zeros(32,32,3);
%     nW{1} = theta{1,1}; nW{2} = theta{1,2};
%     nb{1} = theta{2,1}; nb{2} = theta{2,2};
%     for i=1:10
%         im = reshape(W(i, :), 32, 32, 3);
%         s_im{i}= (im - min(im(:))) / (max(im(:)) - min(im(:)));
%         s_im{i} = permute(s_im{i}, [2, 1, 3]);
%     end
%     figure(2); title('Class Template images'); montage(s_im, 'Size', [1,10]);
end

function [X, Y, y] = LoadBatch(filename)
    %Load .mat files into workspace
    
    A = load(filename); 
    X = batchNorm(double(A.data')./255);% dxN 3072x10,000  
    Y = bsxfun(@eq, 1:10, A.labels+1)';% KxN 10x10,000
    y = (A.labels + 1)';% 1xN 1x10,000
end

function [normX] = batchNorm(X)
    %Batch Normalization
    meanX = mean(X, 2);
    stdX = std(X, 0, 2);len = size(X, 2);
    zcX = X - repmat(meanX, [1, len]);
    normX = zcX ./ repmat(stdX, [1, len]);
end

function [W, b] = InitParam(r, c)
    %Initialisation of model parameters
    % W: rxc, b: rx1
    
    W = zeros(r,c); b = zeros(r,1);
    rng(400);
    for i=1:r
        W(i,:) = 1/sqrt(c).*randn(1,c);
    end
    %b = 0.01.*randn(r,1); %W = 1/sqrt(c).*randn(r,c);
end

function [FP] = EvalClassfier(X, theta)
    %P: KxN 2 layer: ReLU and softmax
    %theta = W1: mxd, b1: mx1  W2: kxm, b2: kx1
   
    s1 = theta{1,1}*X + theta{2,1}; % mxd*dxN + mx1 = mxN
    H = max(0, s1); % mxN
    s = theta{1,2}*H + theta{2,2}; % Kxm*mxN + Kx1 = KxN
    P = softmax(s); % KxN
    FP = {}; FP{1} = H; FP{2} = P;
end

function [ gradTheta] = CompGradients(X, Y, FP, theta, lambda)
    %Compute the gradients through back propagation
    % Y or P: KxN, X: dxN, theta = W: Kxd, b: Kx1, H: mxN
    
    %Initialize
    gW1 =0; gW2 =0; gb1 =0; gb2 =0;
    
    %Update loop
    N = size(X, 2); H = FP{1}; P = FP{2};
    for i = 1:N % ith image
        
        g = -(Y(:,i)-P(:,i))'; %1xK
        gW2 = gW2 + g' * H(:,i)'; %Kx1*1xm = Kxm
        gb2 = gb2 + g'; %Kx1
        
        %mxN
        g = g*theta{1,2}; %1xK*K*m = 1xm
        g = g*diag((H(:,i)>0)); %1xm*mxm = 1xm

        gW1 = gW1 + g'*X(:,i)'; %mxN*Nxd = mxd
        gb1 = gb1 + g'; % mxN
    end
    
    M = 0; %Momentum
    for r=1:2
        for c=1:2
            gradTheta{1,1} = (1./size(X, 2)).* (gW1) + lambda .*2*theta{1,1};
            gradTheta{1,2} = (1./size(X, 2)).* (gW2) + lambda .*2*theta{1,2};
            gradTheta{2,1} = (1./size(X, 2)).* (gb1);
            gradTheta{2,2} = (1./size(X, 2)).* (gb2);    
        end
    end
end

function [ thetaStar] = MiniBatchGD(X, Y, GDparams, theta, lambda)
    
    %Predict
    [FP] = EvalClassfier(X, theta);
 
    %Compute gradient
    [gradTheta] = CompGradients(X, Y, FP, theta, lambda);
    
    %Update the parameters in theta
    thetaStar{1,1} = theta{1,1} - GDparams.eta * gradTheta{1,1};
    thetaStar{1,2} = theta{1,2} - GDparams.eta * gradTheta{1,2};
    thetaStar{2,1} = theta{2,1} - GDparams.eta * gradTheta{2,1};
    thetaStar{2,2} = theta{2,2} - GDparams.eta * gradTheta{2,2};
end

function J = ComputeCost(X, Y, theta, lambda)
    % Compute cost
    % Y: KxN, X: dxN, W: Kxd, b: Kx1, lambda

    [FP] = EvalClassfier(X, theta); %KxN
    L = -log(Y' * FP{2}); %NxN
    totalLoss = trace(L); %sum(diag(L))
    R = sumsqr(theta{1,1}) + sumsqr(theta{1,2});
    J = (totalLoss)./ size(X, 2) + lambda.*R;
end

function A = ComputeAccuracy(X, y, theta)
    % y: 1xN, X: dxN, W: Kxd, b: Kx1, lambda    
    [FP] = EvalClassfier(X, theta); %KxN
    [~, argmax] = max(FP{2});
    c = (argmax == y);
    A = sum(c)/size(c,2);
end

%------------------------------------------------------------
%Correctness check of the Gradient

function [gn] = ComputeGradsNum(X, Y, W, b, lambda, h)
    
    grad_W = cell(numel(W), 1);
    grad_b = cell(numel(b), 1);
    [c] = ComputeCost(X, Y, mConv(W,b), lambda);

    for j=1:length(b)
        grad_b{j} = zeros(size(b{j}));

        for i=1:length(b{j})
            b_try = b;
            b_try{j}(i) = b_try{j}(i) + h;
            [c2] = ComputeCost(X, Y, mConv(W, b_try), lambda);
            grad_b{j}(i) = (c2-c) / h;
        end
    end

    for j=1:length(W)
        grad_W{j} = zeros(size(W{j}));

        for i=1:numel(W{j})   
            W_try = W;
            W_try{j}(i) = W_try{j}(i) + h;
            [c2] = ComputeCost(X, Y, mConv(W_try, b), lambda);

            grad_W{j}(i) = (c2-c) / h;
        end
    end
    gn = mConv(grad_W, grad_b);
    %gn{1,:} = grad_W; gn{2,:} = grad_b;
end

function [rerr] = rerr(ga, gn)
    %Compute relative error
    rerr = sum(sum(abs(ga - gn)./max(eps, abs(ga) + abs(gn))))./ numel(ga);
end

function [theta] = mConv(W,b)
    theta{1,1} = W{1}; theta{1,2} = W{2};
    theta{2,1} = b{1}; theta{2,2} = b{2};
end            