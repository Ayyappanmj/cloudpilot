"""Deployment details injected by Kubernetes (downward API). No secrets are read here."""

import os


def get_deployment_info(git_commit: str) -> dict:
    return {
        "pod": os.environ.get("POD_NAME", os.environ.get("HOSTNAME", "unknown")),
        "namespace": os.environ.get("POD_NAMESPACE", "unknown"),
        "git_commit": git_commit,
    }
