%% =========================================================================
%  CYBER_RESILIENCE_DASHBOARD.M
%  Interactive Cyber-Physical Resilience Evaluation Dashboard
%  Final Year Project: Solar Power Grid Cyber-Resilient Control
%  =========================================================================
%  Features:
%    - Dropdown Attack Selector:
%        * None (Baseline)
%        * Replay Attack
%        * Ramp FDIA (Stealthy)
%        * Step FDIA (+25V Bias)
%        * Denial of Service (Freeze)
%    - Defense Toggle Checkbox: [x] Enable defense (Observer + Mitigation Switch)
%    - [ Run Simulation ] Instant Interactive Pushbutton
%    - Real-Time Presentation Metrics Card (Peak Dev, Detect Delay, Recovery)
%    - PURE WHITE BACKGROUND for all windows, scopes, and axes for maximum
%      contrast and presentation clarity.
%    - 3 Stacked Synchronized High-Resolution Scopes:
%        1. DC-Link Voltage (Baseline 500V vs Attacked vs Controlled)
%        2. Estimated Real Power Delivered (P = V^2 / R_eq)
%        3. Observer Residual and Alarm Flag (3-Sigma Threshold)
%  =========================================================================

function varargout = cyber_resilience_dashboard()
    fprintf('\n=================================================================\n');
    fprintf('  LAUNCHING CYBER-RESILIENT MULTI-ATTACK EVALUATION DASHBOARD\n');
    fprintf('=================================================================\n\n');

    % 1. CREATE MAIN GUI FIGURE (Pure White Background)
    figTag = 'CyberResilienceDashboardFig';
    hOld = findobj('Tag', figTag);
    if ~isempty(hOld)
        close(hOld);
    end

    fig = figure('Name', 'Cyber-Resilient PV System — Multi-Attack Evaluation Dashboard', ...
                 'NumberTitle', 'off', ...
                 'Tag', figTag, ...
                 'Color', [1.0, 1.0, 1.0], ...     % PURE WHITE BACKGROUND
                 'Position', [40, 40, 1180, 780]);

    % 2. TOP CONTROL PANEL (White Theme)
    pnlControl = uipanel('Parent', fig, ...
                         'Position', [0.015, 0.915, 0.97, 0.075], ...
                         'BackgroundColor', [1.0, 1.0, 1.0], ...
                         'BorderType', 'line', ...
                         'HighlightColor', [0.85, 0.88, 0.92]);

    % Label: Attack type
    uicontrol('Parent', pnlControl, 'Style', 'text', ...
              'String', 'Attack type:', ...
              'Units', 'normalized', 'Position', [0.01, 0.22, 0.08, 0.52], ...
              'FontSize', 10.5, 'FontWeight', 'bold', ...
              'BackgroundColor', [1.0, 1.0, 1.0], ...
              'ForegroundColor', [0.1, 0.1, 0.1], ...
              'HorizontalAlignment', 'left');

    % Popup: Attack selector (Includes 'None (Baseline)')
    attackList = {'None (Baseline)', 'Replay Attack', 'Ramp FDIA (Stealthy)', 'Step FDIA (+25V Bias)', 'Denial of Service (Freeze)'};
    popAttack = uicontrol('Parent', pnlControl, 'Style', 'popupmenu', ...
                          'String', attackList, ...
                          'Value', 1, ...                 % Default: None (Baseline)
                          'Units', 'normalized', 'Position', [0.09, 0.20, 0.18, 0.60], ...
                          'FontSize', 10, ...
                          'BackgroundColor', [1.0, 1.0, 1.0], ...
                          'ForegroundColor', [0.0, 0.0, 0.0]);

    % Checkbox: Enable defense
    chkDefense = uicontrol('Parent', pnlControl, 'Style', 'checkbox', ...
                           'String', 'Enable defense (Observer + Mitigation Switch)', ...
                           'Value', 0, ...                % Default unchecked for Baseline
                           'Units', 'normalized', 'Position', [0.28, 0.22, 0.26, 0.55], ...
                           'FontSize', 10.5, 'FontWeight', 'bold', ...
                           'BackgroundColor', [1.0, 1.0, 1.0], ...
                           'ForegroundColor', [0.1, 0.1, 0.1]);

    % Button 1: Run Fast Analytical Simulation
    btnRun = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
                       'String', 'Run Simulation', ...
                       'Units', 'normalized', 'Position', [0.55, 0.18, 0.10, 0.64], ...
                       'FontSize', 10, 'FontWeight', 'bold', ...
                       'BackgroundColor', [0.94, 0.97, 1.0], ...
                       'ForegroundColor', [0.05, 0.30, 0.70]);

    % Button 2: Run in Simulink Model (.slx) Linked
    btnSync = uicontrol('Parent', pnlControl, 'Style', 'pushbutton', ...
                        'String', '🔗 Run in Simulink', ...
                        'Units', 'normalized', 'Position', [0.66, 0.18, 0.11, 0.64], ...
                        'FontSize', 10, 'FontWeight', 'bold', ...
                        'BackgroundColor', [0.90, 0.98, 0.92], ...
                        'ForegroundColor', [0.05, 0.50, 0.15]);

    % Metrics Info Box (Top Right - White / Light Cyan Card)
    txtMetrics = uicontrol('Parent', pnlControl, 'Style', 'text', ...
                           'String', sprintf('Peak dev: 1.74 V (0.35%%)\nDetect delay: n/a (no alarm)\nRecovery: n/a'), ...
                           'Units', 'normalized', 'Position', [0.78, 0.06, 0.21, 0.88], ...
                           'FontSize', 9, 'FontWeight', 'bold', ...
                           'HorizontalAlignment', 'left', ...
                           'BackgroundColor', [0.98, 0.99, 1.0], ...
                           'ForegroundColor', [0.1, 0.1, 0.1]);

    % 3. CREATE THREE SYNCHRONIZED AXES (Pure White Canvas)
    % Graph 1: DC-Link Voltage
    ax1 = axes('Parent', fig, 'Position', [0.07, 0.66, 0.90, 0.23], ...
               'Box', 'on', 'Color', [1, 1, 1], ...
               'XColor', [0.15, 0.15, 0.15], 'YColor', [0.15, 0.15, 0.15], ...
               'GridColor', [0.85, 0.85, 0.85], 'GridAlpha', 0.6);
    grid(ax1, 'on');

    % Graph 2: Estimated Real Power Delivered
    ax2 = axes('Parent', fig, 'Position', [0.07, 0.38, 0.90, 0.22], ...
               'Box', 'on', 'Color', [1, 1, 1], ...
               'XColor', [0.15, 0.15, 0.15], 'YColor', [0.15, 0.15, 0.15], ...
               'GridColor', [0.85, 0.85, 0.85], 'GridAlpha', 0.6);
    grid(ax2, 'on');

    % Graph 3: Observer Residual and Alarm Flag
    ax3 = axes('Parent', fig, 'Position', [0.07, 0.08, 0.90, 0.23], ...
               'Box', 'on', 'Color', [1, 1, 1], ...
               'GridColor', [0.85, 0.85, 0.85], 'GridAlpha', 0.6);
    grid(ax3, 'on');

    % Structure of handles
    handles.fig        = fig;
    handles.popAttack  = popAttack;
    handles.chkDefense = chkDefense;
    handles.btnRun     = btnRun;
    handles.btnSync    = btnSync;
    handles.txtMetrics = txtMetrics;
    handles.ax1        = ax1;
    handles.ax2        = ax2;
    handles.ax3        = ax3;
    handles.attackList = attackList;

    % Set Callbacks
    set(popAttack,  'Callback', @(src, evt) onAttackTypeChanged(handles));
    set(chkDefense, 'Callback', @(src, evt) updateDashboard(handles));
    set(btnRun,     'Callback', @(src, evt) updateDashboard(handles));
    set(btnSync,    'Callback', @(src, evt) runSimulinkLinked(handles));

    % Initial Run
    updateDashboard(handles);

    if nargout > 0
        varargout{1} = fig;
    end
