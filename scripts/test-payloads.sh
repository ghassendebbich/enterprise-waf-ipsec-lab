#!/usr/bin/env bash
# ==============================================================================
# Automated WAF Proof-of-Concept Payload Validation Script
# ==============================================================================

TARGET_IP="172.29.18.51"
SQL_PAYLOAD="Submit=%27+OR+%271%27%3D%271"

echo "------------------------------------------------------------------------"
echo "1. Testing Control Host (Unprotected Port 10445)..."
curl -s -o /dev/null -w "HTTP Response Code: %{http_code}
"   "http://${TARGET_IP}:10445/vulnerabilities/sqli/?id=${SQL_PAYLOAD}"

echo "------------------------------------------------------------------------"
echo "2. Testing FortiWeb Inline WAF (Protected Port 10443)..."
curl -s "http://${TARGET_IP}:10443/vulnerabilities/sqli/?id=${SQL_PAYLOAD}" | grep -i "Web Page Blocked" \
  && echo "[SUCCESS] FortiWeb Interception Verified!"

echo "------------------------------------------------------------------------"
echo "3. Testing ModSecurity WAF (Protected Port 10444)..."
curl -s -o /dev/null -w "HTTP Response Code: %{http_code}
"   "http://${TARGET_IP}:10444/vulnerabilities/sqli/?id=${SQL_PAYLOAD}"
echo "------------------------------------------------------------------------"
