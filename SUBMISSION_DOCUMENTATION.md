# Practical Exam Submission: Docker & DevOps (AI310B) - Morning Shift

## 1. Student Information
- **Full Name:** Priya
- **University Roll Number:** 2428cseaiml148
- **Section:** AIML-B
- **Branch:** CSE-AIML
- **GitHub Username:** Priya342-gif
- **Docker Hub Username:** priya342

---

## 2. GitHub Submission Details
- **GitHub Repository URL (personal fork):** `https://github.com/Priya342-gif/mseprep`
- **GitHub branch used for implementation:** `main`
- **Application URL:** `http://localhost:8080`
- **Backend Health URL:** `http://localhost:3000/health`

---

## 3. Docker Hub Details
- **Docker Hub Username:** `priya342`
- **Frontend Docker Image URL:** `https://hub.docker.com/r/priya342/taskflow-frontend`
- **Backend Docker Image URL:** `https://hub.docker.com/r/priya342/taskflow-backend`
- **Docker Images Published:**
  - `priya342/taskflow-frontend:latest`
  - `priya342/taskflow-backend:latest`

---

## 4. Implementation Checklist
- [x] Frontend Dockerfile implemented (`frontend/Dockerfile`)
- [x] Backend Dockerfile implemented (`backend/Dockerfile`)
- [x] Multi-service Compose implemented (`docker-compose.yml`)
- [x] Published image deployment Compose implemented (`docker-compose.deploy.yml`)
- [x] Frontend image published to Docker Hub (`priya342/taskflow-frontend`)
- [x] Backend image published to Docker Hub (`priya342/taskflow-backend`)
- [x] PostgreSQL persistence verified (`postgres_data` named volume)
- [x] Redis caching verified (`tasks:user:<id>` cached in Redis)
- [x] Application functionality tested (Jest/Supertest TC01-TC12)
- [x] CD pipeline configured and verified (`.github/workflows/cd.yml`)
- [x] Latest changes committed and pushed
- [x] Executable automation script created (`run_all.sh`) with `execution.log` output

---

## 5. Architecture & Container Orchestration Overview

### Services Configuration:
1. **Frontend Service (`frontend`):**
   - Multi-stage build: `node:20-alpine` builds the React/Vite app; `nginx:1.27-alpine` serves static files on port 80.
   - Host Port Mapping: `8080:80`.
   - Reverse proxy in `nginx.conf` proxies `/api/` and `/health` requests to `http://backend:3000`.

2. **Backend Service (`backend`):**
   - Base image: `node:20-alpine`, non-root user `node`.
   - Host Port Mapping: `3000:3000`.
   - Communicates with PostgreSQL (`postgres:5432`) and Redis (`redis:6379`) via Docker network bridge (`app-network`).
   - Healthcheck: polls `http://localhost:3000/health`.

3. **PostgreSQL Service (`postgres`):**
   - Image: `postgres:16-alpine`.
   - Data persistence: Docker volume `postgres_data` mounted to `/var/lib/postgresql/data`.
   - Initialization: `./backend/db/init.sql` mounted to `/docker-entrypoint-initdb.d/init.sql`.
   - Healthcheck: `pg_isready -U taskflow_user -d taskflow`.

4. **Redis Service (`redis`):**
   - Image: `redis:7-alpine`.
   - In-memory cache for user task lists with automatic invalidation on mutation.
   - Healthcheck: `redis-cli ping`.

---

## 6. Execution Evidence Guide for Screenshots

When running `./run_all.sh` using Git Bash, capture the following required screenshots for Moodle / Exam submission:

1. **GitHub Actions Workflow Execution:**
   - Screenshot of the GitHub Actions CD workflow passing all stages in green.
2. **Docker Hub Authentication:**
   - Terminal showing `docker login` success or GitHub Actions login step.
3. **Backend Image Build & Publishing:**
   - Output of `docker build` and `docker push priya342/taskflow-backend:latest`.
4. **Frontend Image Build & Publishing:**
   - Output of `docker build` and `docker push priya342/taskflow-frontend:latest`.
5. **Docker Compose Image Pull:**
   - Output of `docker compose -f docker-compose.deploy.yml pull`.
6. **Application Deployment:**
   - Output of `docker compose -f docker-compose.deploy.yml up -d` and `docker compose ps`.
7. **Backend Health Check:**
   - Browser / curl showing `{"status":"ok","postgres":"ok","redis":"ok"}` at `http://localhost:3000/health`.
8. **Frontend Accessibility Verification:**
   - Browser showing TaskFlow React UI at `http://localhost:8080`.
9. **Final Successful CI/CD Pipeline Status:**
   - Overview of the GitHub Actions run summary showing all green checks.

---

## 7. Declaration
"I hereby declare that the submitted Docker implementation is my own work. I have successfully executed and verified the required CI/CD pipeline stages, published the Docker images to my Docker Hub account, and tested the application deployment."
