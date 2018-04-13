function [m, Ib, pdotdot, wbdot, Op1, Op2, Op3, Op4] = Quadcopter_tilted_arms_dynamic(kf, km, wRb, alpha, beta, theta,n, L, g, Mb, Mp, R, gravitiy)
%[m, Ib,pdotdot, wbdot] = Quadcopter_tilted_arms_dynamic(kf, km, wRb, alpha, beta, theta,n, L, g, Mb, Mp, R, gravitiy)
%QUADROTOR_TILTED_ARMS_DYNAMIC returns the dynamic of a quadcopter with tilting
%propeller and tilted arms
%propellers. Returns the linear and angular acceleration of the drone, its inertia tensor and mass.

%% Calculate the rotation matrix from the body frame of the drone to the body frame of the propeller
bRp1 = rotz(rad2deg(theta(1)))*roty(rad2deg(beta(1)))*rotx(rad2deg(alpha(1)));
bRp2 = rotz(rad2deg(pi/2+theta(2)))*roty(rad2deg(beta(2)))*rotx(rad2deg(alpha(2)));
bRp3 = rotz(rad2deg(pi+theta(3)))*roty(rad2deg(beta(3)))*rotx(rad2deg(alpha(3)));
bRp4 = rotz(rad2deg(3*pi/2+theta(4)))*roty(rad2deg(beta(4)))*rotx(rad2deg(alpha(4)));
%% Calculate the position of each propeller in the body frame
Op1 = rotz(rad2deg(theta(1)))*roty(rad2deg(beta(1)))*[L 0 0].';
Op2 = rotz(rad2deg(pi/2+theta(2)))*roty(rad2deg(beta(2)))*[L 0 0].';
Op3 = rotz(rad2deg(pi+theta(3)))*roty(rad2deg(beta(3)))*[L 0 0].';
Op4 = rotz(rad2deg(3*pi/2+theta(4)))*roty(rad2deg(beta(4)))*[L 0 0].';

%% Drone inertia
m = Mb + 4*Mp; % Mass total of the drone
Icom = 2/5*Mb*R*R*eye(3); % Inertia tensor of a sphere
% Inertia tensor of a sphere with rotors represented as point masses
Ip = Mp*(norm(Op1)^2*eye(3) - Op1*Op1.' + norm(Op2)^2*eye(3) - Op2*Op2.' + ...
     norm(Op3)^2*eye(3) - Op3*Op3.' + norm(Op4)^2*eye(3) - Op4*Op4.');% Inertia tensor of rotors (point masses)
Ib = Icom+ Ip; % Inertia tensor of the drone (sphere with 4 point masses)

%% take gravity into account?
if gravitiy
    f = [0 0 -g].'; % gravity
else
    f = [0 0 0].';
end
%% Propellers thrusts in the propellers frames
Tp1 = [0 0 kf*n(1)^2].'; % Thrust vector propeller 1
Tp2 = [0 0 kf*n(2)^2].'; % Thrust vector propeller 2
Tp3 = [0 0 kf*n(3)^2].'; % Thrust vector propeller 3
Tp4 = [0 0 kf*n(4)^2].'; % Thrust vector propeller 4
%% Propellers counter torques in the propellers frame
Tauext1 = [0 0 -km*n(1)^2].'; % Thrust vector propeller 1
Tauext2 = [0 0 km*n(2)^2].'; % Thrust vector propeller 2
Tauext3 = [0 0 -km*n(3)^2].'; % Thrust vector propeller 3
Tauext4 = [0 0 km*n(4)^2].'; % Thrust vector propeller 4
%% Calculate forces and torques applied to the drone cog 
Taub = cross(Op1,bRp1*Tp1) + cross(Op2,bRp2*Tp2) + cross(Op3,bRp3*Tp3) + cross(Op4,bRp4*Tp4); % Torques applied to the drone by the propeller thrusts
M = (bRp1*Tauext1 + bRp2*Tauext2 + bRp3*Tauext3 + bRp4*Tauext4 + Taub); % propellers counter torques applied to the body frame
wbdot = Ib\M; % angular acceleration

