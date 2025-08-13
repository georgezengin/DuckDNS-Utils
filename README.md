# DuckDNS Update Scripts

Scripts to update your DuckDNS domains with the current public IP address or a specified IP.  
Includes both a PowerShell and a Bash version.

---

## 1. DuckDNS Update Script (PowerShell)

Updates your DuckDNS domains via the DuckDNS API. Writes an entry in the Windows Application Event Log.

### Usage
````markdown


.\duckdns_update.ps1 -Domains "<domain1,domain2,...>" -Token "<your-duckdns-token>" [-IP "<custom-ip>"] [-DryRun] [-NoEventLog] [-Debug] [-Help]
````

### Parameters

| Parameter            | Description                                                                                                              |
| ------------------   | ------------------------------------------------------------------------------------------------------------------------ |
| `-Domains`           | Comma-separated list of DuckDNS domains to update.                                                                       |
| `-Token`             | Your DuckDNS API token.                                                                                                  |
| `-IP`                | (Optional) Specific IP address to set. If omitted, the script auto-detects your public IP using `https://api.ipify.org`. |
| `-DryRun`            | Simulates the update without making changes.                                                                             |
| `-DisableEventLog`   | Disables writing to the Windows Event Log.                                                                               |
| `-DebugConsole`      | Enables verbose debug output in the console.                                                                             |
| `-Help`              | Displays detailed help and usage information.                                                                            |

### Examples

```powershell


# Update multiple domains with auto-detected IP
.\duckdns_update.ps1 -Domains "example1,example2" -Token "123abc456def"

# Update a domain with a specific IP in dry-run mode
.\duckdns_update.ps1 -Domains "example" -Token "123abc456def" -IP "1.2.3.4" -DryRun
```

---

## 2. DuckDNS Update Script (Bash)

Bash script to update DuckDNS domains similarly. Writes an entry in the syslog.

### Usage

```bash
./duckdns_update.sh -d <domain1,domain2,...> -t <your-duckdns-token> [-i <custom-ip>] [-dry-run] [-help]
```

### Parameters

| Parameter   | Description                                                              |
| ----------- | ------------------------------------------------------------------------ |
| `-d`        | Comma-separated DuckDNS domains to update.                               |
| `-t`        | DuckDNS API token.                                                       |
| `-i`        | (Optional) IP address to set. If omitted, script auto-detects public IP. |
| `-dry-run`  | Shows the update URLs without sending requests.                          |
| `-help`     | Displays usage info.                                                     |

### Examples

```bash
# Update domains with auto-detected IP
./duckdns_update.sh -d example1,example2 -t 123abc456def

# Update a domain with specific IP in dry-run mode
./duckdns_update.sh -d example -t 123abc456def -i 1.2.3.4 -dry-run
```

---

## Scheduling

### PowerShell Script on Windows

Use Task Scheduler to run the script periodically.

Windows Task Scheduler setup instructions in Markdown:

# Schedule PowerShell Script Every 30 Minutes on Windows

1. Open **Task Scheduler** (Win+R: taskschd.msc) or use Win+S to search.
2. Click **Create Basic Task...** and enter a name, e.g., ` DuckDNS Update `.  
3. For the trigger, choose **Daily**, then set the start date and time.  
4. On the next page, check **Repeat task every:** and select ` 30 minutes `, then set **for a duration of:** to ` Indefinitely `.  
5. For the action, choose **Start a program**.  
6. In **Program/script:** enter:  ` powershell.exe `
7. In **Add arguments (optional):** enter: ` -ExecutionPolicy Bypass -File "C:\path\to\duckdns\_update.ps1" -Domains "example" -Token "123abc456def" `
8. Complete the wizard and save the task.  

### Bash Script on Linux/WSL

Use cron to schedule updates.
Example: cron entry to run the script every 30 minutes:

```bash
*/30 * * * * /path/to/duckdns_update.sh -d example -t 123abc456def

```

---

## Requirements

* PowerShell 5.1+ for the PowerShell script.
* Bash (Linux, macOS, or WSL) for the Bash script.
* Internet connection to reach DuckDNS and `https://api.ipify.org`.

---

## License

  The license file is the **GNU General Public License (GPL) Version 2, June 1991**. Here’s a summary of its key points:
  
  - **Freedom to Use, Modify, and Distribute:**  
    You can freely use, copy, modify, and distribute the software and its source code.
  
  - **Copyleft Requirement:**  
    If you distribute modified versions or derivative works, you must also distribute the source code under the same GPL license. This means all derivatives remain free and open.
  
  - **No Warranty:**  
    The software is provided "as-is," without any warranty, and the authors are not liable for any damages arising from its use.
  
  - **Redistribution Terms:**  
    You must include the same license and copyright notices when redistributing the software or derivatives.  
    You may charge a fee for physical transfer or warranty protection, but not for the software itself.
  
  - **Patent Clause:**  
    Any patent rights associated with the software must be licensed for everyone’s free use, or not licensed at all.
  
  - **Versioning:**  
    If the software specifies "Version 2 or any later version," you may use any later version of the GPL published by the Free Software Foundation.
  
  - **How to Apply:**  
    The license includes instructions for developers on how to apply the GPL to their own programs.
  
  **In short:**  
  You can use, modify, and share the software freely, but any redistributed or derivative works must also be licensed under the GPL, and there is no warranty.

---
