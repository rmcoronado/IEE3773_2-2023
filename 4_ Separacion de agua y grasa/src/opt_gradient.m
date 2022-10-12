function [ x1, history] = opt_gradient( sub_sampling, sensitivity, B, x0, max_i, tol, option, show, mask)
%OPT_GRADIENT Summary of this function goes here
%   Detailed explanation goes here

U = sub_sampling;
C = sensitivity;

% Some operators
E  = @(C,U,X) U.*itok(C.*X, [1 2]);
Eh = @(C,U,X) sum(conj(C).*ktoi(U.*X,[1 2]),3);

% Size
[m,n,l] = size(C);

% Residual
r0 = zeros([m n]);
r1 = zeros([m n]);

% Resulting image
x1 = zeros([m n]);

% Error and convergence history
history = zeros(max_i, 1);
error = tol + 1.0; 

%% Descending gradient
if option=='dg'

    % Initial estimation of r0
    r0 = r0 + Eh(C,U,B) - Eh(C,U,E(C,U,x0));

    % Solves the problem
    i = 0;
    while error > tol && i < max_i
        % Iteration
        i = i + 1;
        
        % Calculate alpha
        tmp0 = Eh(C,U,E(C,U,r0));
        alpha = r0(:)'*r0(:)./(r0(:)'*tmp0(:));

        % Estimate image
        x1 = x0 + alpha*r0;
        r0 = r0 - alpha*tmp0;

        % error estimation
        error = norm(abs(x1(mask)) - abs(x0(mask)), 2);
        history(i) = error; 

        if show
            figure(20)
            imagesc(abs(reshape(x0, [m,n])));
            caxis([0, 0.5])
            axis off equal
            colormap gray
            title(sprintf('iteration %d',i))
            drawnow
        end
        
        % Update
        x0 = x1;
    end
    
%% Conjugate gradient    
elseif option=='cg'

    % Initial estimation of r0
    r0 = r0 + Eh(C,U,B) - Eh(C,U,E(C,U,x0));
    p0 = r0;
    
    % Solves the problem
    i = 0;
    while error > tol && i < max_i
        % Iteration
        i = i + 1;
        
        % Calculate alpha
        tmp0 = Eh(C,U,E(C,U,p0));
        alpha = r0(:)'*r0(:)./(p0(:)'*tmp0(:));

        % Estimate image and update residual
        x1 = x0 + alpha*p0;
        r1 = r0 - alpha*tmp0;

        % 
        beta = r1(:)'*r1(:)/(r0(:)'*r0(:));
        p1 = r1 + beta*p0;
        
        % error estimation
        error = norm(abs(x1(mask)) - abs(x0(mask)), 2);
        history(i) = error; 

        % Update
        x0 = x1;
        p0 = p1;
        r0 = r1;
        
        if show
            figure(20)
            imagesc(abs(reshape(x0, [m,n])));
%             caxis([0, 0.5])
            axis off equal
            colormap gray
            title(sprintf('iteration %d',i))
            drawnow
        end
        
    end    
else
    exit(fprintf('Avíspate amermelao!'))
end

% Reshape result and history;
% x1 = reshape(x1, [m,n]);
history(history==0) = [];
size(x1)

return;
end