## Initial Enumeration

Performed a comprehensive port scan to identify open services:

```bash
nmap -sCV -T4 -p- $IP -oN enu/nmap-services.md
```

![Nmap Scan Results](.github/screenshots/dvr4-nmap-scan.png)

**Notable Services:**

- SSH (Port 22)  
- SMB (Port 445)  
- HTTP Proxy (Port 8080)  
- RPC (Port 135)

---

### SMB and RPC Null Sessions

Attempted to establish null sessions with SMB and RPC services:

![SMB Null Session Denied](.github/screenshots/dvr4-smb-rpc-null.png)

---

### HTTP Enumeration

Navigated to the web service running on port 8080 and encountered the Argus Surveillance dashboard:

![Argus Surveillance Dashboard](.github/screenshots/dvr4-argus-ui.png)

Initiated a directory search alongside manual exploration:

```bash
dirsearch -u http://$IP:8080
```

---

## Initial Foothold

Identified several accessible directories:

- /about.html  
- /options.html  
- /stats.html  
- /users.html

On the /users.html page, functionalities to add users, change access levels, and update passwords were available but lacked immediate utility. Proceeded to further enumeration.

Utilized `searchsploit` to identify potential vulnerabilities associated with the Argus Surveillance software:

![SearchSploit Results](.github/screenshots/dvr4-searchsploit.png)

A directory traversal vulnerability was particularly noteworthy:

![Directory Traversal Exploit](.github/screenshots/dvr4-dir-traversal-poc.png)

Considering the open SSH port and the user `viewer` found on the web interface, attempted to retrieve SSH keys using the vulnerability:

![Retrieving SSH Keys](.github/screenshots/dvr4-dir-traversal-key.png)

Successfully obtained the private SSH key and established a shell:

![Initial Shell Access](.github/screenshots/dvr4-initial-shell.png)

---

## Privilege Escalation

Checked current user privileges and group memberships:

![User Privileges](.github/screenshots/dvr4-whoami-all.png)

No interesting privileges were discovered. Looked into installed programs but found nothing noteworthy.

Revisited `searchsploit` and identified a weak password encryption vulnerability. Investigated if Argus stored passwords in plaintext or reversible format.

Used the following command to search for password references:

```bash
findstr /SIM /C:"password" *.ini *.cfg *.config *.xml
```

Discovered `DVRParams.ini` with encrypted credentials:

![Viewer Password](.github/screenshots/dvr4-ini-hash-viewer.png)  
![Administrator Password](.github/screenshots/dvr4-ini-hash-admin.png)

Used the weak encryption decryptor script to recover:

![Decrypt Viewer](.github/screenshots/dvr4-decrypt-viewer.png)  
![Decrypt Admin](.github/screenshots/dvr4-decrypt-admin.png)

Guessed the final special character in the decrypted admin password and validated it using `runas`:

![Successful Runas](.github/screenshots/dvr4-runas-success.png)

Downloaded and used netcat to pop a reverse shell:

![Download Netcat](.github/screenshots/dvr4-certutil-nc-download.png)  
![Start Listener](.github/screenshots/dvr4-nc-listen.png)

Obtained a SYSTEM shell:

![Runas Shell](.github/screenshots/dvr4-runas-shell.png)  
![SYSTEM Shell](.github/screenshots/dvr4-system-access-confirm.png)

---

## Lessons Learned

- Directory traversal can expose sensitive assets like private SSH keys.
- Weak encryption of credentials allows attackers to escalate privileges.
- `searchsploit` and manual recon remain crucial tools for exploitation.
- When password cracking fails, inference and trial/error can still lead to success.
- Always audit configurations for hardcoded or weakly protected secrets.

