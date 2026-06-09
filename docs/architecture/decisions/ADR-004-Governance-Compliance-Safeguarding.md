# ADR 004: Document Governance, Compliance, and Safeguarding

**Status:** Approved

---

## Context

The Secure Document Ingestion and Governance Platform accepts document, image, and video uploads from citizens and external systems. Processing these files involves substantial compliance, security, and legal obligations:
1. **GDPR and Data Sovereignty:** Uploaded documents contain personal data. I must ensure data residency (UK regions), prevent unauthorized data exfiltration, enforce data minimisation, and maintain an immutable audit trail.
2. **Online Safety Act and CSEA Content Reporting:** Under the Online Safety (CSEA Content Reporting) Regulations 2026, I have a legal obligation to scan, detect, and preserve illegal content for evidence (1-year retention), without deleting files during active investigations.
3. **Staff Duty of Care:** Safeguarding officers who review flagged content are exposed to potentially graphic, distressing, or illegal material. I must protect their psychological safety and ensure they never download malicious files onto their personal devices.
4. **Secure-by-Default Pipeline:** I must prevent any raw file from reaching permanent storage before validation.

## Decision

I decided to implement a multi-stage gated governance and compliance architecture:

1. **Transient Holding and Quarantine Isolation:** 
   * Files are initially uploaded to a transient **Holding Bucket** with a 3–5 day lifecycle purge failsafe. 
   * Only clean files that pass virus and content scanning are transferred to the primary **File Store**. 
   * Flagged files are moved by the Security Workflow to a restricted **Quarantine Bucket** and preserved for exactly **1 year** for evidentiary purposes, bypassing the standard holding lifecycle.
2. **Staff Illbeing Controls (Security UI):**
   * The **Security UI** restricts how flagged files are vieId. Files are rendered as low-resolution, greyscale thumbnails hidden behind a mandatory warning message.
   * Files are served strictly via **Signed URLs or Base64 strings**, completely preventing direct local downloads to an officer's workstation.
3. **Data Sovereignty and Security Isolation:**
   * All storage and compute infrastructure is pinned to the UK region (`europe-Ist2`).
   * Permanent storage (File Store, Quarantine, Firestore, Security Logs) is isolated inside a **VPC Service Control** perimeter.
   * Google-managed encryption keys and Data Loss Prevention (DLP) are enforced across all buckets.
4. **Isolated Alerting Channels:**
   * An independent **Security Queue (Pub/Sub)** with a threshold of 0 routes security alerts immediately, keeping security incidents separate from general operational failures in the standard Dead-Letter Queue (DLQ).

## Consequences and Trade-offs

### Pros
* **Regulatory Alignment:** Satisfies GDPR requirements (minimisation, retention schedules, data protection by design) and Online Safety Act compliance (evidence preservation, no-purge rules).
* **Duty of Care:** Prioritizes employee psychological safety through strict UI rendering constraints (greyscale, low-res, blur/warnings, no direct downloads).
* **Zero-Trust Security:** Prevents unverified files from entering the primary File Store, mitigating malware and malicious content delivery.
* **Auditability:** Independent Security Logs provide a complete audit trail of scanning results and officer actions, simplifying reporting to authorities (e.g. NCA, IWF).

### Cons
* **Storage Overhead:** Retaining quarantined documents and structured security logs for 1 year incurs additional Cloud Storage costs.
* **Operational Ingestion Latency:** Gated validation (ClamAV scans folloId by Vision/Video/Document AI checks) introduces ingestion latency, requiring asynchronous queues (Cloud Tasks) for bulk uploads (3+ files).
* **Review Friction:** Security-focused UI safeguards (greyscale/low-res) may occasionally make manual classification more difficult for safeguarding officers, though this is a necessary compromise to protect their Illbeing.