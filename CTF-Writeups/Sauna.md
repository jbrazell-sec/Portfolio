From Exposure to Domain Admin
Active Directory remains one of the most commonly targeted components in enterprise environments, yet many compromises still begin with surprisingly small oversights. This writeup walks through the compromise of a retired Windows domain lab, focusing not just on the tools used, but on the decisions that shaped the attack path.

Rather than relying on a single critical vulnerability, this environment fell due to a chain of misconfigurations: exposed employee information, a Kerberos account without preauthentication, insecure credential storage, and excessive Active Directory permissions. Each issue on its own may appear low-risk, but together they resulted in full Domain Admin access.

The goal of this writeup is to document that progression clearly, highlighting both offensive methodology and defensive lessons that apply well beyond CTF environments.

🔍 Network Enumeration (Nmap)
A full TCP scan revealed a classic Windows Active Directory environment, including:

DNS (53)
HTTP (80)
Kerberos (88)
LDAP / LDAPS (389 / 636)
SMB (445)
WinRM (5985)
The presence of Kerberos, LDAP, and SMB immediately suggested that Active Directory attacks would be the primary focus rather than pure web exploitation.

Press enter or click to view image in full size

Nmap scan
🌐 Web Enumeration
Browsing port 80 revealed a static banking website with several informational sections:

/index.html
/contact.html
/about.html → Employee names listed
/blog.html
The About page was especially valuable, as it leaked employee names that could be converted into potential domain usernames.

Press enter or click to view image in full size

Names exposed on website
👤 Username Generation
Using the employee names, I generated a wordlist with common AD naming conventions:

FirstLast
First.Last
First
FLast
This list was later used for Kerberos-based attacks.

Press enter or click to view image in full size

Custom User list
🔥 AS-REP Roasting (Initial Access)
Since Kerberos was exposed, I tested the user list for AS-REP roastable accounts (users with Do not require Kerberos preauthentication set).

impacket-GetNPUsers EGOTISTICAL-BANK.LOCAL/ -no-pass -usersfile users -dc-ip $IP | grep -v 'KDC_ERR_C_PRINCIPAL_UNKNOWN'
This successfully returned a Kerberos hash for the user fsmith.

Press enter or click to view image in full size

🔓 Password Cracking
The AS-REP hash was cracked using John the Ripper:

john hashes --format=krb5asrep --wordlist=/usr/share/wordlists/rockyou.txt
Result:

fsmith : Thestrokes23
Press enter or click to view image in full size

🖥️ Remote Access Confirmation
With valid credentials, I confirmed remote access via WinRM:

nxc winrm $IP -u fsmith -p 'Thestrokes23'
Press enter or click to view image in full size

Then obtained an interactive shell:

evil-winrm -i $IP -u fsmith -p 'Thestrokes23'
Press enter or click to view image in full size

⬆️ Privilege Escalation
🔎 Local Enumeration
After manual enumeration yielded little, I uploaded WinPEAS to identify misconfigurations.

Become a member
WinPEAS revealed AutoLogon credentials stored in the registry for a service account:

svc_loanmgr : Moneymakestheworldgoround!
This immediately suggested credential reuse or delegated privilege abuse.


🧠 Active Directory Enumeration (BloodHound)
While enumerating locally, I simultaneously collected domain data using RustHound:

rusthound --domain EGOTISTICAL-BANK.LOCAL -u fsmith@egotistical-bank.local -p 'Thestrokes23' -i $IP --dc-only
BloodHound analysis showed that svc_loanmgr possessed:

DS-Replication-Get-Changes
DS-Replication-Get-Changes-All
These permissions allow DCSync attacks, effectively letting the account impersonate a Domain Controller.

Press enter or click to view image in full size

🧬 DCSync Attack (Domain Compromise)
Using the recovered service account credentials, I performed a DCSync attack with Impacket:

impacket-secretsdump EGOTISTICAL-BANK.LOCAL/svc_loanmgr:'Moneymakestheworldgoround!'@sauna.egotistical-bank.local
This dumped domain password hashes, including Administrator.

Press enter or click to view image in full size

🏁 Domain Admin Access
Finally, I authenticated as Administrator using pass-the-hash:

evil-winrm -i $IP -u Administrator -H 823452073d75b9d1cf70ebdf86c7f98e
This resulted in full Domain Admin access.

Press enter or click to view image in full size

🧠 Takeaways
AS-REP Roasting remains a powerful initial access vector when Kerberos preauthentication is misconfigured.
Employee name leaks on public-facing websites can directly lead to domain compromise.
AutoLogon credentials are extremely dangerous, especially for service accounts.
DCSync privileges should be treated as Domain Admin–equivalent.
BloodHound remains invaluable for identifying non-obvious AD attack paths.
🛡️ Defensive Notes
Enforce Kerberos preauthentication on all users.
Audit registry-stored credentials regularly.
Monitor for GetChanges permissions outside Domain Admins.
Alert on suspicious secretsdump-like replication activity.
