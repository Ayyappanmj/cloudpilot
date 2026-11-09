# Plain Kubernetes manifests (reference / learning path)

The deployed path (Argo CD and `deploy-local`) uses the **Helm chart** in `deploy/helm/cloudpilot`.
These manifests are the same application written out by hand so you can read every field.

```bash
kubectl apply -k deploy/kubernetes/base        # app resources
kubectl apply -f deploy/kubernetes/optional/   # HPA (needs metrics-server) and PDB
```
`bootstrap/` (Namespace, ResourceQuota, LimitRange) is for people who skip Terraform. If Terraform already
created the namespace, **do not** apply `bootstrap/`. Do not apply these manifests AND install the Helm
chart/Argo CD app into the same namespace - pick one owner.
