function resultados = testa_sistema_ise(Kfull2)

set(0,'DefaultFigureWindowStyle','docked') 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Par�metros para o projeto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Kh2=Kfull2;
% Par�metros Rede

Lg_2_min = 0e-3;   % Indut�ncia m�nima da rede
Lg_2_max = 1e-3;   % Indut�ncia m�xima da rede

% Discretiza��o
fs    = 2*10020; %Amostragem na pr�tica 20040 Hz e comuta��o 10020 Hz; 
Ts    = 1/fs;
s     = tf('s'); 
z     = tf('z',Ts);
f_sw  = 10020;         % Freq��ncia de comuta��o
Tsw   = 1/f_sw;        % Per�odo de comuta��o
w_sw  = 2*pi*f_sw;     %

% Par�metros do filtro
Lc   = 1.e-3;        % Indut�ncia do lado do conversor
rc   = 1e-10;       % Resist�ncia s�rie do indutor do conversor
Cap   = 62e-6;       % Capacitor do filtro LCL
Lg_1 = 0.3e-3;      % Indut�ncia m�nima da rede
rg_1 = 1e-10;       % Resist�ncia s�rie do indutor do lado da rede
rg_2 = 0.;          % Resist�ncia equivalente s�rie da rede

Lg_min = Lg_1+Lg_2_min;       % Indut�ncia TOTAL da rede
Lg_max = Lg_1+Lg_2_max;       % Indut�ncia TOTAL da rede
rg = rg_1+rg_2;

%% Espa�o de estados
% PASSO 1
Ap_1 = [-rc/Lc -1/Lc 0; 1/Cap 0 -1/Cap; 0 1/Lg_min -rg/Lg_min];
Ap_2 = [-rc/Lc -1/Lc 0; 1/Cap 0 -1/Cap; 0 1/Lg_max -rg/Lg_max];
Bp   = [1/Lc; 0; 0]; 
Fp_1 = [0; 0; -1/Lg_min]; 
Fp_2 = [0; 0; -1/Lg_max]; 
Cp_g = [0 0 1];  
Dp   = 0;

% Discretiza��o (corrente da rede)

% Discretiza��o ZOH
% PASSO 2
[Ad_1,Bd_1,Cd_g,Dd]   = ssdata(c2d(ss(Ap_1,Bp,Cp_g,Dp),Ts));
[Ad_2,Bd_2,Cd_g,Dd]   = ssdata(c2d(ss(Ap_2,Bp,Cp_g,Dp),Ts));
[Ad_1,Fd_1,Cd_g,Dd]   = ssdata(c2d(ss(Ap_1,Fp_1,Cp_g,Dp),Ts));
[Ad_2,Fd_2,Cd_g,Dd]   = ssdata(c2d(ss(Ap_2,Fp_2,Cp_g,Dp),Ts));

%% CORRENTE DA REDE => Inclus�o do atraso de transporte em espa�o de estados
% PASSO 3
Gd_1     = [Ad_1 Bd_1; 0 0 0 0]; 
Gd_2     = [Ad_2 Bd_2; 0 0 0 0];
Hd       = [0; 0; 0; 1];         
Hd_dist1 = [Fd_1; 0];             
Hd_dist2 = [Fd_2; 0];
Cd_grid  = [Cd_g 0];
Dd       = 0;


%% Controlador ressonante fundamental
% PASSO 4a
w = 2*pi*60;

zeta    = 1*0.0001;
zeta_3a = 1*0.0001;
zeta_5a = 1*0.0001;
zeta_7a = 1*0.0001;

G_res    = s^1/(s^2 + 2*zeta*s + w^2);
G_res_3a = s^1/(s^2 + 2*zeta_3a*s + (3*w)^2);
G_res_5a = s^1/(s^2 + 2*zeta_5a*s + (5*w)^2);
G_res_7a = s^1/(s^2 + 2*zeta_7a*s + (7*w)^2);

% PASSO 4b
G_res_discreto    = c2d(G_res,Ts,'tustin');
G_res_discreto_3a = c2d(G_res_3a,Ts,'tustin');
G_res_discreto_5a = c2d(G_res_5a,Ts,'tustin');
G_res_discreto_7a = c2d(G_res_7a,Ts,'tustin');


% Forma 1: Matlab
% PASSO 4c
[R1,T1,U1,V1] = ssdata(G_res_discreto);
[R3,T3,U3,V3] = ssdata(G_res_discreto_3a);
[R5,T5,U5,V5] = ssdata(G_res_discreto_5a);
[R7,T7,U7,V7] = ssdata(G_res_discreto_7a);

R = [R1 zeros(2,2) zeros(2,2) zeros(2,2);
     zeros(2,2) R3 zeros(2,2) zeros(2,2);
     zeros(2,2) zeros(2,2) R5 zeros(2,2);
     zeros(2,2) zeros(2,2) zeros(2,2) R7];
