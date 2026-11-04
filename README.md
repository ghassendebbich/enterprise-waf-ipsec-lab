# Enterprise Multi-Site Network Security & Dual-WAF Lab

> **Internship Project Context:** This repository documents an enterprise network security lab designed and implemented inside **EVE-NG** during an internship at **3S – Standard Sharing Software**. 
> 
> **Notice:** The original physical/virtual lab environment was decommissioned upon internship completion and is no longer active or reachable. All configuration files and scripts herein serve as historical reference documentation and sanitized lab templates.

---

## 📌 Project Overview

This project implements and evaluates a dual Web Application Firewall (WAF) deployment across a multi-site enterprise network connected via an encrypted **IKEv2 IPsec VPN tunnel**. 

The primary goal of the lab was to conduct comparative threat testing between enterprise commercial WAF inspection (**FortiWeb**) and open-source WAF inspection (**ModSecurity with OWASP Core Rule Set**) against an uninspected baseline path.

---

## 📐 Architecture Topology

```text
+------------------------------------------------------------------------------------------------+
|                                    SITE 1: HEADQUARTERS & DC                                  |
|                                                                                                |
|  +--------------------+      +--------------------+      +----------------------------------+  |
|  | VLAN 50: WAF Subnet|      | VLAN 60: Backend   |      | Core LAN Segmented Departments   |  |
|  | - FortiWeb (10.0.100.1)  | DVWA Web Server    |      | - VLAN 10 (DEV): 10.10.10.0/24   |  |
|  | - ModSec   (10.0.100.30)| | (10.10.60.20)       |      | - VLAN 20 (IT) : 10.10.20.0/24   |  |
|  +---------+----------+      +---------+----------+      | - VLAN 30 (HR) : 10.10.30.0/24   |  |
|            |                           |                 | - VLAN 40 (MGMT): 10.10.40.0/24  |  |
|            +-------------+-------------+                 +----------------+-----------------+  |
|                          | Trunk (VLAN 50,60)                             | Trunk (10,20,30,40)|
|                     +----+----+                                      +----+----+                 |
|                     |  SW-DC  |                                      | SW-CORE |                 |
|                     +----+----+                                      +----+----+                 |
|                          |                                                |                      |
|                          +-----------------------+------------------------+                      |
|                                                  |                                               |
|                                         +--------+-------+                                       |
|                                         |  FortiGate-1   | (WAN: 172.29.18.51)                   |
|                                         +--------+-------+                                       |
+--------------------------------------------------|-----------------------------------------------+
                                                   | IPsec VPN Tunnel (IKEv2)
                                                   | (172.29.18.0/24 Subnet)
+--------------------------------------------------|-----------------------------------------------+
|                                         +--------+-------+                                       |
|                                         |  FortiGate-2   | (WAN: 172.29.18.61)                   |
|                                         +--------+-------+                                       |
|                                                  |                                               |
|                                         +--------+-------+                                       |
|                                         |   Branch LAN   | Flat Subnet (10.2.0.0/24)             |
|                                         | (Site 2 Office)| Staging Host: 10.2.0.10              |
|                                         +----------------+                                       |
|                                      SITE 2: BRANCH OFFICE                                       |
+------------------------------------------------------------------------------------------------+
```

---

## 📊 Network Addressing & Access Matrix

### VLAN & Subnet Allocations

| Location | Segment / VLAN | Subnet Range | Purpose |
| :--- | :--- | :--- | :--- |
| **Site 1 (HQ)** | VLAN 10 (DEV) | `10.10.10.0/24` | Software Development Department |
| **Site 1 (HQ)** | VLAN 20 (IT) | `10.10.20.0/24` | IT Support & Operations Department |
| **Site 1 (HQ)** | VLAN 30 (HR) | `10.10.30.0/24` | Human Resources Department |
| **Site 1 (HQ)** | VLAN 40 (MGMT) | `10.10.40.0/24` | Out-of-Band Network Management |
| **Site 1 (HQ)** | VLAN 50 (WAF) | `10.0.100.0/24` | Dedicated Reverse Proxy WAF Segment |
| **Site 1 (HQ)** | VLAN 60 (Backend)| `10.10.60.0/24` | Isolated Application Backend (DVWA) |
| **Site 2 (Branch)**| Branch LAN | `10.2.0.0/24` | Remote Branch Office Flat LAN |
| **Inter-Site WAN** | Public / Lab WAN | `172.29.18.0/24` | Edge Interconnect (FG-1: `.51`, FG-2: `.61`) |

