## Initial Enumeration

As always, we begin with a comprehensive `nmap` service and version scan to identify all open ports and running services:

```bash
nmap -sCV -T4 -p- -Pn $IP -oN enu/nmap-services.md
```

This yielded a significant amount of information. Below is a summarized version of the results:

![Nmap Scan](.github/screenshots/medjed_full_nmap_scan_result.png)

### Notable Services Identified

- **SMB**
- **MySQL**
- **Multiple HTTP Instances**
- **FTP**
- **RPC**

The script scan results for the HTTP service indicated that the target is running **Windows OS**, which is also evident from the SMB and RPC ports being open:

![HTTP Nmap Script Scan](.github/screenshots/medjed_nmap_scan_barracuda.png)

---

### FTP Enumeration

The FTP service was found running on a non-standard port: **30021**. An attempt to log in anonymously was successful:

![FTP Anonymous Login](.github/screenshots/medjed_ftp_anonymous_login.png)

Despite access, browsing through the files didn’t reveal anything of immediate interest.

---

### SMB & RPC Enumeration

Tried using a null session to enumerate SMB and RPC, but both returned access denied errors. This suggests tighter restrictions on unauthenticated access.

---

### HTTP Enumeration

Navigating to the HTTP server running on port **8000** presented a **Barracuda dashboard** prompting the creation of an admin user:

![Barracuda Config Wizard](.github/screenshots/medjed_admin_account_created.png)

Visiting the "About" page revealed the **Barracuda version number**:

![Barracuda About Page](.github/screenshots/medjed_barracuda_about_page.png)

Searching on Exploit-DB, a known vulnerability associated with this version was discovered. This could later be used for privilege escalation:

![ExploitDB Entry](.github/screenshots/medjed_exploitdb_reference_alt.png)

---

## Initial Foothold

Further enumeration of the web application revealed access to a **Web File Server**:

![Web File Server UI](.github/screenshots/medjed_web_file_server_main.png)

Unexpectedly, this interface appeared to provide access to the **entire file system**:

![Root Access via File Manager](.github/screenshots/medjed_web_file_server_root_access.png)

Initially, I considered uploading a Lua reverse shell, but remembered from the `nmap` results that additional HTTP servers were running **Apache**. If we could locate the Apache configuration files, we could identify the web root and possibly upload a PHP reverse shell.

![Nmap Apache Servers](.github/screenshots/medjed_apache_enum_nmap_scan.png)

Eventually, the Apache configuration was located:

![Apache Conf Dir](.github/screenshots/medjed_apache_conf_dir_listing.png)  
![httpd.conf with Listen Port](.github/screenshots/medjed_httpd_conf_listen_directive.png)

PHP was confirmed, and the **htdocs** directory was found:

![htdocs Directory](.github/screenshots/medjed_htdocs_clean.png)

I uploaded [Ivan Sincek's PHP reverse shell](https://github.com/ivan-sincek/php-reverse-shell/blob/master/src/reverse/php_reverse_shell.php):

![Upload revshell.php](.github/screenshots/medjed_htdocs_with_shell.png)

Set up a listener:

![Listener Started](.github/screenshots/medjed_listener_before_shell.png)

Triggered the shell:

![Browser Hits Shell](.github/screenshots/medjed_php_reverse_shell_triggered.png)

Shell received:

![Shell as www-data](.github/screenshots/medjed_shell_obtained_as_www_user.png)

---

## Privilege Escalation

Rather than starting full manual enumeration, I revisited the **Barracuda exploit** previously found on Exploit-DB:

![Exploit Reference](.github/screenshots/medjed_exploitdb_entry.png)

I began by checking running services to see if the system was configured similarly:

```bash
wmic service get name,displayname,pathname,startmode
```

![Service Path](.github/screenshots/medjed_permissions_and_privs.png)

This confirmed the presence of the vulnerable service.

Next, I checked file and folder permissions:

![Permissions & Privileges](.github/screenshots/Medjed_service-perms.png)

Our user had write access to `bd.exe`, and `SeShutdownPrivilege` was enabled.

I renamed the original binary to `bd.exe.bak`:

![File Renamed](.github/screenshots/medjed_file_replaced_verified.png)

Generated a reverse shell payload with `msfvenom`:

![Payload Created](.github/screenshots/medjed_msfvenom_payload_generated.png)

Uploaded the payload via `certutil`:

![Upload Success 1](.github/screenshots/medjed_certutil_upload_success.png)  
![Upload Success 2](.github/screenshots/medjed_certutil_upload_success.png)


Scheduled a reboot using `shutdown /r`:

![Shutdown Issued](.github/screenshots/medjed_shutdown_triggered.png)

Listener waiting:

![Final Listener](.github/screenshots/medjed_listener_ready.png)

Received reverse shell as SYSTEM:

![SYSTEM Shell](.github/screenshots/medjed_priv_esc_success.png)

