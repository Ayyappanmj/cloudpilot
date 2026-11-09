# Convenience targets for WSL2/Linux/macOS. On plain Windows PowerShell use scripts/*.ps1 instead.
.PHONY: install lint test docker-build run mode-dev mode-k8s mode-gitops mode-monitoring mode-complete clean
install:        ; python -m pip install -r requirements-dev.txt
lint:           ; ruff check .
test:           ; pytest
docker-build:   ; docker build -f docker/Dockerfile -t cloudpilot-sample:local .
run:            ; docker compose up -d --build
mode-dev:       ; bash scripts/switch-mode.sh 1
mode-k8s:       ; bash scripts/switch-mode.sh 2
mode-gitops:    ; bash scripts/switch-mode.sh 3
mode-monitoring:; bash scripts/switch-mode.sh 4
mode-complete:  ; bash scripts/switch-mode.sh 5
clean:          ; bash scripts/cleanup.sh --all
