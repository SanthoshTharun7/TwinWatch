%% =========================================================================
%  BUILD_CYBER_RESILIENT_SIMULINK.M
%  Constructs the complete Cyber-Resilient PV Simulink Model (.slx)
%  with Interactive Live Visual Block Diagram Feedback!
%  =========================================================================
%  Visual Features on Canvas:
%    - Live Digital Display Readouts on Canvas:
%        * Injected Attack Bias (V)
%        * Compromised Sensor Reading (V)
%        * Observer Lie-Detector Residual (V)
%        * Anomaly Alarm Status (0 = Clear, 1 = ATTACK DETECTED)
%        * Mitigated Controller Feedback (V)
%        * True Physical DC-Link Voltage (V)
%    - Interactive Double-Click Manual Switches:
%        * Attack_ON_OFF_Switch: Toggle Baseline (No Attack) vs Cyber Attack
%        * Attack_Type_Selector: Toggle Ramp FDIA (+25V) vs Replay Attack (-20V)
%    - Distinct Functional Color Coding:
%        * RED     : Cyber Attacks & Injected Summing Node
%        * CYAN    : Physical DC-Link Capacitor Plant (500V)
%        * GREEN   : Luenberger State Observer
%        * YELLOW  : 3-Sigma Anomaly Comparator
%        * MAGENTA : Bumpless Mitigation Switch (Virtual Sensor Handover)
%        * BLUE    : Voltage Stabilizing Controller
%        * WHITE   : Real-Time Digital Meter Displays
%  =========================================================================

