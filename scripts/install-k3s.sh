#!/usr/bin/env bash
set -euo pipefail

# K3s server installation for a single-node EC2 lab/portfolio environment.
curl -sfL https://get.k3s.io | sh -

sudo kubectl get nodes
sudo kubectl get pods -A