### WAF Policy & Target Port Matrix

| Service Path | Public / VIP Port | Internal Target IP & Port | Inspection Mechanism / Profile |
| :--- | :--- | :--- | :--- |
| **FortiWeb WAF** | `172.29.18.51:10443` | `10.0.100.11:80` | Commercial Reverse Proxy WAF Policy |
| **ModSecurity WAF** | `172.29.18.51:10444` | `10.0.100.30:80` | Open-Source ModSecurity + OWASP CRS |
| **Unprotected Baseline**| `172.29.18.51:10445` | `10.10.60.20:80` | **Lab Baseline Only (Direct Pass-Through)** |
| **FortiWeb Admin** | `172.29.18.51:8443` | `10.0.100.1:443` | Management Console GUI Access |

---

## 🛡️ Security Infrastructure & Component Roles

### 1. FortiGate Firewalls (FortiGate-1 & FortiGate-2)
* **FortiGate-1 (HQ Edge):** Terminates the Site-to-Site IPsec VPN tunnel, performs inter-VLAN routing across internal departments, enforces perimeter firewall policies, and maps incoming Virtual IPs (VIPs) to appropriate WAF and backend services.
* **FortiGate-2 (Branch Edge):** Acts as the default gateway for Branch LAN users (`10.2.0.0/24`), routing all cross-site application traffic through the encrypted IPsec tunnel to HQ.

### 2. Site-to-Site IPsec VPN
* Built using **IKEv2** to secure all communication between Site 2 Branch hosts and Site 1 Data Center resources.
* Phase 2 selectors explicitly route traffic originating from `10.2.0.0/24` to both the backend subnet (`10.10.60.0/24`) and the WAF subnet (`10.0.100.0/24`).

### 3. Dual WAF Architecture
* **FortiWeb (Reverse Proxy):** Deployed on VLAN 50 (`10.0.100.1`). Receives traffic on VIP `10.0.100.11` and forwards clean requests to backend server `10.10.60.20`.
* **ModSecurity (OWASP CRS):** Deployed on VLAN 50 (`10.0.100.30`). Acts as an independent open-source reverse proxy running Apache/Nginx with OWASP CRS v3.x.
* **Independent Operation:** The WAF solutions operate on **separate, parallel reverse-proxy paths** for direct policy comparison. They are NOT chained in series or configured in High Availability (HA).

---

## 🧪 Web Application Security Testing & Observed Results

Testing was conducted by staging web attacks from the Site 2 Branch workstation (`10.2.0.10`) across the IPsec tunnel against the three distinct service ports on FortiGate-1.

```
       [Site 2 Branch Host (10.2.0.10)]
                     |
         (IKEv2 IPsec VPN Tunnel)
                     |
           [FortiGate-1 (HQ)]
                     |
    +----------------+----------------+
    |                |                |
Port 10443       Port 10444       Port 10445
    |                |                |
[FortiWeb WAF]  [ModSecurity]   [Direct Control]
 (Blocked!)      (Blocked!)       (Exploited!)
```

### Test Case 1: SQL Injection (SQLi)
* **Payload:** `Submit=%27+OR+%271%27%3D%271`
* **Port 10445 (Uninspected Baseline):** **Exploit Successful.** Request passed directly to DVWA (`10.10.60.20`), returning full database records.
* **Port 10443 (FortiWeb WAF):** **Blocked Inline.** FortiWeb intercepted the request, matched SQLi signatures, returned a `Web Page Blocked!` response, and logged the attack in the threat console.
* **Port 10444 (ModSecurity WAF):** **Blocked Inline.** ModSecurity matched OWASP CRS Rule 942100 (SQL Injection Attack), terminating the connection with HTTP `403 Forbidden`.

