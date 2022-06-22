tic;
%% Clear cache

clear
clc
close all

%% Define parameters

disp('Defining parameters.')
load_switch = 11;
PV_fail = 5;

%% Import Earth irradiance and temperature data
disp('Importing Earth irradiance and temperature data.')

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Time", "Irradiance", "Temp"];
opts.VariableTypes = ["double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
tbl = readtable("data\earth_irradiance_temp_stable.csv", opts);

% Convert to output type
Time = tbl.Time;
Irradiance = tbl.Irradiance;
Temp = tbl.Temp;

% Save as variables for plot
time_cond = Time;
irr_E = Irradiance;
temp_E = Temp;

%% Run models with Earth conditions and save data
disp('Running models with Earth conditions:')

disp('Running base model.')
sim('models\base_model.slx','StartTime','0','StopTime','1');
time = ans.ScopeData.time(101:end);
vpv_base_E = ans.ScopeData.signals(1).values(101:end);
ppv_base_E = ans.ScopeData.signals(2).values(101:end);
vload_base_E = ans.ScopeData.signals(4).values(101:end);

disp('Running Scenario 1.')
sim('models\half_PV_fail.slx','StartTime','0','StopTime','1')
vpv_1E = ans.ScopeData1.signals(1).values(101:end);
ppv_1E = ans.ScopeData1.signals(2).values(101:end);
vload_1E = ans.ScopeData1.signals(4).values(101:end);

disp('Running Scenario 2.')
sim('models\PV_fault.slx','StartTime','0','StopTime','1')
vpv_2E = ans.ScopeData2.signals(1).values(101:end);
ppv_2E = ans.ScopeData2.signals(2).values(101:end);
vload_2E = ans.ScopeData2.signals(4).values(101:end);

disp('Running Scenario 3.')
sim('models\load_fault.slx','StartTime','0','StopTime','1')
vpv_3E = ans.ScopeData3.signals(1).values(101:end);
ppv_3E = ans.ScopeData3.signals(2).values(101:end);
vload_3E = ans.ScopeData3.signals(4).values(101:end);

clear opts tbl

%% Import Lunar irradiance and temperature data
disp('Importing Lunar irradiance and temperature data.')

% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 3);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = ",";