T = wRb*(bRp1*Tp1 + bRp2*Tp2 + bRp3*Tp3 + bRp4*Tp4); % Thrusts in the body frame
pdotdot = f + (1/m)*T; % linear acceleration

%% Round the linear and angular accelerations befor returning them.
Ndecimals = 8;
k = 10.^Ndecimals;
pdotdot = round(k*pdotdot)/k;
wbdot = round(k*wbdot)/k;

%% Validation test 
% T1 = kf*(sin(alpha(1))*sin(theta(1)) + cos(alpha(1))*sin(beta(1))*cos(theta(1)))*n(1)^2 ...
%        + kf*(sin(alpha(2))*cos(theta(2)) - cos(alpha(2))*sin(beta(2))*sin(theta(2)))*n(2)^2 ...
%        - kf*(sin(alpha(3))*sin(theta(3)) + cos(alpha(3))*sin(beta(3))*cos(theta(3)))*n(3)^2 ...
%        - kf*(sin(alpha(4))*cos(theta(4)) - cos(alpha(4))*sin(beta(4))*sin(theta(4)))*n(4)^2;
% 
% T2 = - kf*(sin(alpha(1))*cos(theta(1)) - cos(alpha(1))*sin(beta(1))*sin(theta(1)))*n(1)^2 ...
%        + kf*(sin(alpha(2))*sin(theta(2)) + cos(alpha(2))*sin(beta(2))*cos(theta(2)))*n(2)^2 ...
%        + kf*(sin(alpha(3))*(cos(theta(3))) - cos(alpha(3))*sin(beta(3))*sin(theta(3)))*n(3)^2 ...
%        - kf*(sin(alpha(4))*sin(theta(4)) + cos(alpha(4))*sin(beta(4))*cos(theta(4)))*n(4)^2;
% T3 = kf*cos(alpha(1))*cos(beta(1))*n(1)^2 + kf*cos(alpha(2))*cos(beta(2))*n(2)^2 ...
%        + kf*cos(alpha(3))*cos(beta(3))*n(3)^2+ kf*cos(alpha(4))*cos(beta(4))*n(4)^2;
% T1 = [T1;T2;T3];
% Ndecimals = 4;
% k = 10.^Ndecimals;
% T = round(k*T)/k
% T1 = round(k*T1)/k
% isegal = isequal(T, T1)
% Taub1 = - L*kf*n(1)^2*(sin(beta(1))*sin(alpha(1))*cos(theta(1)) - cos(alpha(1))*sin(theta(1))) ...
%           + L*kf*n(2)^2*(sin(beta(2))*sin(alpha(2))* sin(theta(2)) + cos(alpha(2))*cos(theta(2))) ...
%           + L*kf*n(3)^2*(sin(beta(3))*sin(alpha(3))*cos(theta(3)) - cos(alpha(3))* sin(theta(3))) ...
%           - L*kf*n(4)^2*(sin(beta(4))*sin(alpha(4))*sin(theta(4)) + cos(alpha(4))*cos(theta(4)));
% Taub2 = - L*kf*n(1)^2*(sin(beta(1))*sin(alpha(1))*sin(theta(1)) + cos(alpha(1))*cos(theta(1))) ...
%           - L*kf*n(2)^2*(sin(beta(2))*sin(alpha(2))*cos(theta(2)) - cos(alpha(2))* sin(theta(2))) ...
%           + L*kf*n(3)^2*(sin(beta(3))*sin(alpha(3))* sin(theta(3)) + cos(alpha(3))*cos(theta(3))) ...
%           + L*kf*n(4)^2*(sin(beta(4))*sin(alpha(4))*cos(theta(4)) - cos(alpha(4))*sin(theta(4)));
% Taub3 = - L*kf*n(1)^2*cos(beta(1))*sin(alpha(1)) ...
%           - L*kf*n(2)^2*cos(beta(2))*sin(alpha(2)) ...
%           - L*kf*n(3)^2*cos(beta(3))*sin(alpha(3)) ...
%           - L*kf*n(4)^2*cos(beta(4))*sin(alpha(4));
% M1 = -km*(sin(alpha(1))*sin(theta(1)) + cos(alpha(1))*sin(beta(1))*cos(theta(1)))*n(1)^2 ...
%        + km*(sin(alpha(2))*(cos(theta(2))) - cos(alpha(2))*sin(beta(2))*sin(theta(2)))*n(2)^2 ...
%        + km*(sin(alpha(3))*sin(theta(3)) + cos(alpha(3))*sin(beta(3))*cos(theta(3)))*n(3)^2 ...
%        - km*(sin(alpha(4))*(cos(theta(4))) - cos(alpha(4))*sin(beta(4))*sin(theta(4)))*n(4)^2;
% M2 = + km*(sin(alpha(1))*cos(theta(1)) - cos(alpha(1))*sin(beta(1))*sin(theta(1)))*n(1)^2 ...
%      + km*(sin(alpha(2))*sin(theta(2)) + cos(alpha(2))*sin(beta(2))*(cos(theta(2))))*n(2)^2 ...
%        - km*(sin(alpha(3))*cos(theta(3)) - cos(alpha(3))*sin(beta(3))*sin(theta(3)))*n(3)^2 ...
%        - km*(sin(alpha(4))*sin(theta(4)) + cos(alpha(4))*sin(beta(4))*cos(theta(4)))*n(4)^2;
% M3 = -km*cos(alpha(1))*cos(beta(1))*n(1)^2 + km*cos(alpha(2))*cos(beta(2))*n(2)^2 ...
%        - km*cos(alpha(3))*cos(beta(3))*n(3)^2 + km*cos(alpha(4))*cos(beta(4))*n(4)^2;
% M1 = [M1+Taub1; M2+Taub2; M3+Taub3];
% 
% A_M_static =[L*sin(theta(1))-km*sin(beta(1))*cos(theta(1))/kf, -L*sin(beta(1))*cos(theta(1))-km*sin(theta(1))/kf, ...
%              L*cos(theta(2))-km*sin(beta(2))*sin(theta(2))/kf, L*sin(beta(2))*sin(theta(2))+km*cos(theta(2))/kf, ...
%              -L*sin(theta(3))+km*sin(beta(3))*cos(theta(3))/kf, L*sin(beta(3))*cos(theta(3))+km*sin(theta(3))/kf, ...
%              -L*cos(theta(4))-km*sin(beta(4))*sin(theta(4))/kf, -L*sin(beta(4))*sin(theta(4))-km*cos(theta(4))/kf; ...
%              -L*cos(theta(1))-km*sin(beta(1))*sin(theta(1))/kf, -L*sin(beta(1))*sin(theta(1))+km*cos(theta(1))/kf, ...
%              L*sin(theta(2))+km*sin(beta(2))*cos(theta(2))/kf, -L*sin(beta(2))*cos(theta(2))+km*sin(theta(2))/kf, ...
%              L*cos(theta(3))+km*sin(beta(3))*sin(theta(3))/kf, L*sin(beta(3))*sin(theta(3))-km*cos(theta(3))/kf, ...
%              -L*sin(theta(4))-km*sin(beta(4))*cos(theta(4))/kf, L*sin(beta(4))*cos(theta(4))-km*sin(theta(4))/kf; ...
%              -km*cos(beta(1))/kf, -L*cos(beta(1)), km*cos(beta(2))/kf, -L*cos(beta(2)), -km*cos(beta(3))/kf, ...
%              -L*cos(beta(3)), km*cos(beta(4))/kf, -L*cos(beta(4))];
% Fdec = [kf*cos(alpha(1))*n(1)^2; kf*sin(alpha(1))*n(1)^2; kf*cos(alpha(2))*n(2)^2; 
%         kf*sin(alpha(2))*n(2)^2; kf*cos(alpha(3))*n(3)^2; kf*sin(alpha(3))*n(3)^2; 
%         kf*cos(alpha(4))*n(4)^2; kf*sin(alpha(4))*n(4)^2];
% 
% M2 = A_M_static*Fdec;
% Ndecimals = 4;
% k = 10.^Ndecimals;
% M = round(k*M)/k
% M1 = round(k*M1)/k
% M2 = round(k*M2)/k
end