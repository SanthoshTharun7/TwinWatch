# Complete Lab Guide: Wazuh SIEM + MATLAB Cyber-Physical Simulation

This guide explains:
1. **Reboot Routine:** How to bring the lab back up in 30 seconds after turning off or restarting your laptop.
2. **From-Scratch Setup:** How to rebuild the entire lab on any new Linux/Kali machine.
3. **Architecture Overview:** How MATLAB communicates with Wazuh via Syslog.

---

## Part 1: Quick-Start After Laptop Reboot (Daily Routine)

Because all configuration files, custom rules, and Docker volumes are saved permanently on your disk, **you do not need to re-install anything after turning off your laptop.**

### Step 1: Start Docker Desktop
Open your terminal and run:
```bash
systemctl --user start docker-desktop
```
*(Wait ~10 seconds for the Docker daemon to initialize).*

### Step 2: Start the Wazuh SIEM Stack
```bash
cd /home/sanmaestro7/wazuh-docker/single-node
docker compose up -d
```
Verify the 3 containers are running:
```bash
docker compose ps
```
You should see `wazuh.manager`, `wazuh.indexer`, and `wazuh.dashboard` listed with status `Up`.

### Step 3: Open the Wazuh Web Dashboard
1. Open your browser and go to: **`https://localhost`**
2. Accept the self-signed certificate warning (**Advanced** ➔ **Proceed to localhost**).
3. Log in:
   * **Username:** `admin`
   * **Password:** `SecretPassword`
4. Navigate to **☰ Menu** (top-left) ➔ **Threat Hunting** ➔ **Events**.

### Step 4: Launch Your MATLAB Simulation
In MATLAB, run:
```matlab
cd /home/sanmaestro7/Documents/finalyrproject/final_project
cyber_resilience_dashboard
```
* Select any attack (e.g. `Ramp FDIA (Stealthy)`, `Step FDIA`, `Replay Attack`).
* Ensure **`[x] 🛡️ Wazuh SIEM Stream`** is checked.
* Click **Run Simulation**.
* Check your Wazuh browser tab: all alerts appear live!

### How to Stop Wazuh Before Shutting Down (Optional but Recommended)
```bash
cd /home/sanmaestro7/wazuh-docker/single-node
docker compose down
```

---

## Part 2: Rebuilding the Lab From Scratch (On a New Machine)

If you migrate to a new computer or clean reinstall, follow these steps:

### Prerequisites
* **OS:** Linux (Kali, Ubuntu, Debian, or any distro with Docker support).
* **RAM:** Minimum 8 GB (16 GB recommended).
* **Software:** Docker, Docker Compose, Git, and MATLAB.

### Step 1: Clone Wazuh Docker Repository
```bash
git clone --depth 1 -b v4.9.2 https://github.com/wazuh/wazuh-docker.git ~/wazuh-docker
cd ~/wazuh-docker/single-node
```

### Step 2: Generate Self-Signed TLS Certificates
```bash
docker compose -f generate-indexer-certs.yml run --rm generator
```

### Step 3: Configure Wazuh for MATLAB Syslog Ingestion
Edit `config/wazuh_cluster/wazuh_manager.conf` to enable UDP port 514. Add this block under `<ossec_config>` right after the port 1514 remote block:
```xml
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>0.0.0.0/0</allowed-ips>
  </remote>
```

### Step 4: Create Custom Decoders and Rules for Solar Grid

1. **Create `config/wazuh_cluster/local_decoder.xml`**:
```xml
<decoder name="solar_grid">
  <program_name>solar_grid</program_name>
  <plugin_decoder>JSON_Decoder</plugin_decoder>
</decoder>
```

