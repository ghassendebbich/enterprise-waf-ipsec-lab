# Enterprise Multi-Site Network Security & Dual WAF Lab

This repository contains the complete network topology, configuration files, and validation procedures for an enterprise-grade multi-site security architecture deployed inside **EVE-NG**.

The lab demonstrates inline **Web Application Firewall (WAF)** payload inspection across an encrypted **IPsec VPN tunnel**, comparing enterprise **FortiWeb** signature blocking against **ModSecurity** and an uninspected baseline path.

---

## 📐 Architecture Topology

```text
+------------------------------------------------------------------------------------------------+
|                                    SITE 1: HEADQUARTERS & DC                                  |
|                                                                                                |
|  +--------------------+      +--------------------+      +----------------------------------+  |
|  | VLAN 50: WAF Subnet|      | VLAN 60: Backend   |      | Core LAN Segmented Departments   |  |
|  | - FortiWeb (10.0.100.1)  | DVWA Web Server  |      | - VLAN 10 (DEV): 10.10.10.0/24  |  |
|  | - ModSec   (10.0.100.30)| | (10.10.60.20)     |      | - VLAN 20 (IT) : 10.10.20.0/24  |  |
|  +---------+----------+      +---------+----------+      | - VLAN 30 (HR) : 10.10.30.0/24  |  |
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
|                                         |  FortiGate-1   | (172.29.18.51)                         |
|                                         +--------+-------+                                       |
+--------------------------------------------------|-----------------------------------------------+
                                                   | IPsec VPN Tunnel (IKEv2)
                                                   | (172.29.18.0/24 Subnet)
+--------------------------------------------------|-----------------------------------------------+
|                                         +--------+-------+                                       |
|                                         |  FortiGate-2   | (172.29.18.61)                         |
|                                         +--------+-------+                                       |
|                                                  |                                               |
|                                         +--------+-------+                                       |
|                                         |   Branch LAN   | Flat Subnet (10.2.0.0/24)             |
|                                         | (Site 2 Office)|                                       |
|                                         +----------------+                                       |
|                                      SITE 2: BRANCH OFFICE                                       |
+------------------------------------------------------------------------------------------------+
```

---

## 📊 Addressing & Access Matrix

| Host / Virtual IP | Network Interface / Port | Target IP & Port | Inspection Profile |
| :--- | :--- | :--- | :--- |
| **FortiWeb Virtual Server** | `172.29.18.51:10443` | `10.0.100.11:80` | Inline Inspection (FortiWeb WAF) |
| **ModSecurity WAF** | `172.29.18.51:10444` | `10.0.100.30:80` | Inline Inspection (ModSecurity OWASP CRS) |
| **Unprotected Bypass Path** | `172.29.18.51:10445` | `10.10.60.20:80` | **Direct Control Host (No WAF)** |
| **FortiWeb Management GUI** | `172.29.18.51:8443` | `10.0.100.1:443` | Out-of-band Management Access |

---

## 🔒 Security Proof-of-Concept Scenarios

### Scenario A: Uninspected Direct Control Baseline (Port 10445)
- **Execution:** Payload submitted to `http://172.29.18.51:10445/vulnerabilities/sqli/`.
- **Result:** **Exploit Successful**. Payload passes straight to backend host `10.10.60.20`, returning full database records.

### Scenario B: FortiWeb Inline Protection (Port 10443)
- **Execution:** Payload submitted to `http://172.29.18.51:10443/vulnerabilities/sqli/`.
- **Result:** **Blocked**. FortiWeb intercepts payload inline and returns perimeter `Web Page Blocked!` response.

### Scenario C: ModSecurity Engine Protection (Port 10444)
- **Execution:** Payload submitted to `http://172.29.18.51:10444/vulnerabilities/sqli/`.
- **Result:** **Blocked**. ModSecurity returns `403 Forbidden` response.

---

## 🛠️ Verification Script

Run the automated test script from Site 2:

```bash
chmod +x scripts/test-payloads.sh
./scripts/test-payloads.sh
```

---

## 🚀 Quick Setup & Deployment

Clone the repository:
```bash
git clone https://github.com/ghassendebbich/enterprise-waf-ipsec-lab.git
cd enterprise-waf-ipsec-lab
```
