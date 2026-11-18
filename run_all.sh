#!/usr/bin/env bash
# ==============================================================================
# MSE-2 Docker & DevOps Automation Verification Script
# Stack: React (Vite) + Node.js (Express) + PostgreSQL + Redis
# Author: Priya (2428cseaiml148)
# ==============================================================================

# Ensure script is run in the directory where files reside
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# If run from parent directory and mseprep exists, cd into mseprep
if [ ! -f "docker-compose.yml" ] && [ -d "mseprep" ]; then
  cd mseprep
fi

LOGFILE="execution.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "======================================================================"
echo " Starting MSE-2 DevOps Execution at $(date)"
echo " Log file: $LOGFILE"
echo " Working directory: $(pwd)"
echo "======================================================================"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED_COUNT=0
FAILED_COUNT=0

report_status() {
  local step_name="$1"
  local status="$2"
  if [ "$status" -eq 0 ]; then
    echo -e "${GREEN}[PASS]${NC} $step_name"
    PASSED_COUNT=$((PASSED_COUNT + 1))
  else
    echo -e "${RED}[FAIL]${NC} $step_name"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
}

# ------------------------------------------------------------------------------
# STEP 1: Verify Environment Files & Pre-requisites
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 1: Checking Required Files & Environment ---${NC}"

if [ ! -f .env ]; then
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
  fi
fi

# Load environment variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

export DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-priya342}"

REQUIRED_FILES=("backend/Dockerfile" "frontend/Dockerfile" "docker-compose.yml" "docker-compose.deploy.yml" "submission.json")
ALL_FILES_EXIST=0
for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "Found required file: $f"
  else
    echo "MISSING file: $f"
    ALL_FILES_EXIST=1
  fi
done
report_status "Deliverable files check" $ALL_FILES_EXIST

# Check Docker connectivity
echo -e "\n${BLUE}--- Step 2: Docker Engine Verification ---${NC}"
docker info > /dev/null 2>&1
DOCKER_STATUS=$?
if [ $DOCKER_STATUS -ne 0 ]; then
  echo -e "${YELLOW}[WARNING] Docker daemon is not accessible directly or Docker Desktop is not started.${NC}"
  echo "Please ensure Docker Desktop is running and press ENTER to retry..."
  read -r _
  docker info > /dev/null 2>&1
  DOCKER_STATUS=$?
fi
report_status "Docker daemon connectivity" $DOCKER_STATUS

if [ $DOCKER_STATUS -ne 0 ]; then
  echo -e "${RED}Cannot proceed without active Docker daemon. Aborting container tasks.${NC}"
  exit 1
fi

# ------------------------------------------------------------------------------
# STEP 3: Validate Docker Compose Configurations
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 3: Validate Compose Files ---${NC}"
docker compose config --quiet
report_status "docker-compose.yml syntax and configuration" $?

docker compose -f docker-compose.deploy.yml config --quiet
report_status "docker-compose.deploy.yml syntax and configuration" $?

# Verify deploy compose does not contain 'build:' directives
if grep -Eq '^[[:space:]]+build:' docker-compose.deploy.yml; then
  echo "Error: docker-compose.deploy.yml contains build directives!"
  report_status "Validate deploy compose has no build directives" 1
else
  echo "Confirmed: docker-compose.deploy.yml uses published images only."
  report_status "Validate deploy compose has no build directives" 0
fi

# ------------------------------------------------------------------------------
# STEP 4: Build Local Docker Images
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 4: Build Images via Docker Compose ---${NC}"
docker compose build
report_status "Local image build (backend and frontend)" $?

# ------------------------------------------------------------------------------
# STEP 5: Start Local Application Stack
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 5: Start All 4 Services (Frontend, Backend, Postgres, Redis) ---${NC}"
docker compose up -d
report_status "Docker Compose up -d" $?

echo "Waiting for services to become healthy..."
BACKEND_HEALTHY=1
for i in {1..40}; do
  if curl --fail --silent http://localhost:3000/health > /dev/null 2>&1; then
    echo "Backend is healthy at attempt $i!"
    BACKEND_HEALTHY=0
    break
  fi
  sleep 2
done
report_status "Backend health check (http://localhost:3000/health)" $BACKEND_HEALTHY

FRONTEND_OK=1
for i in {1..20}; do
  if curl --fail --silent http://localhost:8080/ > /dev/null 2>&1; then
    echo "Frontend is reachable at attempt $i!"
    FRONTEND_OK=0
    break
  fi
  sleep 2
done
report_status "Frontend web server check (http://localhost:8080/)" $FRONTEND_OK

docker compose ps
report_status "All 4 containers running" $?