2. **Create `config/wazuh_cluster/local_rules.xml`**:
```xml
<group name="solar_grid,cps_security,ot_security,">

  <rule id="100100" level="3">
    <decoded_as>solar_grid</decoded_as>
    <description>Solar Grid Simulation: Event received.</description>
    <group>solar_grid,</group>
  </rule>

  <rule id="100101" level="3">
    <if_sid>100100</if_sid>
    <field name="event_type">^TELEMETRY_NORMAL$</field>
    <description>Solar Grid: Normal operating telemetry recorded (Vdc: $(sensor_voltage)V, Power: $(power_kw)kW).</description>
    <group>solar_grid,telemetry,</group>
  </rule>

  <rule id="100102" level="8">
    <if_sid>100100</if_sid>
    <field name="event_type">^ANOMALY_RESIDUAL_ALERT$</field>
    <description>Solar Grid ALERT: Observer residual anomaly detected! Residual $(residual)V exceeded 3-sigma threshold $(threshold)V.</description>
    <group>solar_grid,anomaly_detection,attack_alert,</group>
  </rule>

  <rule id="100103" level="10">
    <if_sid>100100</if_sid>
    <field name="event_type">^CYBER_ATTACK_INJECTED$</field>
    <field name="attack_type">FDIA</field>
    <description>Solar Grid CRITICAL: False Data Injection Attack (FDIA) injected into DC-Link voltage sensor ($(attack_type)).</description>
    <group>solar_grid,fdia,integrity_attack,</group>
  </rule>

  <rule id="100104" level="10">
    <if_sid>100100</if_sid>
    <field name="event_type">^CYBER_ATTACK_INJECTED$</field>
    <field name="attack_type">Replay</field>
    <description>Solar Grid CRITICAL: Replay Attack injected on voltage telemetry ($(attack_type)).</description>
    <group>solar_grid,replay_attack,integrity_attack,</group>
  </rule>

  <rule id="100105" level="12">
    <if_sid>100100</if_sid>
    <field name="event_type">^CYBER_ATTACK_INJECTED$</field>
    <field name="attack_type">Denial of Service|Freeze</field>
    <description>Solar Grid EMERGENCY: Denial of Service / Telemetry Freeze attack on PV Grid Controller.</description>
    <group>solar_grid,dos_attack,availability_attack,</group>
  </rule>

  <rule id="100106" level="7">
    <if_sid>100100</if_sid>
    <field name="event_type">^CYBER_RESILIENCE_MITIGATED$</field>
    <description>Solar Grid RESILIENCE: Corrupted sensor isolated; control switched to virtual Luenberger observer estimate.</description>
    <group>solar_grid,mitigation,resilience,</group>
  </rule>

  <rule id="100107" level="4">
    <if_sid>100100</if_sid>
    <field name="event_type">^SIMULATION_SUMMARY$</field>
    <description>Solar Grid Summary: Peak dev $(peak_dev)V ($(peak_dev_pct)%), Detection delay $(detect_delay), Recovery $(recovery_time).</description>
    <group>solar_grid,benchmark,</group>
  </rule>

</group>
```

### Step 5: Mount Rules in `docker-compose.yml`
Under the `wazuh.manager` service `volumes:` section in `docker-compose.yml`, add:
```yaml
      - ./config/wazuh_cluster/local_rules.xml:/var/ossec/etc/rules/local_rules.xml
      - ./config/wazuh_cluster/local_decoder.xml:/var/ossec/etc/decoders/local_decoder.xml
```

### Step 6: Start Wazuh
```bash
docker compose up -d
```

---

## Part 3: How the MATLAB Integration Works

### The Connector: `wazuh_sender.m`
Located in your project directory:
`wazuh_sender(eventType, payload, targetHost, targetPort)`
* Formats events as RFC 3164 Syslog messages with JSON payloads:
  `<14>Sep 16 10:44:26 sanmaestro solar_grid: {"event_type":"...", ...}`
* Sends UDP packets to `127.0.0.1:514` via standard Java networking (`java.net.DatagramSocket`).
* Saves an offline copy to `wazuh_siem_events.jsonl` in the same directory.

### Fast 1-Second Connection Verification Script
Whenever you want to test whether Wazuh is receiving events without opening the full simulation GUI, run in MATLAB:
```matlab
cd /home/sanmaestro7/Documents/finalyrproject/final_project
verify_wazuh_sim
```
If you see `[+] All events dispatched to Wazuh SIEM over UDP port 514!`, the link is healthy.

---

## Part 4: Useful Troubleshooting Commands

* **Check container health:**
  ```bash
  cd ~/wazuh-docker/single-node && docker compose ps
  ```
* **View live Wazuh Manager logs:**
  ```bash
  docker exec -it single-node-wazuh.manager-1 tail -f /var/ossec/logs/ossec.log
  ```
* **View alerts generated in text format:**
  ```bash
  docker exec -it single-node-wazuh.manager-1 tail -f /var/ossec/logs/alerts/alerts.log
  ```
* **Test rule matching via command line:**
  ```bash
  docker exec -i single-node-wazuh.manager-1 /var/ossec/bin/wazuh-logtest
  ```
