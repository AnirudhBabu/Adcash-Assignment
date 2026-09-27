#!/usr/bin/env python3
"""
platform-cli
============
Lets a developer scaffold a production-ready, canary-deployed service
without hand-writing Kubernetes manifests, Argo Rollout specs, or
AnalysisTemplates. Generates GitOps-ready files under gitops/apps/<name>/
that ArgoCD picks up automatically once committed and pushed.
"""
import os
import argparse
from jinja2 import Template

ROLLOUT_TEMPLATE = """\
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: {{ app_name }}
  namespace: {{ environment }}
spec:
  replicas: {{ replicas }}
  strategy:
    canary:
      analysis:
        templates:
          - templateName: success-rate-analysis
        args:
          - name: service-name
            value: {{ app_name }}
      steps:
        - setWeight: 10
        - pause: { duration: 2m }
        - setWeight: 50
        - pause: { duration: 5m }
        - setWeight: 100
  selector:
    matchLabels:
      app: {{ app_name }}
  template:
    metadata:
      labels:
        app: {{ app_name }}
    spec:
      containers:
        - name: {{ app_name }}
          image: {{ image }}
          ports:
            - containerPort: {{ port }}
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: {{ app_name }}
  namespace: {{ environment }}
spec:
  ports:
    - port: {{ port }}
      targetPort: {{ port }}
  selector:
    app: {{ app_name }}
"""

ARGOCD_APP_TEMPLATE = """\
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ app_name }}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: {{ repo_url }}
    targetRevision: main
    path: gitops/apps/{{ app_name }}
  destination:
    server: https://kubernetes.default.svc
    namespace: {{ environment }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
"""


def generate_app(app_name, environment, image, port, replicas, repo_url):
    target_dir = f"gitops/apps/{app_name}"
    os.makedirs(target_dir, exist_ok=True)

    rollout_out = Template(ROLLOUT_TEMPLATE).render(
        app_name=app_name, environment=environment, image=image, port=port, replicas=replicas
    )
    with open(os.path.join(target_dir, "deployment.yaml"), "w") as f:
        f.write(rollout_out.strip() + "\n")

    app_out = Template(ARGOCD_APP_TEMPLATE).render(
        app_name=app_name, environment=environment, repo_url=repo_url
    )
    with open(os.path.join(target_dir, "application.yaml"), "w") as f:
        f.write(app_out.strip() + "\n")

    print(f"[SUCCESS] Scaffolded '{app_name}' at {target_dir}/")
    print(f"          Commit + push, then ArgoCD's App-of-Apps picks it up automatically.")


def main():
    parser = argparse.ArgumentParser(description="Adcash IDP Developer Self-Service CLI")
    subparsers = parser.add_subparsers(dest="command")

    create_parser = subparsers.add_parser("create-app", help="Scaffold a new canary-deployed microservice")
    create_parser.add_argument("--name", required=True)
    create_parser.add_argument("--env", default="staging")
    create_parser.add_argument("--image", required=True)
    create_parser.add_argument("--port", type=int, default=8080)
    create_parser.add_argument("--replicas", type=int, default=3)
    create_parser.add_argument("--repo-url", default="https://github.com/AnirudhBabu/Adcash-Assignment.git")

    args = parser.parse_args()
    if args.command == "create-app":
        generate_app(args.name, args.env, args.image, args.port, args.replicas, args.repo_url)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
