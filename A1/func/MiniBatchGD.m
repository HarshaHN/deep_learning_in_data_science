function [Wstar, bstar] = MiniBatchGD(X, Y, GDparams, W, b, lambda)
    
    %Predict
    P = EvaluateClassifier(X, W, b);
 
    %Compute gradient
    [grad_W, grad_b] = ComputeGradients(X, Y, P, W, lambda);
    
    %Update the parameters W, b
    Wstar = W - GDparams.eta * grad_W;
    bstar = b - GDparams.eta * grad_b;
    
end

