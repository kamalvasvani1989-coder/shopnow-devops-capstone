# Grafana dashboards

Every `*.json` file in this folder is loaded by Ansible as a ConfigMap labelled
`grafana_dashboard: "1"`; the Grafana sidecar imports it automatically on every new cluster.
Anything built only in the Grafana UI is lost at the nightly teardown - export it here.

| File | How to get it |
| --- | --- |
| `shopnow.json` | Included. Request rate, p95 latency, 5xx %, HPA replicas, pod CPU, AWS estimated charges. |
| `node-exporter-full.json` | Download dashboard ID **1860** from grafana.com (Download JSON). Replace `${DS_PROMETHEUS}` with `prometheus` if Grafana complains about the datasource. |
| `jenkins.json` | Search grafana.com for "Jenkins Prometheus", download the JSON, same datasource fix. |

Open Grafana: `kubectl -n monitoring port-forward svc/kps-grafana 3000:80` -> http://localhost:3000 (admin / the `grafana-admin` Jenkins credential).