function modelName = build_cyber_resilient_simulink()
    fprintf('\n=================================================================\n');
    fprintf('  BUILDING VISUAL CYBER-RESILIENT SIMULINK MODEL: PV_Cyber_Resilient_MVP.slx\n');
    fprintf('=================================================================\n\n');

    modelName = 'PV_Cyber_Resilient_MVP';

    % Close existing instance if loaded (stop simulation first if stuck)
    if bdIsLoaded(modelName)
        try
            set_param(modelName, 'SimulationCommand', 'stop');
        catch
        end
        close_system(modelName, 0);
    end

    % Create new Simulink model
    new_system(modelName);

    % Solver settings: Fixed-step solver (ultra-fast, eliminates chattering)
    set_param(modelName, 'SolverType', 'Fixed-step', 'Solver', 'ode3', 'FixedStep', '0.001');
    set_param(modelName, 'StopTime', '6.0');

    fprintf('[1/4] Adding color-coded blocks and digital meters to canvas...\n');

    % ---------------------------------------------------------------------
    % 1. PHYSICAL PLANT: DC-Link Capacitor (Cyan)
    % ---------------------------------------------------------------------
    add_block('simulink/Sources/Constant', [modelName, '/Vdc_Nominal_500V'], ...
              'Value', '500', 'Position', [40, 80, 100, 110], ...
              'BackgroundColor', 'cyan', 'FontWeight', 'bold');

    add_block('simulink/Continuous/Transfer Fcn', [modelName, '/DC_Link_Plant'], ...
              'Numerator', '[200]', 'Denominator', '[1 80]', ...
              'Position', [140, 130, 230, 180], ...
              'BackgroundColor', 'cyan', 'FontWeight', 'bold');

    add_block('simulink/Math Operations/Sum', [modelName, '/True_Vdc_Sum'], ...
              'Inputs', '++', 'Position', [270, 85, 300, 135], ...
              'BackgroundColor', 'cyan');

    % Canvas Display 1: True Physical Voltage
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_True_Plant_Vdc'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [340, 35, 430, 65], ...
              'BackgroundColor', 'white', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 2. ATTACK INJECTION SUBSYSTEM (Red / Coral)
    % ---------------------------------------------------------------------
    % Attack Option A: Baseline 0V (No Attack)
    add_block('simulink/Sources/Constant', [modelName, '/Attack_None_0V'], ...
              'Value', '0', 'Position', [40, 230, 90, 260], ...
              'BackgroundColor', 'white');

    % Attack Option B: Ramp FDIA (+15 V/s up to +25V)
    add_block('simulink/Sources/Ramp', [modelName, '/Attack_Ramp'], ...
              'slope', '15', 'start', '2.0', 'X0', '0', ...
              'Position', [40, 290, 90, 320], ...
              'BackgroundColor', 'red', 'ForegroundColor', 'white');
    add_block('simulink/Discontinuities/Saturation', [modelName, '/Attack_Cap'], ...
              'UpperLimit', '25', 'LowerLimit', '0', ...
              'Position', [120, 290, 160, 320], ...
              'BackgroundColor', 'red', 'ForegroundColor', 'white');

    % Attack Option C: Replay Attack (Recorded -20V Drop at t=2s)
    add_block('simulink/Sources/Step', [modelName, '/Attack_Replay'], ...
              'Time', '2.0', 'Before', '0', 'After', '-20.0', ...
              'Position', [40, 350, 90, 380], ...
              'BackgroundColor', 'red', 'ForegroundColor', 'white');

    % Manual Switch 1: Toggle Ramp FDIA vs Replay Attack
    add_block('simulink/Signal Routing/Manual Switch', [modelName, '/Attack_Type_Selector'], ...
              'Position', [200, 300, 230, 360], ...
              'BackgroundColor', 'red', 'ForegroundColor', 'white', 'FontWeight', 'bold');

    % Manual Switch 2: Toggle Baseline (No Attack) vs Cyber Attack
    add_block('simulink/Signal Routing/Manual Switch', [modelName, '/Attack_ON_OFF_Switch'], ...
              'Position', [270, 245, 300, 305], ...
              'BackgroundColor', 'yellow', 'FontWeight', 'bold');

    % Canvas Display 2: Live Injected Bias Voltage
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_Injected_Bias_V'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [340, 215, 430, 245], ...
              'BackgroundColor', 'white', 'FontWeight', 'bold');

    % Sensor Summing Node: Injects attack onto measurement wire
    add_block('simulink/Math Operations/Sum', [modelName, '/Sensor_Attack_Sum'], ...
              'Inputs', '++', 'Position', [470, 100, 500, 150], ...
              'BackgroundColor', 'yellow', 'FontWeight', 'bold');

    % Canvas Display 3: Compromised Sensor Reading
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_Sensor_Reading_V'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [530, 45, 620, 75], ...
              'BackgroundColor', 'white', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 3. LUENBERGER OBSERVER SUBSYSTEM (Green)
    % ---------------------------------------------------------------------
    add_block('simulink/Continuous/Transfer Fcn', [modelName, '/Observer_Predictor'], ...
              'Numerator', '[200]', 'Denominator', '[1 80]', ...
              'Position', [570, 250, 670, 300], ...
              'BackgroundColor', 'green', 'ForegroundColor', 'white', 'FontWeight', 'bold');

    add_block('simulink/Math Operations/Sum', [modelName, '/Observer_State_Sum'], ...
              'Inputs', '++', 'Position', [710, 255, 740, 305], ...
              'BackgroundColor', 'green', 'ForegroundColor', 'white');

    % Residual Calculation: r = y_sensor - V_hat
    add_block('simulink/Math Operations/Sum', [modelName, '/Residual_Sum'], ...
              'Inputs', '+-', 'Position', [570, 145, 600, 195], ...
              'BackgroundColor', 'green');
    add_block('simulink/Math Operations/Abs', [modelName, '/Abs_Residual'], ...
              'Position', [630, 155, 660, 185], ...
              'BackgroundColor', 'green');

    % Canvas Display 4: Live Observer Residual
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_Observer_Residual_V'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [690, 195, 780, 225], ...
              'BackgroundColor', 'white', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 4. 3-SIGMA ANOMALY COMPARATOR & ALARM (Yellow / Red)
    % ---------------------------------------------------------------------
    add_block('simulink/Logic and Bit Operations/Compare To Constant', [modelName, '/Threshold_3Sigma'], ...
              'relop', '>', 'const', '2.5', ...
              'ZeroCross', 'off', ...
              'Position', [700, 150, 770, 180], ...
              'BackgroundColor', 'yellow', 'FontWeight', 'bold');

    % Canvas Display 5: Alarm Status (0 = Clear, 1 = ATTACK DETECTED)
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_ALARM_0_Clear_1_TRIP'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [800, 95, 880, 125], ...
              'BackgroundColor', 'red', 'ForegroundColor', 'white', 'FontWeight', 'bold');

    % Manual Switch 3: Defense Enable / Bypass Switch (sw=0 Defended, sw=1 Bypassed)
    add_block('simulink/Sources/Constant', [modelName, '/Defense_Bypass_0'], ...
              'Value', '0', 'Position', [770, 205, 800, 235], ...
              'BackgroundColor', 'white');
    add_block('simulink/Signal Routing/Manual Switch', [modelName, '/Defense_Mode_Switch'], ...
              'Position', [830, 155, 860, 215], ...
              'BackgroundColor', 'magenta', 'ForegroundColor', 'white', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 5. BUMPLESS MITIGATION SWITCH (Magenta)
    % ---------------------------------------------------------------------
    add_block('simulink/Signal Routing/Switch', [modelName, '/Mitigation_Switch'], ...
              'Criteria', 'u2 ~= 0', ...
              'ZeroCross', 'off', ...
              'Position', [900, 135, 950, 195], ...
              'BackgroundColor', 'magenta', 'ForegroundColor', 'white', 'FontWeight', 'bold');

    % Canvas Display 6: Mitigated Controller Feedback
    add_block('simulink/Sinks/Display', [modelName, '/DISPLAY_Safe_Mitigated_V'], ...
              'Format', 'short', 'Decimation', '10', ...
              'Position', [980, 85, 1070, 115], ...
              'BackgroundColor', 'white', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 6. VOLTAGE CONTROLLER (Light Blue / Orange)
    % ---------------------------------------------------------------------
    add_block('simulink/Math Operations/Sum', [modelName, '/Error_Sum'], ...
              'Inputs', '-+', 'Position', [990, 145, 1020, 185], ...
              'BackgroundColor', 'lightBlue');
    add_block('simulink/Math Operations/Gain', [modelName, '/Controller_Gain'], ...
              'Gain', '-0.32', 'Position', [1050, 150, 1120, 180], ...
              'BackgroundColor', 'orange', 'FontWeight', 'bold');

    % ---------------------------------------------------------------------
    % 7. SCOPES & MUX
    % ---------------------------------------------------------------------
    add_block('simulink/Signal Routing/Mux', [modelName, '/Mux_Voltages'], ...
              'Inputs', '3', 'Position', [940, 20, 950, 70]);

    add_block('simulink/Sinks/Scope', [modelName, '/Scope_DC_Voltage_Comparison'], ...
              'Position', [990, 25, 1030, 65]);
    add_block('simulink/Sinks/Scope', [modelName, '/Scope_Residual_and_Alarm'], ...
              'NumInputPorts', '2', 'Position', [900, 250, 940, 310]);

    fprintf('[2/4] Connecting wires and feedback loops...\n');

    % Physical Plant connections
    add_line(modelName, 'Vdc_Nominal_500V/1', 'True_Vdc_Sum/1', 'autorouting', 'on');
    add_line(modelName, 'DC_Link_Plant/1', 'True_Vdc_Sum/2', 'autorouting', 'on');
    add_line(modelName, 'True_Vdc_Sum/1', 'DISPLAY_True_Plant_Vdc/1', 'autorouting', 'on');
    add_line(modelName, 'True_Vdc_Sum/1', 'Sensor_Attack_Sum/1', 'autorouting', 'on');
    add_line(modelName, 'True_Vdc_Sum/1', 'Mux_Voltages/1', 'autorouting', 'on');

    % Attack Generator routing
    add_line(modelName, 'Attack_Ramp/1', 'Attack_Cap/1', 'autorouting', 'on');
    add_line(modelName, 'Attack_Cap/1', 'Attack_Type_Selector/1', 'autorouting', 'on');
    add_line(modelName, 'Attack_Replay/1', 'Attack_Type_Selector/2', 'autorouting', 'on');

    add_line(modelName, 'Attack_None_0V/1', 'Attack_ON_OFF_Switch/1', 'autorouting', 'on');
    add_line(modelName, 'Attack_Type_Selector/1', 'Attack_ON_OFF_Switch/2', 'autorouting', 'on');

    % Selected Attack -> Injected bias wire & live display
    add_line(modelName, 'Attack_ON_OFF_Switch/1', 'Sensor_Attack_Sum/2', 'autorouting', 'on');
    add_line(modelName, 'Attack_ON_OFF_Switch/1', 'DISPLAY_Injected_Bias_V/1', 'autorouting', 'on');

    % Compromised Sensor Wire & live display
    add_line(modelName, 'Sensor_Attack_Sum/1', 'DISPLAY_Sensor_Reading_V/1', 'autorouting', 'on');
    add_line(modelName, 'Sensor_Attack_Sum/1', 'Mitigation_Switch/3', 'autorouting', 'on');
    add_line(modelName, 'Sensor_Attack_Sum/1', 'Residual_Sum/1', 'autorouting', 'on');
    add_line(modelName, 'Sensor_Attack_Sum/1', 'Mux_Voltages/2', 'autorouting', 'on');

    % Observer State Prediction & Virtual Wire
    add_line(modelName, 'Vdc_Nominal_500V/1', 'Observer_State_Sum/1', 'autorouting', 'on');
    add_line(modelName, 'Observer_Predictor/1', 'Observer_State_Sum/2', 'autorouting', 'on');
    add_line(modelName, 'Observer_State_Sum/1', 'Residual_Sum/2', 'autorouting', 'on');
    add_line(modelName, 'Observer_State_Sum/1', 'Mitigation_Switch/1', 'autorouting', 'on');

    % Residual Lie Detector & live display
    add_line(modelName, 'Residual_Sum/1', 'Abs_Residual/1', 'autorouting', 'on');
    add_line(modelName, 'Abs_Residual/1', 'Threshold_3Sigma/1', 'autorouting', 'on');
    add_line(modelName, 'Abs_Residual/1', 'DISPLAY_Observer_Residual_V/1', 'autorouting', 'on');
    add_line(modelName, 'Abs_Residual/1', 'Scope_Residual_and_Alarm/1', 'autorouting', 'on');

    % 3-Sigma Alarm Flag -> Defense Mode Switch -> Mitigation Switch & displays
    add_line(modelName, 'Threshold_3Sigma/1', 'Defense_Mode_Switch/1', 'autorouting', 'on');
    add_line(modelName, 'Defense_Bypass_0/1', 'Defense_Mode_Switch/2', 'autorouting', 'on');

    add_line(modelName, 'Defense_Mode_Switch/1', 'Mitigation_Switch/2', 'autorouting', 'on');
    add_line(modelName, 'Defense_Mode_Switch/1', 'DISPLAY_ALARM_0_Clear_1_TRIP/1', 'autorouting', 'on');
    add_line(modelName, 'Defense_Mode_Switch/1', 'Scope_Residual_and_Alarm/2', 'autorouting', 'on');

    % Mitigation Switch Output & live display
    add_line(modelName, 'Mitigation_Switch/1', 'DISPLAY_Safe_Mitigated_V/1', 'autorouting', 'on');
    add_line(modelName, 'Mitigation_Switch/1', 'Error_Sum/2', 'autorouting', 'on');
    add_line(modelName, 'Mitigation_Switch/1', 'Mux_Voltages/3', 'autorouting', 'on');

    % Controller Feedback Loop
    add_line(modelName, 'Vdc_Nominal_500V/1', 'Error_Sum/1', 'autorouting', 'on');
    add_line(modelName, 'Error_Sum/1', 'Controller_Gain/1', 'autorouting', 'on');
    add_line(modelName, 'Controller_Gain/1', 'DC_Link_Plant/1', 'autorouting', 'on');
    add_line(modelName, 'Controller_Gain/1', 'Observer_Predictor/1', 'autorouting', 'on');

    % Mux to Scope
    add_line(modelName, 'Mux_Voltages/1', 'Scope_DC_Voltage_Comparison/1', 'autorouting', 'on');

    fprintf('[3/4] Saving model file: %s.slx...\n', modelName);
    save_system(modelName, [modelName, '.slx']);

    fprintf('[4/4] Opening visual model diagram in Simulink...\n');
    open_system(modelName);
    open_system([modelName, '/Scope_DC_Voltage_Comparison']);
    open_system([modelName, '/Scope_Residual_and_Alarm']);

    fprintf('\n=================================================================\n');
    fprintf('  [+] SUCCESS! VISUAL SIMULINK MODEL READY: %s.slx\n', modelName);
    fprintf('=================================================================\n');
    fprintf('  🎮 VISUAL CONTROLS ON CANVAS:\n');
    fprintf('  1. Attack_ON_OFF_Switch : Double-click to toggle Baseline vs Attack.\n');
    fprintf('  2. Attack_Type_Selector : Double-click to toggle Ramp FDIA vs Replay Attack.\n');
    fprintf('  3. 6 Live Displays      : Watch voltage, bias, residual & alarm update live!\n');
    fprintf('=================================================================\n\n');
end