### Test Case 2: Cross-Site Scripting (XSS)
* **Payload:** `<script>alert('XSS-Test')</script>`
* **Port 10445 (Uninspected Baseline):** **Exploit Successful.** Script injected and stored/reflected by DVWA without sanitization.
* **Port 10443 (FortiWeb WAF):** **Blocked Inline.** Blocked by FortiWeb XSS protection profile.
* **Port 10444 (ModSecurity WAF):** **Blocked Inline.** Matched OWASP CRS Rule 941100 (XSS Attack), returning HTTP `403 Forbidden`.

---

## ⚠️ Security Warnings & Limitations

1. **IPsec Pre-Shared Key Placeholder:**
   The configuration files use the placeholder `REPLACE_WITH_YOUR_OWN_PSK`. **You MUST configure your own strong, unique pre-shared key on both FortiGate endpoints before establishing the VPN tunnel.**
2. **Legacy Cryptographic Proposals Warning:**
   The original lab configurations document legacy cryptographic proposals (`des-md5` / `des-sha1`). These proposals were preserved strictly to maintain historical fidelity with the lab implementation. **Do NOT reuse DES, MD5, or SHA-1 in production environments.** For production deployments, migrate to modern mutually supported algorithms (e.g., `aes256-sha256` or `aes256-gcm` with Diffie-Hellman Group 14 or higher).
3. **Lab-Only Uninspected Control Path:**
   Port 10445 exposes an uninspected path directly to DVWA. This is strictly a lab-only control mechanism designed to establish baseline exploitability and MUST NEVER be exposed in enterprise or production networks.
4. **Environment Decommissioning:**
   The EVE-NG lab environment has been decommissioned. These configuration files serve as reference documentation and have not been re-validated on active hardware following repository sanitization.

---

## 📁 Repository Structure

```text
enterprise-waf-ipsec-lab/
├── README.md                           # Main repository documentation
├── SECURITY.md                         # Security policy, sanitization notes & warnings
├── configs/
│   ├── firewalls/
│   │   ├── fortigate-1-hq.conf         # FortiGate-1 HQ Edge Firewall configuration
│   │   └── fortigate-2-branch.conf     # FortiGate-2 Branch Firewall configuration
│   ├── waf/
│   │   └── fortiweb-reverse-proxy.conf # FortiWeb WAF reverse proxy configuration
│   └── switches/
│       ├── sw-dc-cisco.cfg             # Cisco SW-DC switch configuration
│       └── sw-core-cisco.cfg           # Cisco SWITCH-CORE switch configuration
└── scripts/
    └── test-payloads.sh                # Bash automated payload testing script
```

---

## 🚀 Deployment & Configuration Placement

To deploy these configurations in a fresh lab environment:

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/ghassendebbich/enterprise-waf-ipsec-lab.git
   cd enterprise-waf-ipsec-lab
   ```

2. **Set Custom PSK in Firewall Configurations:**
   Edit `configs/firewalls/fortigate-1-hq.conf` and `configs/firewalls/fortigate-2-branch.conf`, replacing `"REPLACE_WITH_YOUR_OWN_PSK"` with your generated PSK:
   ```fortinet
   set psksecret "[REDACTED]"
   ```

3. **Apply Switch Configurations:**
   Load `configs/switches/sw-dc-cisco.cfg` onto your Datacenter Cisco Switch and `configs/switches/sw-core-cisco.cfg` onto your Core Switch via console or SSH.

4. **Apply Firewall Configurations:**
   Import or paste the CLI configuration snippets into FortiGate-1 and FortiGate-2 appliances.

5. **Execute Validation Script:**
   From a Linux workstation on Site 2 Branch LAN (`10.2.0.0/24`):
   ```bash
   chmod +x scripts/test-payloads.sh
   ./scripts/test-payloads.sh
   ```