% Specify column names and types
opts.VariableNames = ["Time", "Irradiance", "Temp"];
opts.VariableTypes = ["double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Import the data
tbl = readtable("data\lunar_irradiance_temp_moderate.csv", opts);

% Convert to output type
Time = tbl.Time;
Irradiance = tbl.Irradiance;
Temp = tbl.Temp;

% save as variables for plot
time_cond = Time;
irr_L = Irradiance;
temp_L = Temp;

%% Run models with Lunar conditions
disp('Running models with Lunar conditions:')

disp('Running base model.')
sim('models\base_model.slx','StartTime','0','StopTime','1');
vpv_base_L = ans.ScopeData.signals(1).values(101:end);
ppv_base_L = ans.ScopeData.signals(2).values(101:end);
vload_base_L = ans.ScopeData.signals(4).values(101:end);

disp('Running Scenario 1.')
sim('models\half_PV_fail.slx','StartTime','0','StopTime','1')
vpv_1L = ans.ScopeData1.signals(1).values(101:end);
ppv_1L = ans.ScopeData1.signals(2).values(101:end);
vload_1L = ans.ScopeData1.signals(4).values(101:end);

disp('Running Scenario 2.')
sim('models\PV_fault.slx','StartTime','0','StopTime','1')
vpv_2L = ans.ScopeData2.signals(1).values(101:end);
ppv_2L = ans.ScopeData2.signals(2).values(101:end);
vload_2L = ans.ScopeData2.signals(4).values(101:end);

disp('Running Scenario 3.')
sim('models\load_fault.slx','StartTime','0','StopTime','1')
vpv_3L = ans.ScopeData3.signals(1).values(101:end);
ppv_3L = ans.ScopeData3.signals(2).values(101:end);
vload_3L = ans.ScopeData3.signals(4).values(101:end);

clear opts tbl

%% Delete contents of plots folder
disp('Deleting old plots.')
delete('plots\*.png');

%% PLot temperature and irradiance
disp('Creating plots.')

fig = figure;
p1 = plot(time_cond,temp_E);
hold on
p2 = plot(time_cond,temp_L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([-120,120])
xlabel('Time (seconds)')
ylabel('Temperature (C)')
grid on
title('Temperature')
saveas(gcf, 'plots\temp.png')
close(fig)

fig = figure;
p1 = plot(time_cond,irr_E);
hold on
p2 = plot(time_cond,irr_L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,1500])
xlabel('Time (seconds)')
ylabel('Irradiance (W/m^2)')
grid on
title('Irradiance')
saveas(gcf, 'plots\irr.png')
close(fig)

%% Plot PV Voltage data
fig = figure;
p1 = plot(time,vpv_base_E);
hold on
p2 = plot(time,vpv_base_L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('PV Voltage - Base Model')
saveas(gcf, 'plots\vpvbase.png')
close(fig)

fig = figure;
p1 = plot(time,vpv_1E);
hold on
p2 = plot(time,vpv_1L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('PV Voltage - Loss of Half PV')
saveas(gcf, 'plots\vpv1.png')
close(fig)

fig = figure;
p1 = plot(time,vpv_2E);
hold on
p2 = plot(time,vpv_2L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('PV Voltage - PV Fault')
saveas(gcf, 'plots\vpv2.png')
close(fig)

fig = figure;
p1 = plot(time,vpv_3E);
hold on
p2 = plot(time,vpv_3L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('PV Voltage - Load Fault')
saveas(gcf, 'plots\vpv3.png')
close(fig)

%% Plot PV Power data
fig = figure;
p1 = plot(time,ppv_base_E);
hold on
p2 = plot(time,ppv_base_L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,50000])
xlabel('Time (seconds)')
ylabel('Power (W)')
grid on
title('PV Power - Base Model')
saveas(gcf, 'plots\ppvbase.png')
close(fig)

fig = figure;
p1 = plot(time,ppv_1E);
hold on
p2 = plot(time,ppv_1L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,50000])
xlabel('Time (seconds)')
ylabel('Power (W)')
grid on
title('PV Power - Loss of Half PV')
saveas(gcf, 'plots\ppv1.png')
close(fig)

fig = figure;
p1 = plot(time,ppv_2E);
hold on
p2 = plot(time,ppv_2L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,50000])
xlabel('Time (seconds)')
ylabel('Power (W)')
grid on
title('PV Power - PV Fault')
saveas(gcf, 'plots\ppv2.png')
close(fig)

fig = figure;
p1 = plot(time,ppv_3E);
hold on
p2 = plot(time,ppv_3L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,50000])
xlabel('Time (seconds)')
ylabel('Power (W)')
grid on
title('PV Power - Load Fault')
saveas(gcf, 'plots\ppv3.png')
close(fig)

%% Plot Load Voltage data
fig = figure;
p1 = plot(time,vload_base_E);
hold on
p2 = plot(time,vload_base_L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('Load Voltage - Base Model')
saveas(gcf, 'plots\vloadbase.png')
close(fig)

fig = figure;
p1 = plot(time,vload_1E);
hold on
p2 = plot(time,vload_1L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('Load Voltage - Loss of Half PV')
saveas(gcf, 'plots\vload1.png')
close(fig)

fig = figure;
p1 = plot(time,vload_2E);
hold on
p2 = plot(time,vload_2L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('Load Voltage - PV Fault')
saveas(gcf, 'plots\vload2.png')
close(fig)

fig = figure;
p1 = plot(time,vload_3E);
hold on
p2 = plot(time,vload_3L);
hold off
h = [p1, p2];
legend(h, 'Earth Conditions', 'Lunar Conditions')
ylim([0,500])
xlabel('Time (seconds)')
ylabel('Voltage (V)')
grid on
title('Load Voltage - Load Fault')
saveas(gcf, 'plots\vload3.png')
close(fig)

disp('End of simulation.')

toc
