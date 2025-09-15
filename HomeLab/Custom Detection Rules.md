# 🔐 Detection Rule: Multiple Failed Logon Attempts

## 📌 Background
While Microsoft Defender XDR provides strong built-in detections, it’s valuable for analysts to understand how to **engineer custom rules**. Custom detections help you:

- Practice extracting fields from raw events  
- Tune thresholds and logic for your environment  
- Map entities (accounts, hosts, IPs) for clearer incidents  

In this lab, I created a Sentinel analytics rule to detect **multiple failed logon attempts** (Event ID **4625**) within a short time window.

---

## ⚙️ Detection Query (KQL)
```KQL
Event
| where EventID == 4625
| extend ed = tostring(EventData)
| extend TargetUser = extract(@"(?i)<Data Name=""TargetUserName"">([^<]*)</Data>", 1, ed)
| extend IpAddress = extract(@"(?i)<Data Name=""IpAddress"">([^<]*)</Data>", 1, ed)
| project TimeGenerated, Computer, TargetUser, IpAddress
```

---

## 🔎 Explanation
- **EventID 4625** → Windows failed logon events  
- **extend TargetUser** → Regex extraction of the target username from the XML event data  
- **extend IpAddress** → Regex extraction of the IP address from the XML event data  
- **project** → Displays only the most relevant fields for alert triage  

---

## 📊 Entity Mapping
Mapping fields to Sentinel entities ensures that when an incident is generated, it automatically ties together the user, host, and IP.

- **Account** → `TargetUser`  
- **Host** → `Computer`  
- **IP Address** → `IpAddress`  

This makes the incident graph far more useful, showing relationships between authentication attempts, devices, and source IPs.

---

## 📸 Screenshots
- **Detection Rule Query & Entity Mapping**  
  ![Detection Rule](./images/detection-rule.png)  

- **Incident in Microsoft Sentinel**  
  ![Incident Graph](./images/incident-graph.png)  

---

## 🧩 Lab Outcome
When triggered, the rule produced a Sentinel incident labeled **Multiple Failed Logon Attempts**. The incident graph showed the relationships between:

- Target account(s)  
- Host computer(s)  
- Source IP  

This allowed for fast triage and demonstrated how even a **basic rule** becomes actionable when paired with entity mapping.

---

## 🔹 Lessons Learned
- Built-in detections are powerful, but creating custom rules improves understanding of **raw event data**  
- Entity mapping transforms a flat log query into a **visual, contextualized incident**  
- Even simple use cases like failed logons can form the foundation for more advanced detection engineering  

---

✅ This project was part of my ongoing practice in **detection engineering and SOC workflows**. Future iterations will include thresholding (e.g., >5 failed logons in 10 minutes) and correlation with successful logons (Event ID 4624) for brute-force detection.
