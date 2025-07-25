# 🧠 Adcash Assignment – SRE Engineering Challenge

This repo contains a complete solution for the DevOps Engineering assignment from Adcash. I have included a Node.js application with Prometheus metric exports (built-in to the web app), infrastructure configuration via Ansible, and container orchestration using Jinja2-based Kubernetes templates.

## 📦 Contents

- `server.js`: Express-based Node.js server with Prometheus metrics exposed via `/metrics`, time in colombo at the moment of loading via `/colombo`, and Gandalf's image at `/gandalf`
- `deployGandalf.yaml`: Playbook for deploying the Gandalf app and metrics exporter
- `configurePrometheus.yaml`: Ansible playbook to configure Prometheus VM created in final step of prior playbook (separation was necessary as the private key needed to be retrieved into GitHub's temporary runner env)
- `service.yaml.j2` & `deployment.yaml.j2`: Jinja2 Kubernetes templates
- `prometheus.yml`: Prometheus scrape config targeting Gandalf metrics
- `README.md`: This file!

## 🚀 Features

- ✅ Custom Prometheus metrics:  
  `node_gandalf_request_total` and `node_colombo_request_total` exported by the web app for visit counters
- ✅ Containerized Node.js app served on port `80` at [http://172.161.147.92/gandalf](http://172.161.147.92/gandalf) and [http://172.161.147.92/colombo](http://172.161.147.92/colombo)
- ✅ Prometheus server collects metrics from Gandalf via scrape job. Access UI at [Prometheus UI](http://135.225.122.9:9090/graph?g0.expr=node_gandalf_request_total%7Bjob%3D%22gandalf_scraper%22%7D&g0.tab=1&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h&g1.expr=node_colombo_request_total%7Bjob%3D%22gandalf_scraper%22%7D&g1.tab=1&g1.stacked=0&g1.show_exemplars=0&g1.range_input=1h)
- ✅ Configured using Ansible (chosen as YAML is easily understandable and usable)

## 📊 Metric Examples

Prometheus scrapes metrics provided by the web app at [http://172.161.147.92/metrics](http://172.161.147.92/metrics):

```text
# HELP node_gandalf_request_total The total number of GET requests received at /gandalf
# TYPE node_gandalf_request_total counter
node_gandalf_request_total{method="GET",path="/gandalf",status_code="200"} 10

# HELP node_colombo_request_total The total number of GET requests received at /colombo
# TYPE node_colombo_request_total counter
node_colombo_request_total{method="GET",path="/colombo",status_code="200"} 13
