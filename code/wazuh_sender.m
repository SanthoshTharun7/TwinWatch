function success = wazuh_sender(eventType, payload, targetHost, targetPort)
%% =========================================================================
%  WAZUH_SENDER.M - Real-Time Syslog / UDP Connector for Wazuh SIEM
%  Integrates MATLAB Cyber-Physical Simulation with Wazuh SIEM
%  =========================================================================
%  Usage:
%    wazuh_sender('CYBER_ATTACK_INJECTED', struct('attack_type', 'Step FDIA', 'sensor_voltage', 525.0));
%    wazuh_sender('ANOMALY_RESIDUAL_ALERT', struct('residual', 24.5, 'threshold', 1.2));
%    wazuh_sender('CYBER_RESILIENCE_MITIGATED', struct('action', 'OBSERVER_ISOLATION'));
%    wazuh_sender('SIMULATION_SUMMARY', struct('peak_dev', 25.0, 'detect_delay', '12 ms'));
%  =========================================================================

    if nargin < 3 || isempty(targetHost)
        targetHost = '127.0.0.1';
    end
    if nargin < 4 || isempty(targetPort)
        targetPort = 514;
    end

    success = false;
    try
        % 1. Format payload
        if ~isfield(payload, 'event_type')
            payload.event_type = eventType;
        end
        if ~isfield(payload, 'timestamp')
            payload.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss.SSS'));
        end
        if ~isfield(payload, 'source')
            payload.source = 'MATLAB_Cyber_Resilience_Simulation';
        end

        % Convert struct to JSON string
        jsonStr = jsonencode(payload);

        % 2. Construct RFC 3164 Syslog packet
        % Priority <14> = Facility 1 (user) * 8 + Severity 6 (informational)
        monthNames = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
        c = clock;
        mon = monthNames{c(2)};
        syslogHeader = sprintf('<14>%s %2d %02d:%02d:%02d sanmaestro solar_grid: ', ...
                               mon, c(3), c(4), c(5), round(c(6)));
        fullPacket = [syslogHeader, jsonStr];

        % 3. Send over UDP using Java DatagramSocket (Standard across all MATLAB versions)
        import java.net.DatagramSocket;
        import java.net.DatagramPacket;
        import java.net.InetAddress;

        bytes = int8(fullPacket); % Java byte array
        addr = InetAddress.getByName(targetHost);
        packet = DatagramPacket(bytes, length(bytes), addr, targetPort);

        socket = DatagramSocket();
        socket.send(packet);
        socket.close();

        % 4. Append to local audit JSONL log
        thisDir = fileparts(mfilename('fullpath'));
        auditLog = fullfile(thisDir, 'wazuh_siem_events.jsonl');
        fid = fopen(auditLog, 'a');
        if fid ~= -1
            fprintf(fid, '%s\n', jsonStr);
            fclose(fid);
        end

        success = true;
    catch ME
        fprintf('  [-] Notice: Wazuh Syslog transmit failed: %s\n', ME.message);
    end
end
