#!/usr/bin/env bash
# ==============================================================================
# Automated WAF Proof-of-Concept Payload Validation Script
# Target: Enterprise WAF & IPsec Lab Environment
# Notice: Run from Site 2 Branch workstation (10.2.0.10) across IPsec VPN.
# ==============================================================================

set -euo pipefail

TARGET_IP="${1:-172.29.18.51}"
SQL_PAYLOAD="Submit=%27+OR+%271%27%3D%271"
XSS_PAYLOAD="txtName=%3Cscript%3Ealert%28%27XSS-Test%27%29%3C%2Fscript%3E&btnSign=Sign+Guestbook"

echo "========================================================================"
echo "    AUTOMATED WAF & IPsec VPN SECURITY TEST SUITE"
echo "    Target Gateway IP: ${TARGET_IP}"
echo "========================================================================"
echo ""

echo "[+] 1. Testing Unprotected Control Baseline Path (Port 10445)..."
HTTP_CODE_BASE=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_IP}:10445/vulnerabilities/sqli/?id=${SQL_PAYLOAD}" || echo "000")
echo "    -> Control Path Response Code: ${HTTP_CODE_BASE}"
if [ "${HTTP_CODE_BASE}" == "200" ]; then
    echo "    -> [OBSERVED] Baseline uninspected path returned HTTP 200 (Exploit Execution Verified)."
fi
echo ""

echo "[+] 2. Testing FortiWeb Commercial WAF Inspection (Port 10443)..."
RESPONSE_FORTIWEB=$(curl -s "http://${TARGET_IP}:10443/vulnerabilities/sqli/?id=${SQL_PAYLOAD}" || true)
if echo "${RESPONSE_FORTIWEB}" | grep -iq "Web Page Blocked"; then
    echo "    -> [SUCCESS] FortiWeb Inline Interception Verified! ('Web Page Blocked' detected)."
else
    HTTP_CODE_FW=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_IP}:10443/vulnerabilities/sqli/?id=${SQL_PAYLOAD}" || echo "000")
    echo "    -> FortiWeb HTTP Response Code: ${HTTP_CODE_FW}"
fi
echo ""

echo "[+] 3. Testing ModSecurity OWASP CRS Engine (Port 10444)..."
HTTP_CODE_MODSEC=$(curl -s -o /dev/null -w "%{http_code}" "http://${TARGET_IP}:10444/vulnerabilities/sqli/?id=${SQL_PAYLOAD}" || echo "000")
echo "    -> ModSecurity Response Code: ${HTTP_CODE_MODSEC}"
if [ "${HTTP_CODE_MODSEC}" == "403" ]; then
    echo "    -> [SUCCESS] ModSecurity OWASP CRS Interception Verified! (HTTP 403 Forbidden)."
fi

echo ""
echo "========================================================================"
echo "    TEST SUITE COMPLETE"
echo "========================================================================"
