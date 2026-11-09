# Kubernetes details

- **Access:** Kind maps host `127.0.0.1:8080` -> node port 30080 -> Service `cloudpilot:8000`. Fallback: `kubectl port-forward -n cloudpilot svc/cloudpilot 8080:8000`.
- **Defaults (low-spec):** 1 replica; requests 50m/64Mi; limits 250m/192Mi; rolling update `maxUnavailable: 0, maxSurge: 1`.
- **Probes:** startup `/healthz` (up to 60 s), liveness `/healthz`, readiness `/readyz`.
- **Pod security:** non-root 10001, `readOnlyRootFilesystem`, `drop: [ALL]`, `allowPrivilegeEscalation: false`, seccomp RuntimeDefault, no hostPath/Docker socket,
  `/tmp` as a 16 Mi emptyDir, service account token not mounted. The namespace enforces Pod Security `restricted`.
- **NetworkPolicy:** ingress only on 8000; egress only DNS. Kind's default CNI may not enforce policies - the manifest is valid and
  would be enforced by Calico/Cilium. Enforcement is **not demonstrated** here.

## HPA (optional - needs metrics-server)
Not installed by default (saves RAM; avoids an unneeded add-on).
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.7.2/components.yaml
kubectl patch deployment metrics-server -n kube-system --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'   # Kind-only workaround
kubectl top nodes        # verify (can take ~1 min)
helm upgrade cloudpilot deploy/helm/cloudpilot -n cloudpilot --reuse-values --set autoscaling.enabled=true
```
`--kubelet-insecure-tls` is acceptable only for local Kind. The namespace quota (10 pods, 500m CPU requests) caps scale-out at roughly 3 replicas.

## Rolling update demo (Mode 2)
```bash
scripts/deploy-local.sh                       # revision 1
# change something in app/, then:
scripts/deploy-local.sh                       # new image tag -> revision 2
kubectl rollout status deploy/cloudpilot -n cloudpilot
helm history cloudpilot -n cloudpilot ; scripts/rollback.sh helm
```
## Canary and blue-green (optional, documented - not implemented as manifests)
- A normal rolling update is **not** a canary. True canary (e.g. 10% of traffic) needs a traffic-splitting layer such as Argo Rollouts
  with an ingress/service mesh - out of scope for 8 GB.
- A crude *replica-ratio* canary is possible: a second Deployment with the same Service-selecting label and 1 replica next to 9 stable
  ones gives roughly 10% - but that is an approximation (needs 10 pods; your quota allows 10).
- Blue-green: run two Deployments (`blue`, `green`), point the Service selector at one, switch with `kubectl patch svc`. Doubles memory
  during the switch.
