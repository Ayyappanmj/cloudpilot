# Windows 10/11 setup (beginner friendly)

Commands marked **PowerShell** run in Windows PowerShell/Terminal (not as admin unless stated). Commands marked **Bash** run inside a WSL2 Ubuntu terminal.

## 1. Enable WSL2 (PowerShell, as Administrator, then reboot)
```powershell
wsl --install
wsl --set-default-version 2
```
## 2. Install tools with winget (PowerShell)
```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Docker.DockerDesktop -e        # then start it; Settings > General: "Use WSL 2 based engine"
winget install --id Python.Python.3.11 -e
winget install --id Kubernetes.kubectl -e
winget install --id Kubernetes.kind -e
winget install --id Helm.Helm -e
winget install --id Hashicorp.Terraform -e
```
Open a **new** PowerShell window afterwards so PATH updates apply. (No winget? Use the official download pages for each tool.)

## 3. Limit WSL2 memory (important on 8 GB)
Create `%UserProfile%\.wslconfig` - see `docs/HARDWARE_REQUIREMENTS.md`, then `wsl --shutdown` and restart Docker Desktop.

## 4. Verify (PowerShell)
```powershell
git --version; python --version; docker --version; docker info --format '{{.MemTotal}}'
kubectl version --client; kind version; helm version --short; terraform version
```
All commands must print a version. If `docker info` errors, start Docker Desktop and wait for "Engine running".

## 5. Allow the project's scripts (PowerShell, once)
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
Or run one script at a time: `powershell -ExecutionPolicy Bypass -File scripts\setup-kind.ps1`.

## 6. Python environment (PowerShell, in the project folder)
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
ruff check .
pytest
```
Run the app without Docker: `uvicorn app.main:app --reload` then open http://localhost:8000/docs.

## 7. Simple explanations
- **Docker image / container:** the packaged app / a running copy of it.
- **Kind:** runs a whole Kubernetes cluster inside one Docker container on your laptop.
- **kubectl:** the command-line remote control for Kubernetes.
- **Helm:** "package manager" that fills a template with your settings and installs the app.
- **Terraform:** describes infrastructure (here: namespaces and quotas) in files and creates it with `plan`/`apply`.
- **Argo CD:** watches a Git repository and makes the cluster match it (GitOps).
- **Prometheus / Grafana:** collects numbers from the app / draws graphs from them.
