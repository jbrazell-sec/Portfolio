# **TryHackMe Network Challenge: Breaching AD**

**Author:** StillMarzz(Sl1M)  
**Platform:** TryHackMe
**Category:** Exploiting Active Directory  
**Date:** 2/23/2025

---

## **1. Introduction**

This CTF walkthrough demonstrates various authentication-based attacks in an Active Directory environment, highlighting weaknesses in **NTLM authentication, password spraying, LDAP pass-back attacks, and credential extraction from PXE boot images and databases**.

The simulated environment consists of:
- **Domain Controller** (`THMDC - 10.200.80.101`)
- **Web Server** (`THM IIS - 10.200.80.201`)
- **PXE Boot Server** (`THM MDT - 10.200.80.202`)
- **Attacking System** (Kali/Linux machine)

Network Diagram Provided to us:

![Network Diagram](.github/screenshots/Screenshot_20250223_114222.png)  

### **Objectives**
✅ Enumerate NTLM authentication mechanisms  
✅ Exploit weak credentials via password spraying  
✅ Capture NTLM authentication hashes via LDAP attacks  
✅ Extract stored credentials from PXE boot images  
✅ Analyze sensitive credentials in the McAfee database  

---

## **2. Reconnaissance & Initial Access**

The first step was verifying if the **targeted domain name resolution** was correctly set. We configured our DNS settings to use the domain controller (`10.200.80.101`).

![DNS Setup](.github/screenshots/Screenshot_20250223_130420.png)  

Once configured, an **nslookup query** was performed to validate DNS resolution.

![nslookup query](.github/screenshots/Screenshot_20250223_130506.png)  

**Q1: What popular website can be used to verify if your email address or password has ever been exposed in a publicly disclosed data breach?**
📝 **Answer:** `haveibeenpwned`

---

## **3. Password Spraying Attack**

To identify weak credentials, we attempted a **password spraying attack** against NTLM authentication.

**Q2: What is the name of the challenge-response authentication mechanism that uses NTLM?**
📝 **Answer:** `netntlm`

We found that the NTLM auth requested a username and password
![Password Spraying Script](.github/screenshots/Screenshot_20250223_130548.png)  

Using an **NTLM password spraying script**, we tested a default password (`Changeme123`) against a list of known usernames.

![Password Spraying Script](.github/screenshots/Screenshot_20250223_130635.png)  
![Password Spraying Script](.github/screenshots/Screenshot_20250223_130711.png)   

The attack was **successful**, revealing **four valid credential pairs**:
- **Third Valid Username:** `gordon.stevens`
- **Total Valid Credentials Found:** `4`

![Successful Logins](.github/screenshots/Screenshot_20250223_130738.png)  

Testing one of the compromised accounts on the **NTLM-secured web application** displayed the following response:

**Q5: What is the message displayed by the web application when authenticating with a valid credential pair?**
📝 **Answer:** `Hello World`

![Successful Authentication](.github/screenshots/Screenshot_20250223_130815.png)  

---

## **4. LDAP Pass-Back Attack**

We found a printer settings page at printer.za.tryhackme.com/settings, which sends information to a server:

![Printer Settings](.github/screenshots/Screenshot_20250223_131411.png)  

We try to intercept using a **Netcat Listener** and changing the server information to our IP but only receive encrypted credentials:

![Printer Settings Interception](.github/screenshots/Screenshot_20250223_131538.png)  

Next, we targeted **LDAP authentication vulnerabilities** by setting up a **rogue LDAP server** to capture plaintext credentials.

![LDAP Configuration](.github/screenshots/Screenshot_20250223_131608.png)  
![LDAP Capture Setup](.github/screenshots/Screenshot_20250223_131702.png)  

Then, we adjusted the olcSaslSecProps.ldif to use plaintext credentials.

![olc configure](.github/screenshots/Screenshot_20250223_131833.png)  
![Restart using configuration](.github/screenshots/Screenshot_20250223_131856.png) 
![verifying configuration](.github/screenshots/Screenshot_20250223_131916.png)

Then, we set up a tcpdump to listen for the credentials:

![tcpdump listener](.github/screenshots/Screenshot_20250223_131942.png)  

**Q6: What type of attack can be performed against LDAP Authentication systems not commonly found against Windows Authentication systems?**
📝 **Answer:** `ldap pass-back attack`

