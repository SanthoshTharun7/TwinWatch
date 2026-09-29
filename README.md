# TwinWatch

**Cyber-physical resilience testbed for a simulated 5kW solar power grid.** MATLAB/Simulink models a DC-link solar plant under active cyberattack, detects anomalies using a Luenberger state observer and a statistically-derived 3-sigma threshold, automatically isolates the compromised sensor, and streams every event to a Wazuh SIEM for monitoring and alerting.

![Status](https://img.shields.io/badge/status-active--development-yellow)
![MATLAB](https://img.shields.io/badge/MATLAB-Simulink-orange)
![SIEM](https://img.shields.io/badge/SIEM-Wazuh-blue)

---

## Why this project

Most ICS/OT security demos target legacy sectors — water treatment, oil & gas. Inverter-based renewable generation (solar, wind) is comparatively understudied despite being an increasingly large share of grid infrastructure. TwinWatch demonstrates a full attack → detect → mitigate → alert chain against a solar DC-link model, using a physics-grounded defense (a state observer) rather than network-signature detection alone.

## Architecture

```
┌─────────────────┐     ┌──────────────────────┐     ┌────────────────┐
│  Attack Layer    │────▶│   Physical Plant      │────▶│  Sensor Layer  │
│  (FDIA / Replay /│     │   (DC-link capacitor,  │     │  (compromised  │
│   DoS / Ramp)    │     │    500V, 100kW)        │     │   reading)     │
└─────────────────┘     └──────────────────────┘     └───────┬────────┘
                                                                │
                          ┌─────────────────────────────────────┘
                          ▼
                ┌──────────────────────┐        ┌───────────────────┐
                │  Luenberger Observer  │───────▶│  3-Sigma Residual  │
                │  (pole-placed gain L) │        │   Anomaly Check     │
                └──────────────────────┘        └─────────┬──────────┘
                                                            │ alarm
                          ┌─────────────────────────────────┘
                          ▼
                ┌──────────────────────┐        ┌───────────────────┐
                │  Bumpless Mitigation  │───────▶│  Wazuh Sender       │
                │  Switch (isolates     │        │  (syslog/UDP → SIEM)│
                │  bad sensor)          │        └─────────┬──────────┘
                └──────────────────────┘                  │
                                                            ▼
                                                  ┌───────────────────┐
                                                  │  Wazuh SIEM         │
                                                  │  (decoder + rules,  │
                                                  │   MITRE ATT&CK tags)│
                                                  └───────────────────┘
```

## What's implemented

| Component | Status | Notes |
|---|---|---|
| DC-link solar plant model | ✅ Implemented | `PV_Cyber_Resilient_MVP.slx`, 500V/100kW transfer-function plant |
| Attack injection (Ramp FDIA, Step FDIA) | ✅ Implemented | Selectable via GUI dashboard or Simulink manual switch |
| Attack injection (Replay, DoS/Freeze) | ⚠️ Partial | Currently share logic with Step FDIA; behaviorally distinct implementations in progress |
| Luenberger observer | ✅ Implemented | Closed-loop, pole-placed gain (`p_obs = 0.60`) |
| 3-sigma anomaly detection | ✅ Implemented | Threshold computed from live noise statistics (`3 × std`), with 5ms persistence debounce |
| Bumpless mitigation switch | ✅ Implemented | Isolates compromised sensor, hands control to observer estimate |
| Interactive dashboard | ✅ Implemented | Attack/defense toggles, live scopes, auto-computed metrics |
| Wazuh SIEM integration | ✅ Implemented | Custom decoder + rules, syslog/UDP sender from MATLAB |
| MITRE ATT&CK for ICS tagging | 🔲 Planned | Rules structured for it, tags not yet added |
| CI/CD misconfiguration → initial access chain | 🔲 Planned | TruffleHog/Nosey Parker secrets-scanning as the entry point into this OT chain |
| HashiCorp Vault remediation | 🔲 Planned | Dynamic credentials as the fix for the above |

## Quick start

**Requirements:** MATLAB with Simulink, a running Wazuh manager.

1. Configure the Wazuh manager to accept syslog on UDP 514 (`/var/ossec/etc/ossec.conf`):
   ```xml
   <remote>
     <connection>syslog</connection>
     <port>514</port>
     <protocol>udp</protocol>
     <allowed-ips>127.0.0.1/32</allowed-ips>
   </remote>
   ```
2. Copy `decoder/solar_grid_decoder.xml` and `rules/solar_grid_rules.xml` into your Wazuh manager's local decoders/rules directories and restart the manager.
3. In MATLAB, run:
   ```matlab
   build_cyber_resilient_simulink   % builds and opens the .slx model
   cyber_resilience_dashboard       % launches the interactive GUI
   ```
4. Select an attack type, toggle defense on/off, and click **Run Simulation**. Open your Wazuh dashboard to see events arrive in real time.
5. To verify the SIEM link independently: `verify_wazuh_sim`

## Results

Metrics are computed live for each run and displayed on the dashboard (peak voltage deviation, detection delay, recovery time). See `output/cyber_defense_dashboard_results.png` for a sample run.

*(Fill in with your actual measured numbers once finalized — e.g. "Ramp FDIA detected within 85ms of onset; physical voltage recovered to within 1% of nominal in 0.4s.")*

## Repository structure

```
TwinWatch/
├── code/
│   ├── build_cyber_resilient_simulink.m
│   ├── cyber_resilience_dashboard.m
│   ├── wazuh_sender.m
│   └── verify_wazuh_sim.m
├── decoder/
│   └── solar_grid_decoder.xml
├── rules/
│   └── solar_grid_rules.xml
├── output/
│   └── cyber_defense_dashboard_results.png
├── LICENSE
└── README.md
```

## Threat model

Attacks implemented here are grounded in [MITRE ATT&CK for ICS](https://attack.mitre.org/matrices/ics/):
- **Ramp/Step FDIA** → False data injection on the sensor path, consistent with *Spoof Reporting Message* (T0856)
- **Replay** → Re-injection of previously valid telemetry *(implementation in progress)*
- **DoS/Freeze** → *Denial of Control* / *Denial of View* pattern *(implementation in progress)*

*(Update with confirmed technique IDs once the Wazuh rule tagging is finalized.)*

## Limitations

- UDP syslog transport is fire-and-forget; no delivery acknowledgment.
- Detection is validated in simulation against a single-state DC-link model; not yet tested against a multi-state or hardware-in-the-loop plant.
- Replay and DoS/Freeze attacks are not yet behaviorally distinct from the step-bias attack (see table above).

## Author

Built by [Santy](https://github.com/SanthoshTharun7) — final-year B.Tech Cybersecurity, Amrita University, Coimbatore.

## License

MIT — see [LICENSE](LICENSE).
