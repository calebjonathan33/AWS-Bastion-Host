#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_FILE="${SCRIPT_DIR}/../logs/resources-id.txt"

if [[ -z "${BAS_SG_ID:-}" && -f "${RESOURCE_FILE}" ]]; then
	source "${RESOURCE_FILE}"
fi

if [[ -z "${BAS_SG_ID:-}" ]]; then
	echo "Error: BAS_SG_ID is not set. Export it or provide logs/resources-id.txt"
	exit 1
fi

CURRENT_IP="$(curl -s https://checkip.amazonaws.com)/32"
OLD_IP="$(aws ec2 describe-security-groups --group-ids "${BAS_SG_ID}" --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`].IpRanges[0].CidrIp' --output text)"

if [[ "${OLD_IP}" == "${CURRENT_IP}" ]]; then
	echo "No change: ${CURRENT_IP} already whitelisted"
	exit 0
fi

if [[ -n "${OLD_IP}" && "${OLD_IP}" != "None" ]]; then
	aws ec2 revoke-security-group-ingress --group-id "${BAS_SG_ID}" --protocol tcp --port 22 --cidr "${OLD_IP}" >/dev/null 2>&1 || true
fi

aws ec2 authorize-security-group-ingress --group-id "${BAS_SG_ID}" --protocol tcp --port 22 --cidr "${CURRENT_IP}" >/dev/null 2>&1
echo "Updated bastion SG from ${OLD_IP:-none} to ${CURRENT_IP}"