We allowed **`login` and `plain` authentication mechanisms** to force unencrypted logins.

Captured credentials:
- **Username:** `svcLDAP`
- **Password:** `tryhackmeldappass1@`

![Captured Credentials](.github/screenshots/Screenshot_20250223_132003.png)  

---

## **5. NTLM Authentication Poisoning**

To capture **NTLM authentication hashes**, we deployed **Responder**.

**Q9: What is the name of the tool we can use to poison and capture authentication requests on the network?**
📝 **Answer:** `responder`

![Responder Setup](.github/screenshots/Screenshot_20250223_132043.png)  

Captured credentials (Didn't get the original screenshot):

![Responder Interception](.github/screenshots/Screenshot_20250223_132115.png)
![Responder Interception](.github/screenshots/Screenshot_20250223_132158.png)

Then, using hashcat, we decrypted the user credentials:

![Hashcat](.github/screenshots/Screenshot_20250223_132234.png)


- **Username:** `svcFileCopy`
- **Cracked Password:** `FPassword1!`

---

## **6. PXE Boot Image Credential Extraction**

We would normally receive the IP for the MDT server via DHCP, but since it's provided in the network diagram, we already have it:

![pxe server](.github/screenshots/Screenshot_20250223_133627.png)  

We then ssh into the thmjmp1 machine using the password **Password1@**

![SSH connection](.github/screenshots/Screenshot_20250223_133720.png)  

From there, we create a directory for ourselves and copy over the PowerPXE script:

![pxe script](.github/screenshots/Screenshot_20250223_133754.png)  

Then, referencing the x64 file, we noticed in the browser, we copy that into our new directory:

![mdt file](.github/screenshots/Screenshot_20250223_133834.png)  

Now, we can easily find the path to the MDT image file, copy it to our directory using tftp, and extract any credentials.

![Image file](.github/screenshots/Screenshot_20250223_133903.png)  
![Extracted Credentials](.github/screenshots/Screenshot_20250223_134019.png)  

Using **TFTP**, we retrieved PXE Boot configuration files to extract credentials.

**Q12: What Microsoft tool is used to create and host PXE Boot images in organisations?**
📝 **Answer:** `Microsoft Deployment Toolkit`

**Q13: What network protocol is used for recovery of files from the MDT server?**
📝 **Answer:** `TFTP`

Extracted credentials:
- **Username:** `svcMDT`
- **Password:** `PXEBootSecure1@`  

---

## **7. Configuration File Credential Extraction**

Upon enumerating the file system, we found a McAfee **`ma.db`** database and using scp, downloaded it to our machine.

![McAfee Database](.github/screenshots/Screenshot_20250223_134322.png)  
![scp Download](.github/screenshots/Screenshot_20250223_134343.png)

We then used an sqlitebrowser to enumerate the database and found credentials stored in the **AGENT_REPOSITORIES** database

![sqlitebrowser](.github/screenshots/Screenshot_20250223_134405.png)
![agent-repositories database](.github/screenshots/Screenshot_20250223_134427.png)

We then decrypted **AUTH_PASSWD** using a python script found at: ![Mcafee-sitelist-pwd-decryption](https://github.com/funoverip/mcafee-sitelist-pwd-decryption):

![Python Decryption](.github/screenshots/Screenshot_20250223_134552.png)

**Q18: What table in this database stores the credentials of the orchestrator?**
📝 **Answer:** `AGENT_REPOSITORIES`

- **Username:** `svcAV`
- **Password:** `MyStrongPassword!` 

---

## **8. Conclusion & Lessons Learned**

### **Key Findings:**
- Weak passwords enabled **password spraying attacks**.
- **LDAP authentication** was vulnerable to **pass-back attacks**, exposing plaintext credentials.
- **NTLM authentication poisoning** allowed **credential interception and cracking**.
- **PXE boot images stored credentials**.
- **McAfee database contained stored credentials**, which were easily decrypted.

### **Mitigation Strategies:**
✅ Enforce strong passwords & eliminate default credentials  
✅ Disable NTLM authentication where possible  
✅ Enforce LDAP signing & channel binding  
✅ Restrict access to PXE boot files and encrypt stored credentials  
✅ Secure configuration files by hashing and salting stored passwords  

🚀 **TryHackMe link to challenge: ![Breaching AD](https://tryhackme.com/room/breachingad)**
