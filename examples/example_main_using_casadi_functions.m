restoredefaultpath;
clear all;
clc;

addpath(genpath('../src'));
% make sure, that matlab can find casadi package
% addpath(genpath('../tools/'))
import casadi.*

%% define Alex's non-convex problem
N   =   2;
n   =   2;
m   =   1;

y_1 = SX.sym('y_1', n);
y_2 = SX.sym('y_2', n);

f1f = 2 * (y_1(1) - 1)^2;
f2f = (y_2(2) - 2)^2;

f1 = Function('f_1', {y_1}, {f1f});
f2 = Function('f_2', {y_2}, {f2f});

h1f = 1 - y_1(1)*y_1(2);
h2f = -1.5 + y_2(1)*y_2(2);

h1 = Function('h_1', {y_1}, {h1f});
h2 = Function('h_2', {y_2}, {h2f});

A1  =   [0, 1];
A2  =   [-1,0];
b   =   0;

lb1 =   [0;0];
lb2 =   [0;0];

ub1 =   [10;10];
ub2 =   [10;10];

%% initalize
maxit   =   30;
y0      =   3*rand(N*n,1);
lam0    =   10*(rand(1)-0.5);
rho     =   100;
mu      =   100;
eps     =   1e-4;
Sig     =   {eye(n),eye(n)};

% no termination criterion, stop after maxit
term_eps = 0;

%% solve with ALADIN

emptyfun      = @(x) [];
[ggifun{1:N}] = deal(emptyfun);

% define the optimization set up
% define objective and constraint functions
sProb.locFuns.ffi  = {f1, f2};
sProb.locFuns.ggi  = ggifun;
sProb.locFuns.hhi  = {h1, h2};

% define boundaries
sProb.llbx = {lb1,lb2};
sProb.uubx = {ub1,ub2};

% define counpling matrix
sProb.AA   = {A1,A2};

% define initial values for solutions and lagrange multipliers
sProb.zz0  = {y0(1:2),y0(3:4)};
sProb.lam0 = 10*(rand(1)-0.5);


opts = initializeOpts(rho, mu, maxit, Sig, term_eps);

sol_ALADIN = run_ALADINnew( sProb, opts ); 

                                
%% solve centralized problem with CasADi & IPOPT

y   =   SX.sym('y',[N*n,1]);
F = f1(y_1) + f2(y_2);
g = [h1(y_1); h2(y_2); [A1, A2]*[y_1;y_2]];

% F   =   f1fun(y(1:2))+f2fun(y(3:4));
% g   =   [h1fun(y(1:2));
%          h2fun(y(3:4));
%          [A1, A2]*y];
nlp =   struct('x',[y_1; y_2],'f',F,'g',g);
cas =   nlpsol('solver','ipopt',nlp);
sol =   cas('lbx', [lb1; lb2],...
            'ubx', [ub1; ub2],...
            'lbg', [-inf;-inf;b], ...
            'ubg', [0;0;b]);  
        
        
%% plotting
% set(0,'defaulttextInterpreter','latex')
% figure(2)
% hold on
% plot(loggAL.X')
% hold on
% plot(maxit,full(sol.x),'ob')
% xlabel('$k$');
% ylabel('$x^k$');

 