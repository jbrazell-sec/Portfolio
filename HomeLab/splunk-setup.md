# Domain Network with Splunk SIEM – Home Lab Write-Up

## **Overview**
This lab simulates a **real-world enterprise domain environment** with a **Security Information and Event Management (SIEM)** system using **Splunk**. The goal is to monitor and analyze security events across the domain.

## **Network Architecture**
### **Components:**
- **Windows Server (Domain Controller, VM in VirtualBox)** – Hosts Active Directory and logs authentication events.
- **Windows Client (Workstation, VM in VirtualBox)** – Simulates an end-user machine, forwarding logs.
- **Ubuntu Server (Splunk SIEM, VM in VirtualBox)** – Receives and analyzes logs from domain machines.

### **Network Topology:**
```
[ Windows Server ]  <-->  [ Ubuntu Server (Splunk) ]  <-->  [ Windows Client ]
```
- All machines are within the **same domain**.
- The **Ubuntu Server** runs Splunk Enterprise.
- **Universal Forwarders** send logs to the Splunk instance.

---

## **Splunk SIEM Setup**
### **1. Install Splunk on Ubuntu Server**
1. **Update and prepare the system:**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
2. **Download the Splunk Enterprise package:**
   ```bash
   wget -O splunk.deb "https://download.splunk.com/products/splunk/releases/latest/linux/splunk-latest-linux-2.6-amd64.deb"
   ```
3. **Install the package:**
   ```bash
   sudo dpkg -i splunk.deb
   ```
4. **Enable Splunk to start at boot and accept the license agreement:**
   ```bash
   sudo /opt/splunk/bin/splunk enable boot-start --accept-license
   ```
5. **Start Splunk:**
   ```bash
   sudo /opt/splunk/bin/splunk start
   ```
6. **Set up the admin credentials:**
   - During the first-time startup, Splunk will prompt you to set an admin username and password.

7. **Ensure firewall rules allow Splunk traffic:**
   ```bash
   sudo ufw allow 8000/tcp
   sudo ufw allow 9997/tcp
   sudo ufw enable
   ```

### **2. Configure Splunk for Data Collection**
1. **Create an index for Windows logs:**
   ```bash
   sudo /opt/splunk/bin/splunk add index endpoint -auth admin:<yourpassword>
   ```
2. **Enable receiving logs from forwarders:**
   ```bash
   sudo /opt/splunk/bin/splunk enable listen 9997
   ```
3. **Verify Splunk is actively listening:**
   ```bash
   sudo netstat -tulnp | grep 9997
   ```
4. **Check Splunk status:**
   ```bash
   sudo /opt/splunk/bin/splunk status
   ```

---

### **3. Install & Configure Universal Forwarders on Windows Machines**
1. Download **Splunk Universal Forwarder**:
   - [64-bit Windows Forwarder](https://download.splunk.com/products/universalforwarder/releases/latest/windows/splunkforwarder-*-x64-release.msi)
   - [32-bit Windows Forwarder](https://download.splunk.com/products/universalforwarder/releases/latest/windows/splunkforwarder-*-x86-release.msi)
2. Install with the following configurations:
   - Forward logs to **Ubuntu Splunk Server IP** on port **9997**.
   - Enable Windows Event Log monitoring (`Security`, `System`, `Application`).
3. **Create an inputs.conf file to specify log sources and the index:**
   - Navigate to the Splunk Universal Forwarder directory:
     ```powershell
     cd "C:\Program Files\SplunkUniversalForwarder\system\local"
     ```
   - Create or edit the `inputs.conf` file:
     ```plaintext
     [WinEventLog://Application]
     index = endpoint
     disabled = false
     
     [WinEventLog://Security]
     index = endpoint
     disabled = false
     
     [WinEventLog://System]
     index = endpoint
     disabled = false
     
     [WinEventLog://Microsoft-Windows-Sysmon/Operational]
     index = endpoint
     disabled = false
     renderXml = true
     source = XmlWinEventLog:Microsoft-Windows-Sysmon/Operational
     ```
   - Save and restart the Universal Forwarder service.

4. Verify forwarding by running:
   ```powershell
   splunk list forward-server
   ```

---

### **Automated Log Parsing and Anomaly Detection**
To automate log parsing and detect anomalies, two scripts are scheduled to run every **10 minutes** on the **Ubuntu Splunk Server** using cron jobs:

1. **Log Parser** - Queries Splunk logs and saves the results:
   [View Script](https://github.com/YourGitHubUsername/Portfolio/blob/main/Scripts/log-parser.py)

2. **Anomaly Detector** - Identifies suspicious activity (failed logins, admin logins, process execution):
   [View Script](https://github.com/YourGitHubUsername/Portfolio/blob/main/Scripts/anomaly-detector.sh)

#### **Setting Up the Cron Jobs**
To schedule the scripts, add the following entries to the cron scheduler:
```bash
(crontab -l 2>/dev/null; echo "*/10 * * * * python3 /path/to/log-parser.py") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * * bash /path/to/anomaly-detector.sh") | crontab -
```
To verify scheduled tasks:
```bash
crontab -l
```
To manually run a script:
```bash
python3 /path/to/log-parser.py
bash /path/to/anomaly-detector.sh
```

---

## **Use Cases & Threat Detection**
✅ **Detect unauthorized logins to domain accounts**
✅ **Monitor system process execution for malware activity**
✅ **Analyze authentication failures for brute-force attacks**

This setup simulates a **basic SOC analyst workflow**, allowing hands-on experience with **log analysis, threat detection, and incident response** in an enterprise network.

---

## **Next Steps**
- Expand with **Suricata for network monitoring**
- Integrate **Elastic SIEM** as an alternative
- Automate **alerting for critical events**

This write-up documents my **hands-on experience** in building a security monitoring environment. 🚀

