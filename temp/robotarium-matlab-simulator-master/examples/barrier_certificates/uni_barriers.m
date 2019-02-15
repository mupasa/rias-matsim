%% Barrier certificates for unicycle-modeled systems
%Paul Glotfelter 
%3/24/2016

%% Set up Robotarium object

N = 12;
r = Robotarium('NumberOfRobots', N, 'ShowFigure', true);

%Run the simulation for a specific number of iterations
iterations = 2000;

%% Set up constants for experiments

% Initialize velocity vector for agents.  Each agent expects a 2 x 1
% velocity vector containing the linear and angular velocity, respectively.
dx = zeros(2, N);

% This code ensures that the agents are initially distributed around an
% ellipse.  
xybound = 0.8*[-1, 1, -1, 1];
p_theta = (1:2:2*N)/(2*N)*2*pi;
p_circ = [xybound(2)*cos(p_theta) xybound(2)*cos(p_theta+pi); xybound(4)*sin(p_theta)  xybound(4)*sin(p_theta+pi)];

x_goal = p_circ(:,1:N);

flag = 0; %flag of task completion

lambda = 0.05;
safety = 1.5*r.robot_diameter;

%% Tools to map single-integrator -> unicycle

% Get the tools we need to map from single-integrator
[si_to_uni_dyn, uni_to_si_states] = create_si_to_uni_mapping('ProjectionDistance', lambda);

% Grab barrier certificates for unicycle dynamics
uni_barrier_cert = create_uni_barrier_certificate('SafetyRadius', safety, 'ProjectionDistance', lambda);

% Grab a position controller for single-integrator systems
si_pos_controller = create_si_position_controller();

%Iterate for the previously specified number of iterations
for t = 1:iterations
    
    % Retrieve the most recent poses from the Robotarium.  The time delay is
    % approximately 0.033 seconds
    x = r.get_poses();
    
    %% Algorithm
  
    % Check if we've reached our destination on the ellipse
    if norm(x_goal-x(1:2, :),1)<0.1
         flag = 1-flag;
    end
    
    % Switch positions on the ellipse
    if flag == 0
        x_goal = p_circ(:,1:N);
    else
        x_goal = p_circ(:,N+1:2*N);
    end
    
    % Convert to single-integrator domain 
    x_int = uni_to_si_states(x);
    
    %Currently in integrator dynamics
    dx = si_pos_controller(x_int, x_goal);
    
    % Threshold velocities for safety
    dxmax = 0.1;
    for i = 1:N
        if norm(dx(:,i)) > dxmax
            dx(:,i) = dx(:,i)/norm(dx(:,i))*dxmax;
        end
    end
    
    % Map to unicycle dynamics
    dx = si_to_uni_dyn(dx, x);    
    
    %Ensure the robots don't collide
    dx = uni_barrier_cert(dx, x);    
    
    % Set velocities of agents 1,...,N
    r.set_velocities(1:N, dx);
    
    % Send the previously set velocities to the agents.  This function must be called!
    r.step();
    
end

% We can call this function to debug our experiment!  Fix all the errors
% before submitting to maximize the chance that your experiment runs
% successfully.
r.debug();