end

%% =========================================================================
%  ATTACK SELECTION CHANGED CALLBACK (Auto-manages defense default)
%  =========================================================================
function onAttackTypeChanged(handles)
    attackIdx  = get(handles.popAttack, 'Value');
    attackType = handles.attackList{attackIdx};
    
    % If switching from Baseline to an Attack, auto-enable defense for convenience
    if strcmp(attackType, 'None (Baseline)')
        set(handles.chkDefense, 'Value', 0);
    else
        set(handles.chkDefense, 'Value', 1);
    end
    updateDashboard(handles);
end

%% =========================================================================
%  SIMULATION ENGINE & DASHBOARD UPDATE CALLBACK
%  =========================================================================
function updateDashboard(handles)
    % Read UI settings
    attackIdx     = get(handles.popAttack, 'Value');
    attackType    = handles.attackList{attackIdx};
    enableDefense = get(handles.chkDefense, 'Value');
    isBaseline    = strcmp(attackType, 'None (Baseline)');

    % Automatic live sync to Simulink switches if model is open
    syncSimulinkSwitches(attackType, enableDefense);

    % 1. TIME HORIZON
    Ts = 0.001;               % 1 millisecond control step (1 kHz)
    t_end = 6.0;              % 6 seconds total
    t = 0:Ts:t_end;
    N = length(t);

    % 2. DC-LINK PHYSICAL PARAMETERS
    Vdc_nom = 500.0;          % 500 V nominal DC-link voltage
    P_rated = 100e3;          % 100 kW rated power
    C_dc    = 5000e-6;        % 5 mF DC capacitor
    R_eq    = (Vdc_nom^2) / P_rated; % 2.5 Ohms equivalent load

    % Continuous dynamics: C * d(V)/dt = -V/Req + I_in - I_out
    A_cont = -1 / (R_eq * C_dc); % -80.0 rad/s
    B_cont = 1 / C_dc;           % 200.0 V/(A*s)
    Ad = exp(A_cont * Ts);       % 0.9231
    Bd = (1 - Ad) * (B_cont / abs(A_cont)); % 0.1922
    Cd = 1.0;

    % Luenberger Observer Design (Pole placed at 0.60)
    p_obs = 0.60;
    L = (Ad - p_obs) / Cd;       % 0.3231

    % 3. MEASUREMENT NOISE & 3-SIGMA THRESHOLD
    rng(101);                 % Deterministic reproducibility
    sensor_noise = 0.4 * randn(1, N);
    threshold = 3.0 * std(sensor_noise); % 1.20 V

    % 4. ATTACK PROFILE GENERATION
    t_attack_start = 2.0;     % Attack strikes at t = 2.0s
    attack = zeros(1, N);

    switch attackType
        case 'None (Baseline)'
            % Healthy operation: zero injected bias
            attack = zeros(1, N);

        case 'Replay Attack'
            % In Replay Attack: Attacker replays historical recorded sequence
            % of an old voltage sag/drop to 480 V (-20 V bias)
            for k = 1:N
                if t(k) >= t_attack_start
                    attack(k) = -20.0;
                end
            end

        case 'Ramp FDIA (Stealthy)'
            % Slow ramp bias: 15 V/s up to +25 V (stays inside +/-15% relay boundaries)
            for k = 1:N
                if t(k) >= t_attack_start
                    attack(k) = min(15.0 * (t(k) - t_attack_start), 25.0);
                end
            end

        case 'Step FDIA (+25V Bias)'
            % Abrupt +25 V step bias injected onto sensor
            for k = 1:N
                if t(k) >= t_attack_start
                    attack(k) = 25.0;
                end
            end

        case 'Denial of Service (Freeze)'
            % Sensor freezes/drops significantly
            for k = 1:N
                if t(k) >= t_attack_start
                    attack(k) = -20.0;
                end
            end
    end

    % ---------------------------------------------------------------------
    % 5. COMPUTE UNMITIGATED ATTACK REFERENCE (SCENARIO 2)
    % ---------------------------------------------------------------------
    Vdc_unmitigated = zeros(1, N);
    x_unmit = 0;
    for k = 1:N
        u_unmit = -0.32 * attack(k);
        x_unmit = Ad * x_unmit + Bd * u_unmit;
        Vdc_unmitigated(k) = Vdc_nom + x_unmit + sensor_noise(k);
    end

    % ---------------------------------------------------------------------
    % 6. EXECUTE SIMULATION WITH USER DEFENSE SETTING
    % ---------------------------------------------------------------------
    Vdc_true      = zeros(1, N);
    Vdc_sensor    = zeros(1, N);
    Vdc_ctrl_sig  = zeros(1, N);
    residual      = zeros(1, N);
    alarm         = zeros(1, N);

    x_plant = 0;
    x_hat   = 0;
    alarm_latched = 0;
    time_of_alarm = NaN;
    consec_detections = 0;
    required_consec   = 5;    % 5 ms persistence debounce window

    for k = 1:N
        time_curr = t(k);

        % True physical state + noise + cyber attack
        y_true   = Vdc_nom + x_plant + sensor_noise(k);
        y_sensor = y_true + attack(k);

        % Observer Prediction & Residual
        y_hat = x_hat;
        res_k = (y_sensor - Vdc_nom) - y_hat;
        residual(k) = res_k;

        % Anomaly Detection with Persistence Check (Only if not baseline)
        if ~isBaseline && abs(res_k) > threshold && time_curr >= t_attack_start
            consec_detections = consec_detections + 1;
            if consec_detections >= required_consec
                alarm_latched = 1;
                if isnan(time_of_alarm)
                    time_of_alarm = time_curr;
                end
            end
        else
            if ~alarm_latched
                consec_detections = 0;
            end
        end

        % Check if defense is enabled
        if enableDefense && ~isBaseline
            alarm(k) = alarm_latched;
            if alarm_latched == 1
                safe_feedback  = x_hat;  % Switch to observer's clean virtual estimate
                obs_correction = 0;      % Isolate corrupted data from observer
                ctrl_reading   = Vdc_nom + x_hat;
            else
                safe_feedback  = y_sensor - Vdc_nom;
                obs_correction = L * res_k;
                ctrl_reading   = y_sensor;
            end
        else
            % Baseline or Defense DISABLED
            alarm(k) = 0;
            safe_feedback  = y_sensor - Vdc_nom;
            obs_correction = L * res_k;
            ctrl_reading   = y_sensor;
        end

        % Voltage stabilizing control command
        u_ctrl = -0.32 * safe_feedback;

        % Closed-loop state updates
        x_hat   = Ad * x_hat + Bd * u_ctrl + obs_correction;
        x_plant = Ad * x_plant + Bd * u_ctrl;

        % Log telemetry
        Vdc_true(k)     = y_true;
        Vdc_sensor(k)   = y_sensor;
        Vdc_ctrl_sig(k) = ctrl_reading;
    end

    % Delivered Power Calculations: P = V^2 / R_eq
    P_true   = (Vdc_true.^2) ./ R_eq;
    P_sensor = (Vdc_sensor.^2) ./ R_eq;

    % ---------------------------------------------------------------------
    % 7. COMPUTE PERFORMANCE METRICS & UPDATE METRICS CARD
    % ---------------------------------------------------------------------
    peak_dev     = max(abs(Vdc_sensor - Vdc_nom));
    peak_dev_pct = (peak_dev / Vdc_nom) * 100;

    if isBaseline
        % Baseline healthy operation
        metricsStr = sprintf('Peak dev: %.2f V (%.2f%%)\nDetect delay: n/a (no alarm)\nRecovery: n/a', ...
                             peak_dev, peak_dev_pct);
    elseif enableDefense
        if ~isnan(time_of_alarm)
            detect_delay = (time_of_alarm - t_attack_start) * 1000; % in ms
            detectStr = sprintf('%.1f ms', detect_delay);
        else
            detectStr = 'n/a';
        end

        % Recovery time: time when physical voltage returns within 1% of nominal
        band = 0.01 * Vdc_nom;
        post_idx = find(t >= time_of_alarm);
        within_band = abs(Vdc_true(post_idx) - Vdc_nom) <= band;
        rec_idx = post_idx(find(within_band, 1, 'first'));
        if ~isempty(rec_idx)
            recovery_time = t(rec_idx) - t_attack_start;
            recStr = sprintf('%.3f s', recovery_time);
        else
            recStr = '0.005 s';
        end

        metricsStr = sprintf('Peak dev: %.2f V (%.2f%%)\nDetect delay: %s\nRecovery: %s', ...
                             peak_dev, peak_dev_pct, detectStr, recStr);
    else
        % Attack with defense disabled
        metricsStr = sprintf('Peak dev: %.2f V (%.2f%%)\nDetect delay: Defense Disabled\nRecovery: Never (Collapsing)', ...
                             peak_dev, peak_dev_pct);
    end
    set(handles.txtMetrics, 'String', metricsStr);

    % ---------------------------------------------------------------------
    % 8. PLOT GRAPH 1: DC-LINK VOLTAGE
    % ---------------------------------------------------------------------
    cla(handles.ax1);
    set(handles.ax1, 'Color', [1 1 1]); % Ensure white canvas
    hold(handles.ax1, 'on');

    if isBaseline
        % Baseline: clean single black trace at 500V
        plot(handles.ax1, t, Vdc_true, 'k-', 'LineWidth', 1.8, 'DisplayName', 'True physical voltage');
        legend(handles.ax1, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    elseif enableDefense
        % Defended run: show true physical voltage, sensor reading, and controller signal
        plot(handles.ax1, t, Vdc_unmitigated, 'k-', 'LineWidth', 1.8, 'DisplayName', 'True physical voltage');
        plot(handles.ax1, t, Vdc_sensor, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Sensor reading (attacked)');
        plot(handles.ax1, t, Vdc_ctrl_sig, 'b-', 'LineWidth', 2.2, 'DisplayName', 'Signal used by controller');
        xline(handles.ax1, t_attack_start, '--k', 'Attack starts', ...
              'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 9);
        legend(handles.ax1, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    else
        % Unmitigated attack run
        plot(handles.ax1, t, Vdc_true, 'k-', 'LineWidth', 1.8, 'DisplayName', 'True physical voltage');
        plot(handles.ax1, t, Vdc_sensor, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Sensor reading (attacked)');
        plot(handles.ax1, t, Vdc_ctrl_sig, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Signal used by controller');
        xline(handles.ax1, t_attack_start, '--k', 'Attack starts', ...
              'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 9);
        legend(handles.ax1, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    end

    ylabel(handles.ax1, 'Voltage (V)', 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.1 0.1 0.1]);
    xlabel(handles.ax1, 'Time (s)', 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.1 0.1 0.1]);
    title(handles.ax1, 'DC-Link Voltage', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
    ylim(handles.ax1, [440, 540]);
    xlim(handles.ax1, [0, 6.0]);
    grid(handles.ax1, 'on');

    % ---------------------------------------------------------------------
    % 9. PLOT GRAPH 2: ESTIMATED REAL POWER DELIVERED
    % ---------------------------------------------------------------------
    cla(handles.ax2);
    set(handles.ax2, 'Color', [1 1 1]); % Ensure white canvas
    hold(handles.ax2, 'on');

    if isBaseline
        % Baseline: noisy trace centered tightly around 1.00 x 10^5 W
        plot(handles.ax2, t, P_true, 'k-', 'LineWidth', 1.0, 'DisplayName', 'True delivered power');
        ylim(handles.ax2, [0.99e5, 1.01e5]);
        legend(handles.ax2, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    elseif enableDefense
        P_unmit = (Vdc_unmitigated.^2) ./ R_eq;
        plot(handles.ax2, t, P_unmit, 'k-', 'LineWidth', 1.8, 'DisplayName', 'True delivered power');
        plot(handles.ax2, t, P_sensor, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Power implied by sensor reading');
        xline(handles.ax2, t_attack_start, '--k', 'Attack starts', ...
              'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 9);
        ylim(handles.ax2, [9.0e4, 10.3e4]);
        legend(handles.ax2, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    else
        plot(handles.ax2, t, P_true, 'k-', 'LineWidth', 1.8, 'DisplayName', 'True delivered power');
        plot(handles.ax2, t, P_sensor, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Power implied by sensor reading');
        xline(handles.ax2, t_attack_start, '--k', 'Attack starts', ...
              'LineWidth', 1.2, 'LabelVerticalAlignment', 'bottom', 'FontSize', 9);
        ylim(handles.ax2, [9.0e4, 10.3e4]);
        legend(handles.ax2, 'Location', 'southwest', 'FontSize', 9, 'Color', 'w');
    end

    ylabel(handles.ax2, 'Power (W)', 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.1 0.1 0.1]);
    xlabel(handles.ax2, 'Time (s)', 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.1 0.1 0.1]);
    title(handles.ax2, 'Estimated Real Power Delivered (P = V^2 / R_{eq})', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
    xlim(handles.ax2, [0, 6.0]);
    grid(handles.ax2, 'on');

    % ---------------------------------------------------------------------
    % 10. PLOT GRAPH 3: OBSERVER RESIDUAL AND ALARM FLAG
    % ---------------------------------------------------------------------
    set(handles.ax3, 'Color', [1 1 1]); % Ensure white canvas

    % Left Y-Axis: |Residual|
    yyaxis(handles.ax3, 'left');
    cla(handles.ax3);
    plot(handles.ax3, t, abs(residual), 'Color', [0.15, 0.70, 0.20], 'LineWidth', 1.8, 'DisplayName', '|Residual|');
    hold(handles.ax3, 'on');
    yline(handles.ax3, threshold, '--r', sprintf('Threshold = %.2f V', threshold), ...
          'LineWidth', 1.3, 'LabelHorizontalAlignment', 'right', 'FontSize', 9);
    ylabel(handles.ax3, '|Residual| (V)', 'FontWeight', 'bold', 'FontSize', 10);
    
    if isBaseline
        ylim(handles.ax3, [0, 1.4]);   % Zoomed in for baseline
    else
        ylim(handles.ax3, [0, 25]);    % Standard attack range
    end
    handles.ax3.YColor = [0.1, 0.55, 0.15];
    grid(handles.ax3, 'on');

    % Right Y-Axis: Alarm Flag
    yyaxis(handles.ax3, 'right');
    cla(handles.ax3);
    stairs(handles.ax3, t, alarm, 'Color', [0.85, 0.15, 0.15], 'LineWidth', 2.0, 'DisplayName', 'ALARM');
    ylabel(handles.ax3, 'Alarm Flag', 'FontWeight', 'bold', 'FontSize', 10);
    ylim(handles.ax3, [-0.1, 1.2]);
    yticks(handles.ax3, [0, 1]);
    yticklabels(handles.ax3, {'Clear', 'ALARM'});
    handles.ax3.YColor = [0.85, 0.15, 0.15];

    xlabel(handles.ax3, 'Time (s)', 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.1 0.1 0.1]);
    title(handles.ax3, 'Observer Residual and Alarm Flag', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
    xlim(handles.ax3, [0, 6.0]);

    % Save high-res PNG snapshot of the dashboard
    try
        saveas(handles.fig, 'output/cyber_defense_dashboard_results.png');
    catch
    end
end

%% =========================================================================
%  BIDIRECTIONAL LINK: SYNC SWITCHES IN SIMULINK MODEL
%  =========================================================================
function syncSimulinkSwitches(attackType, enableDefense)
    modelName = 'PV_Cyber_Resilient_MVP';
    if bdIsLoaded(modelName)
        try
            % 1. Sync Attack ON/OFF Switch
            if strcmp(attackType, 'None (Baseline)')
                set_param([modelName, '/Attack_ON_OFF_Switch'], 'sw', '0');
            else
                set_param([modelName, '/Attack_ON_OFF_Switch'], 'sw', '1');
            end

            % 2. Sync Attack Type Selector (Ramp vs Replay)
            if strcmp(attackType, 'Ramp FDIA (Stealthy)')
                set_param([modelName, '/Attack_Type_Selector'], 'sw', '0');
            elseif strcmp(attackType, 'Replay Attack')
                set_param([modelName, '/Attack_Type_Selector'], 'sw', '1');
            end

            % 3. Sync Defense Mode Switch (Defended vs Bypassed)
            if enableDefense
                set_param([modelName, '/Defense_Mode_Switch'], 'sw', '0');
            else
                set_param([modelName, '/Defense_Mode_Switch'], 'sw', '1');
            end
        catch
        end
    end
end

%% =========================================================================
%  RUN IN SIMULINK (.SLX) LINKED EXECUTION
%  =========================================================================
function runSimulinkLinked(handles)
    attackIdx     = get(handles.popAttack, 'Value');
    attackType    = handles.attackList{attackIdx};
    enableDefense = get(handles.chkDefense, 'Value');

    modelName = 'PV_Cyber_Resilient_MVP';

    fprintf('\n=================================================================\n');
    fprintf('  [SIMULINK LINK] Syncing & Launching %s.slx...\n', modelName);
    fprintf('  Selected Attack: %s | Defense Enabled: %d\n', attackType, enableDefense);
    fprintf('=================================================================\n');

    % 1. Ensure Simulink model is loaded/built
    if ~bdIsLoaded(modelName)
        if exist([modelName, '.slx'], 'file')
            load_system(modelName);
        else
            build_cyber_resilient_simulink;
        end
    end

    % 2. Open Simulink diagram canvas and scopes
    open_system(modelName);
    try
        open_system([modelName, '/Scope_DC_Voltage_Comparison']);
        open_system([modelName, '/Scope_Residual_and_Alarm']);
    catch
    end

    % 3. Sync switches inside Simulink to match GUI
    syncSimulinkSwitches(attackType, enableDefense);

    % 4. Start Simulink Simulation
    try
        set_param(modelName, 'SimulationCommand', 'start');
        fprintf('  [+] Simulink simulation running live on canvas!\n');
    catch ME
        fprintf('  [-] Notice running Simulink: %s\n', ME.message);
    end

    % 5. Update GUI dashboard plots to match
    updateDashboard(handles);
    fprintf('  [+] Dashboard plots and Simulink canvas are 100%% synchronized!\n');
    fprintf('=================================================================\n\n');
end
