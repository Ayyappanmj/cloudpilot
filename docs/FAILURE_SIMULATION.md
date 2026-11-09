# Failure simulations

Run these in Mode 2 or 4 (Helm owns the app) unless stated. Each is reversible. Namespace `cloudpilot`, deployment `cloudpilot`.
Baseline: `kubectl get pods -n cloudpilot` shows `1/1 Running`.

## 1. Container crashes
- **Reproduce:** `kubectl exec -n cloudpilot deploy/cloudpilot -- python -c "import os,signal; os.kill(1, signal.SIGTERM)"`
- **Detect:** `kubectl get pods -n cloudpilot` -> RESTARTS increments; Grafana "Container restart count"; alert `CloudPilotPodRestarting` after >2.
- **Root cause:** PID 1 stopped; kubelet restarts the container (restartPolicy Always).
- **Resolve:** nothing needed for a single restart; for repeats read `kubectl logs deploy/cloudpilot -n cloudpilot --previous`.
- **Verify:** pod `1/1 Running`, `curl localhost:8080/readyz` returns 200.

## 2. Incorrect image tag
- **Reproduce:** `kubectl set image deploy/cloudpilot cloudpilot=cloudpilot-sample:doesnotexist -n cloudpilot`
- **Detect:** new pod `ErrImageNeverPull` (local chart uses `pullPolicy: Never`); `kubectl describe pod`; old pod keeps serving because `maxUnavailable: 0`.
- **Root cause:** image not present in the node / tag typo.
- **Resolve:** `kubectl rollout undo deploy/cloudpilot -n cloudpilot` (or `scripts/rollback.sh helm`).
- **Verify:** `kubectl rollout status deploy/cloudpilot -n cloudpilot`.

## 3. CrashLoopBackOff
- **Reproduce:** `kubectl set env deploy/cloudpilot CLOUDPILOT_MAX_SLOW_MS=999999 -n cloudpilot`
- **Detect:** pod status `CrashLoopBackOff`; `kubectl logs <pod> -n cloudpilot` shows a pydantic validation error (value must be <= 10000).
- **Root cause:** invalid configuration fails settings validation at startup (fail-fast by design). Old pod keeps serving during the rollout.
- **Resolve:** `kubectl set env deploy/cloudpilot CLOUDPILOT_MAX_SLOW_MS- -n cloudpilot` or `scripts/rollback.sh helm`. (Under Argo CD self-heal reverts it automatically - good GitOps demo, Mode 3.)
- **Verify:** pod Running, restarts stop increasing.

## 4. Readiness probe fails
- **Reproduce:** `helm upgrade cloudpilot deploy/helm/cloudpilot -n cloudpilot --reuse-values --set config.CLOUDPILOT_SIMULATE_NOT_READY=true`
- **Detect:** new pod `0/1 Running`; `kubectl describe pod` -> "Readiness probe failed: HTTP probe failed with statuscode: 503"; `curl` on `/readyz` -> 503 with checks JSON. Liveness is fine, so no restart.
- **Root cause:** app reports not-ready; Service withholds traffic; rollout stalls (old pod still serves).
- **Resolve:** `helm rollback cloudpilot -n cloudpilot` or re-upgrade with `=false`.
- **Verify:** `1/1 Running`, `/readyz` 200.

## 5. Application returns HTTP 500
- **Reproduce (needs fault injection - on in values-local):** `1..30 | % { curl.exe -s -o NUL http://localhost:8080/api/v1/simulate-error }`
- **Detect:** Grafana "HTTP 5xx per second"; PromQL `sum(rate(http_requests_total{job="cloudpilot",status=~"5.."}[5m]))`; alert `CloudPilotHigh5xxRate` after 5 min of sustained >5% (keep sending traffic).
- **Root cause:** controlled error endpoint. **Resolve:** stop traffic; in real life fix the code and roll back. **Verify:** 5xx rate returns to 0, alert resolves.

## 6. Image pull fails
- **Reproduce:** `kubectl set image deploy/cloudpilot cloudpilot=ghcr.io/no-such-user-xyz/none:1 -n cloudpilot` and `kubectl patch deploy cloudpilot -n cloudpilot -p '{"spec":{"template":{"spec":{"containers":[{"name":"cloudpilot","imagePullPolicy":"Always"}]}}}}'`
- **Detect:** `ErrImagePull` -> `ImagePullBackOff`; `kubectl describe pod` events show pull denied/not found. In Mode 3 the same appears when the GHCR package is still private.
- **Root cause:** wrong name/tag or missing credentials. **Resolve:** `kubectl rollout undo deploy/cloudpilot -n cloudpilot`; for private packages see docs/GITOPS.md. **Verify:** pod Running.

## 7. Argo CD synchronization fails (Mode 3)
- **Reproduce:** in `gitops/environments/local/values.yaml` set `service.type: Bogus`, commit, push.
- **Detect:** `kubectl get application cloudpilot -n argocd` -> `OutOfSync`/`Degraded`; `kubectl get application cloudpilot -n argocd -o jsonpath='{.status.operationState.message}'` mentions the invalid Service type; Argo retries 3 times.
- **Root cause:** API server rejects the rendered manifest. Running pods are untouched.
- **Resolve:** `scripts/rollback.sh git` (revert) and push. **Verify:** Application `Synced`/`Healthy`.

## 8. GitOps manifest contains invalid YAML (Mode 3)
- **Reproduce:** add a line with a tab indent or an unclosed bracket (`config: [`) to the values file, commit, push.
- **Detect:** Application condition `ComparisonError`: `kubectl get application cloudpilot -n argocd -o jsonpath='{.status.conditions[*].message}'`. Locally, `helm lint deploy/helm/cloudpilot -f gitops/environments/local/values.yaml` fails; CI catches this on pull requests.
- **Root cause:** Helm cannot render. Cluster keeps the last good state. **Resolve:** revert/fix and push. **Verify:** condition disappears, `Synced`.

## 9. Resource limits prevent pod creation
- **Reproduce:** `kubectl set resources deploy/cloudpilot -n cloudpilot --requests=memory=600Mi --limits=memory=800Mi`
- **Detect:** no new pod appears; `kubectl describe rs -n cloudpilot` -> `FailedCreate ... exceeded quota: default-quota` (quota requests.memory is 512Mi). (If requests are within quota but exceed node capacity you would instead see `Pending` with `FailedScheduling: Insufficient memory`.)
- **Root cause:** ResourceQuota (Terraform) doing its job. **Resolve:** `kubectl rollout undo deploy/cloudpilot -n cloudpilot`. **Verify:** pods Running; `kubectl describe quota -n cloudpilot` shows usage.

## 10. Prometheus stops seeing the app
- **Reproduce:** `kubectl scale deploy/cloudpilot -n cloudpilot --replicas=0`
- **Detect:** Prometheus Targets page has no `cloudpilot` target; Grafana availability panel shows No data; `CloudPilotDown` fires after 2 min (`absent(up{job="cloudpilot"})`).
- **Root cause:** nothing to scrape. Variants: wrong pod label or port name (the scrape job keeps only pods labelled `app.kubernetes.io/name=cloudpilot` with a port named `http`).
- **Resolve:** `kubectl scale deploy/cloudpilot -n cloudpilot --replicas=1`. **Verify:** target UP within ~30-60 s, alert resolves. (Under Argo CD self-heal restores replicas by itself.)