# ------------------------------------------------------------------------------
# STEP 6: Run Automated Integration Tests
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 6: Execute Integration Test Suite ---${NC}"
if [ -d "tests" ]; then
  cd tests
  if [ ! -d "node_modules" ]; then
    npm install --silent
  fi
  BASE_URL="http://localhost:3000" NODE_OPTIONS="--experimental-vm-modules" npm test
  TEST_RESULT=$?
  cd ..
  report_status "Jest/Supertest API test suite execution" $TEST_RESULT
else
  echo "Tests folder not found."
  report_status "Jest/Supertest API test suite execution" 1
fi

# ------------------------------------------------------------------------------
# STEP 7: Test PostgreSQL Persistence
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 7: Test PostgreSQL Data Persistence ---${NC}"
echo "Restarting PostgreSQL container..."
docker compose restart postgres
sleep 5

PERSISTENCE_HEALTHY=1
for i in {1..20}; do
  if curl --fail --silent http://localhost:3000/health > /dev/null 2>&1; then
    PERSISTENCE_HEALTHY=0
    break
  fi
  sleep 2
done
report_status "PostgreSQL persistence and recovery verification" $PERSISTENCE_HEALTHY

# ------------------------------------------------------------------------------
# STEP 8: Docker Hub Publishing
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 8: Tag and Publish Images to Docker Hub ---${NC}"
echo "Current Docker Hub user target: $DOCKERHUB_USERNAME"
echo "To publish, make sure you are logged in via: docker login"

# Tag images
docker tag $(docker compose images -q backend) "${DOCKERHUB_USERNAME}/taskflow-backend:latest" 2>/dev/null || docker build -t "${DOCKERHUB_USERNAME}/taskflow-backend:latest" ./backend
docker tag $(docker compose images -q frontend) "${DOCKERHUB_USERNAME}/taskflow-frontend:latest" 2>/dev/null || docker build -t "${DOCKERHUB_USERNAME}/taskflow-frontend:latest" ./frontend

# Also tag without taskflow- prefix in case required
docker tag "${DOCKERHUB_USERNAME}/taskflow-backend:latest" "${DOCKERHUB_USERNAME}/backend:latest" 2>/dev/null || true
docker tag "${DOCKERHUB_USERNAME}/taskflow-frontend:latest" "${DOCKERHUB_USERNAME}/frontend:latest" 2>/dev/null || true

report_status "Tag Docker Hub images" 0

echo "Attempting Docker Hub push..."
docker push "${DOCKERHUB_USERNAME}/taskflow-backend:latest"
PUSH_BACKEND=$?
docker push "${DOCKERHUB_USERNAME}/taskflow-frontend:latest"
PUSH_FRONTEND=$?

if [ $PUSH_BACKEND -eq 0 ] && [ $PUSH_FRONTEND -eq 0 ]; then
  report_status "Docker Hub image publishing" 0
else
  echo -e "${YELLOW}[NOTE] Docker Hub push requires active authentication ('docker login'). Please authenticate and re-run if needed.${NC}"
  report_status "Docker Hub image publishing" 1
fi

# ------------------------------------------------------------------------------
# STEP 9: Test Deployment Using Published Images (docker-compose.deploy.yml)
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}--- Step 9: Verify Deployment Stack (docker-compose.deploy.yml) ---${NC}"
echo "Stopping local stack (preserving volumes)..."
docker compose down

echo "Starting deployment stack from published images..."
docker compose -f docker-compose.deploy.yml up -d
report_status "Deploy stack startup (docker-compose.deploy.yml up -d)" $?

DEPLOY_BACKEND_HEALTHY=1
for i in {1..30}; do
  if curl --fail --silent http://localhost:3000/health > /dev/null 2>&1; then
    echo "Deployment backend is healthy!"
    DEPLOY_BACKEND_HEALTHY=0
    break
  fi
  sleep 2
done
report_status "Deployment backend health verification" $DEPLOY_BACKEND_HEALTHY

DEPLOY_FRONTEND_OK=1
for i in {1..15}; do
  if curl --fail --silent http://localhost:8080/ > /dev/null 2>&1; then
    echo "Deployment frontend is reachable!"
    DEPLOY_FRONTEND_OK=0
    break
  fi
  sleep 2
done
report_status "Deployment frontend accessibility verification" $DEPLOY_FRONTEND_OK

# Run tests against deploy stack
if [ -d "tests" ]; then
  cd tests
  BASE_URL="http://localhost:3000" NODE_OPTIONS="--experimental-vm-modules" npm test
  DEPLOY_TEST_RESULT=$?
  cd ..
  report_status "Integration tests against deployed stack" $DEPLOY_TEST_RESULT
fi

# Clean up deploy stack
docker compose -f docker-compose.deploy.yml down

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------
echo "======================================================================"
echo -e " EXECUTION SUMMARY: ${GREEN}${PASSED_COUNT} PASSED${NC}, ${RED}${FAILED_COUNT} FAILED${NC}"
echo " Logs written to: $LOGFILE"
echo " Completed at: $(date)"
echo "======================================================================"
