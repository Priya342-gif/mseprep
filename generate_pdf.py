import os

def create_pdf(filepath):
    # Minimal valid single-page PDF generator
    stream_content = """BT
/F2 16 Tf
50 740 Td
(MSE-2: Software Engineering and DevOps - Morning Shift) Tj
0 -22 Td
/F1 11 Tf
(Practical Examination: Docker Containerization & Orchestration) Tj
0 -30 Td
/F2 12 Tf
(1. Student Information) Tj
0 -18 Td
/F1 10 Tf
(Name: Priya               University Roll Number: 2428cseaiml148) Tj
0 -15 Td
(Section: AIML-B           Branch: Computer Science & Engineering - AIML) Tj
0 -15 Td
(GitHub: Priya342-gif      Docker Hub Username: priya111222333) Tj
0 -26 Td
/F2 12 Tf
(2. GitHub Repository Details) Tj
0 -18 Td
/F1 10 Tf
(Repository Fork URL: https://github.com/Priya342-gif/mseprep) Tj
0 -15 Td
(Working Branch: main) Tj
0 -15 Td
(Application URL: http://localhost:8080      Backend Health: http://localhost:3000/health) Tj
0 -26 Td
/F2 12 Tf
(3. Published Docker Hub Images) Tj
0 -18 Td
/F1 10 Tf
(Backend:  priya111222333/taskflow-backend:latest) Tj
0 -15 Td
(Frontend: priya111222333/taskflow-frontend:latest) Tj
0 -26 Td
/F2 12 Tf
(4. Implementation Deliverables & Verification Checklist) Tj
0 -18 Td
/F1 9 Tf
([x] Task 1: frontend/Dockerfile (Multi-stage Node 20 build + Nginx 1.27 reverse proxy)) Tj
0 -14 Td
([x] Task 1: backend/Dockerfile (Node 20 alpine, non-root user node, port 3000)) Tj
0 -14 Td
([x] Task 2: docker-compose.yml (Orchestrates Postgres 16, Redis 7, Backend, Frontend)) Tj
0 -14 Td
([x] Task 2: Healthchecks for Postgres, Redis, and Backend services) Tj
0 -14 Td
([x] Task 2: Persistent PostgreSQL storage via named volume postgres_data) Tj
0 -14 Td
([x] Task 2: Redis caching verified with user tasks list cache & invalidation) Tj
0 -14 Td
([x] Task 3: Docker Hub image publishing configuration and tags) Tj
0 -14 Td
([x] Task 4: docker-compose.deploy.yml (Pure image-based deployment without build:)) Tj
0 -14 Td
([x] Automation: Single-command script run_all.sh with execution.log output) Tj
0 -14 Td
([x] GitHub Actions: CI/CD workflows cd.yml & ci.yml configured for student fork) Tj
0 -26 Td
/F2 12 Tf
(5. Academic Integrity Declaration) Tj
0 -18 Td
/F1 9 Tf
(\\"I hereby declare that the submitted Docker implementation is my own work.) Tj
0 -13 Td
(I have successfully executed and verified the required CI/CD pipeline stages,) Tj
0 -13 Td
(published the Docker images to my Docker Hub account, and tested the application deployment.\\") Tj
0 -30 Td
/F1 8 Tf
(Student Signature: Priya (2428cseaiml148)                Date: 18-Nov-2026) Tj
ET"""

    stream_bytes = stream_content.encode('latin1')
    stream_len = len(stream_bytes)

    objects = []
    # 1: Catalog
    objects.append(b"<< /Type /Catalog /Pages 2 0 R >>")
    # 2: Pages
    objects.append(b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>")
    # 3: Page
    objects.append(b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>")
    # 4: F1
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")
    # 5: F2
    objects.append(b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>")
    # 6: Contents stream
    objects.append(b"<< /Length " + str(stream_len).encode('ascii') + b" >>\nstream\n" + stream_bytes + b"\nendstream")

    pdf_data = bytearray(b"%PDF-1.4\n")
    offsets = [0]
    for i, obj in enumerate(objects, 1):
        offsets.append(len(pdf_data))
        pdf_data.extend(f"{i} 0 obj\n".encode('ascii'))
        pdf_data.extend(obj)
        pdf_data.extend(b"\nendobj\n")

    xref_offset = len(pdf_data)
    pdf_data.extend(f"xref\n0 {len(objects) + 1}\n".encode('ascii'))
    pdf_data.extend(b"0000000000 65535 f \n")
    for off in offsets[1:]:
        pdf_data.extend(f"{off:010d} 00000 n \n".encode('ascii'))

    pdf_data.extend(f"trailer\n<< /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF\n".encode('ascii'))

    with open(filepath, 'wb') as f:
        f.write(pdf_data)
    print(f"Created PDF: {filepath}")

if __name__ == '__main__':
    create_pdf('G:/mse222222/mseprep/2428cseaiml148_Priya.pdf')
    create_pdf('G:/mse222222/2428cseaiml148_Priya.pdf')
