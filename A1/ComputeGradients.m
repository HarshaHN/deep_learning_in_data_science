function [grad_W, grad_b] = ComputeGradients(X, Y, P, W, lambda)
    %COMPUTEGRADIENTS Summary of this function goes here
    %   Detailed explanation goes here
    % Y or P: KxN, X: dxN, W: Kxd, b: Kx1
    
    LossW = (-1./P) * ; %Kxd
    Lossb = (-1./P) * ; %Kx1
    R = 2*W;
    Jw = (1./size(X, 2)) * (LossW) + lambda.*R;
    Jb = (1./size(X, 2)) * (Lossb);
    
    grad_W = Jw; %Kxd.
    grad_b = Jb; %Kx1
    
end