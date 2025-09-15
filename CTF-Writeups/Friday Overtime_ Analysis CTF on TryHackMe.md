## **Friday Overtime: Hello Busy Weekend - CTF Write-Up**

**Author:** StillMarzz\
**Platform:** TryHackMe\
**Category:** Threat Intelligence / SOC Analysis\
**Date:** 2/22/2025

---

## **1. Introduction**

It's a Friday evening at PandaProbe Intelligence, and SwiftSpend Finance has raised concerns about potential malware threats. As the only CTI analyst on shift, I took charge of analyzing the suspicious files and investigating possible cyber threats.

After accessing the **PandaProbe Dashboard**, we received a **samples.zip** file containing the following **DLL files**:

- `cbmrpa.dll`
- `maillfpassword.dll`
- `pRsm.dll`
- `qmsdp.dll`
- `wcdbcrk.dll`

This analysis involved:\
✅ **Malware Sample Investigation**\
✅ **Threat Intelligence Correlation**\
✅ **MITRE ATT&CK Mapping**\
✅ **IOC Collection & Detection Strategies**

---

## **2. Challenge Questions & Answers**

### **Q1: Who shared the malware samples?**

📝 **Answer:** Oliver Bennett

🔍 **How I Found It:**

- When signing into the PandaProbe Dashboard, I found a ticket regarding the situation, sent by Oliver Bennett.
- **Key Notes:**
  - Detected on **Friday, December 8, 2023**
  - Infected over **9000 systems**
  - Nature of Malware: **Unknown / Suspected RAT**
  - All infected systems were **isolated** from the network, and the malware samples were sent for analysis.

---

### **Q2: What is the SHA1 hash of the file "pRsm.dll" inside ********`samples.zip`********?**

📝 **Answer:** `9d1ecbbe8637fed0d89fca1af35ea821277ad2e8`

🔍 **How I Found It:**

- Extracted `samples.zip` using the command:
  ```bash
  unzip samples.zip
  ```
- Ran a SHA1 hash check using:
  ```bash
  sha1sum pRsm.dll
  ```
- Verified against VirusTotal for known malware signatures.

---

### **Q3: Which malware framework utilizes these DLLs as add-on modules?**

📝 **Answer:** MgBot

🔍 **How I Found It:**

- When browsing community input on **VirusTotal**, there were multiple entries referencing **MgBot**.
- Cross-referenced findings with **MITRE ATT&CK** and malware repositories.

---

### **Q4: Which MITRE ATT&CK Technique is linked to using ********`pRsm.dll`******** in this malware framework?**

📝 **Answer:** `T1123 - Audio Capture`\
🔗 **MITRE ATT&CK Link:** [https://attack.mitre.org/techniques/T1123/](https://attack.mitre.org/techniques/T1123/)

🔍 **How I Found It:**

- Found a **YARA signature match** on the hash of `pRsm.dll`, titled **"MAL\_MgBot\_Audio\_Capture\_Plugin\_Apr23"**.
- Examined the **MITRE ATT&CK page** for **MgBot**, which includes a technique titled **"Audio Capture"**, allowing MgBot to record input/output audio streams from infected devices.

---

### **Q5: What is the CyberChef defanged URL of the malicious download location first seen on 2020-11-02?**

📝 **Answer:** `hxxp[://]update[.]browser[.]qq[.]com/qmbs/QQ/QQUrlMgr_QQ88_4296.exe`

🔍 **How I Found It:**

- Based on research from the article **"Evasive Panda APT group delivers malware via updates for popular Chinese software"** ([WeLiveSecurity](https://www.welivesecurity.com/2023/04/26/evasive-panda-apt-group-malware-updates-popular-chinese-software/)), the malware was delivered via a **fake software update**.
- **ESET telemetry data** identified the original **download URL**, first seen on **November 2, 2020**.
- Used **CyberChef** to **defang** the URL.

---

### **Q6: What is the CyberChef defanged IP address of the C&C server first detected on 2020-09-14?**

📝 **Answer:** `122[.]10[.]90[.]12`

🔍 **How I Found It:**

- The same **WeLiveSecurity** article contained a section on **network infrastructure**, listing two C&C servers.
- One of these IPs was first detected on **September 14, 2020**.
- Used **CyberChef** to **defang** the IP address.

---

### **Q7: What is the SHA1 hash of the SpyAgent family spyware hosted on the same IP targeting Android devices on November 16, 2022?**

📝 **Answer:** `1c1fe906e822012f6235fcc53f601d006d15d7be`

🔍 **How I Found It:**

- Searched the **IP address** on **VirusTotal**.
- Under the **Relations tab**, found a communicating file categorized as **Android spyware**.
- Checked the file’s **VirusTotal page** and extracted the **SHA1 hash**.

---

## **3. Conclusion & Lessons Learned**

- **Summary of findings**: MgBot was identified as the malware framework, with an audio capture plugin used in attacks.
- **Impact on organization**: Potential widespread RAT infection, compromising sensitive data.
- **Future recommendations**: Implement stricter network segmentation and enhance malware analysis pipelines.

---

## **4. References & Tools Used**

📌 **OSINT Tools**: VirusTotal, Hybrid Analysis, urlscan.io\
📌 **Forensic Tools**: CyberChef, YARA\
📌 **MITRE ATT&CK Link**: [https://attack.mitre.org/techniques/T1123/](https://attack.mitre.org/techniques/T1123/)\
📌 **Reference Article**: [Evasive Panda APT group delivers malware via updates for popular Chinese software](https://www.welivesecurity.com/2023/04/26/evasive-panda-apt-group-malware-updates-popular-chinese-software/)

