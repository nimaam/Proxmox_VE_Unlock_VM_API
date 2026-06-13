#!/usr/bin/env python3

import re
import paramiko
from pathlib import Path

INVENTORY_FILE = "inventory.ini"

inventory_nodes = {}
problem_nodes = []
missing_nodes = set()


def parse_inventory(filename):
    nodes = {}

    with open(filename, "r") as f:
        for line in f:
            line = line.strip()

            if (
                not line
                or line.startswith("#")
                or line.startswith("[")
            ):
                continue

            parts = line.split()

            hostname = parts[0]
            data = {}

            for item in parts[1:]:
                if "=" in item:
                    k, v = item.split("=", 1)
                    data[k] = v

            nodes[hostname] = data

    return nodes


def ssh_run(host, user, password, command):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(
        paramiko.AutoAddPolicy()
    )

    client.connect(
        hostname=host,
        username=user,
        password=password,
        timeout=10,
    )

    stdin, stdout, stderr = client.exec_command(command)

    out = stdout.read().decode()
    err = stderr.read().decode()

    client.close()

    return out, err


inventory_nodes = parse_inventory(INVENTORY_FILE)

inventory_hostnames = set(inventory_nodes.keys())

for node_name, info in inventory_nodes.items():

    host = info.get("ansible_host")
    user = info.get("ansible_user", "root")
    password = info.get("ansible_password")

    print(f"Checking {node_name} ({host})")

    try:
        out, err = ssh_run(
            host,
            user,
            password,
            "pvecm nodes 2>/dev/null"
        )

        if not out.strip():
            continue

        cluster_nodes = set()

        for line in out.splitlines():

            m = re.match(
                r"^\s*\d+\s+(\S+)",
                line
            )

            if m:
                cluster_nodes.add(m.group(1))

        for cluster_node in cluster_nodes:
            if cluster_node not in inventory_hostnames:
                missing_nodes.add(
                    f"{node_name}: {cluster_node}"
                )

    except Exception as e:
        problem_nodes.append(
            f"{node_name} ({host}) : {str(e)}"
        )

with open("missed.txt", "w") as f:
    for item in sorted(missing_nodes):
        f.write(item + "\n")

with open("problem_connection.txt", "w") as f:
    for item in sorted(problem_nodes):
        f.write(item + "\n")

print("\nDone.")
print(f"Missing nodes: {len(missing_nodes)}")
print(f"Connection problems: {len(problem_nodes)}")