T = [T1;T3;T5;T7];
U = [U1 U3 U5 U7];
V = V1+V3+V5+V7;


% Ressonante espa�o de estados
% PASSO 5
A_til_1 = [  Gd_1      zeros(4,8);
           -T*Cd_grid      R];
A_til_2 = [  Gd_2      zeros(4,8);
           -T*Cd_grid      R];
B_til = [Hd;
        zeros(8,1)];

Br_til = [zeros(4,1);
         T];
Bdist1_til = [Hd_dist1;zeros(8,1)];
Bdist2_til = [Hd_dist2;zeros(8,1)];

C_til = [Cd_grid zeros(1,8)];



%% Para os dois v�rtices => Hinf => usar se for necess�rio...
%close all, clc

Adi  = [A_til_1 A_til_2];          %Matriz din�mica do sistema (x)
Bdi  = [B_til B_til];              %Matriz de controle  (u)
Edi = [Bdist1_til Bdist2_til];    %Matriz de dist�rbio (vd)           
Br = [Br_til Br_til];             %Matriz de ref (ref) 
Ci = [C_til C_til];               %Matriz de sa�da
D = [0 0];
Di = [0 0];
Dd = [0 0];



%% ---------------------------------------------------------------------------------------------//-------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% H2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MF1h2 = ss(A_til_1 + B_til*Kh2, [Br_til], C_til, 0, Ts ); %ig/iref
MF2h2 = ss(A_til_2 + B_til*Kh2, [Br_til], C_til, 0, Ts ); %ig/iref

MFdu1h2 = ss(A_til_1 + B_til*Kh2, B_til, C_til, 0, Ts ); %ig/u
MFdu2h2 = ss(A_til_2 + B_til*Kh2, B_til, C_til, 0, Ts ); %ig/u

MFdist1h2 = ss(A_til_1 + B_til*Kh2, Bdist1_til, C_til, 0, Ts ); %ig/vd
MFdist2h2 = ss(A_til_2 + B_til*Kh2, Bdist2_til, C_til, 0, Ts ); %ig/vd

MFx1h2 = ss(A_til_1 + B_til*Kh2, A_til_1, C_til, 0, Ts ); %ig/dx
MFx2h2 = ss(A_til_2 + B_til*Kh2, A_til_2, C_til, 0, Ts ); %ig/dx

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simula��o
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

to = 0;
tf1 = 0.3;

t = to:Ts:tf1;       
[n1 n2] = size(t);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Dist�rbio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disturbio = 1*(311)*sin(2*pi*60*t);%+3*sin(2*pi*180*t); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Refer�ncia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%r = 10*sin(2*pi*60*t);%1*(1-exp(-(1/0.1)*t)).*sin(2*pi*60*t);   

for nsample = 1:n2
          
          if (nsample < 2*334)
      	       ref(nsample) = 0;
          end
          if (nsample >= 2*334 && nsample < 4.75*334)
      	       ref(nsample) = 10.*sin(60*2*pi*Ts*nsample);
          end
          if (nsample >= 4.75*334 && nsample < 9*334)
      	       ref(nsample) = -10.*sin(60*2*pi*Ts*nsample);
          end
          if (nsample >= 9*334 && nsample < 13*334)
      	       ref(nsample) = 10.*cos(60*2*pi*Ts*nsample);
          end
          if (nsample >= 13*334)
      	       ref(nsample) = 20.*cos(60*2*pi*Ts*nsample);
          end

end

% Simula��o do sistema

k=1;
k2=1;
x1(12,1)=0;
y1(1)=0;
x2(12,1)=0;
y2(1)=0;
tp(1)=0;

for nsample = 1:n2
    
    disturb(k) = 1*(311)*sin(2*pi*60*k*Ts);
    u1(k)=Kfull2*x1(:,k);
    x1(:,k+1)=A_til_1*x1(:,k)+B_til*u1(k)+Bdist1_til*disturb(k)+Br_til*ref(nsample);
    y1(k)=C_til*x1(:,k);
    k=k+1;
end

for nsample = 1:n2
    u2(k2)=Kfull2*x2(:,k2);
    x2(:,k2+1)=A_til_2*x2(:,k2)+B_til*u2(k2)+Bdist2_til*disturb(k2)+Br_til*ref(nsample);
    y2(k2)=C_til*x2(:,k2);
    k2=k2+1;
end

% Verifica��o da derivada da acao de controle

for nsample = 1:n2-1
    derivada1(nsample) = u1(nsample+1)-u1(nsample);
    derivada2(nsample) = u2(nsample+1)-u2(nsample);
end

max_derivada = max(max(abs(derivada1)),max(abs(derivada2)));

  
   resultados = max_derivada;
  
  

