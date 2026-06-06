# ADR 003: Ingestion Pipeline Orchestration and Queueing

**Status:** Approved

---

## Context

The Secure Document Ingestion and Governance Platform must coordinate a multi-stage file verification pipeline. This pipeline involves:
1. Validating the file in a transient holding storage.
2. Routing the file to virus scanning (ClamAV).
3. Routing to file-type-specific AI content APIs (Vision, Video Intelligence, or Document AI).
4. Committing valid files to the File Store, or routing failures to the Security Workflow.
5. Updating transaction state in Firestore and delivering notifications.

Furthermore, we must support two ingestion patterns:
* **Synchronous Route:** Immediate verification for small uploads (1–2 files).
* **Asynchronous Route:** Batch uploads (3+ files) that must not saturate downstream APIs and must support retries, rate limiting, and webhook callbacks.

We need an orchestration solution that is highly available, resilient, serverless, and easy to define and version control, without the overhead of maintaining persistent worker infrastructure (e.g., Temporal or custom queue managers).

## Decision

We decided to use **Google Cloud Workflows** (defined declaratively in **YAML**) for step-by-step service orchestration, integrated with **Google Cloud Tasks** to handle batch queuing, rate limiting, and retries for the asynchronous upload route.

* **Cloud Workflows (YAML):** Manages the core ingestion pipeline logic, ensuring that conditional execution (pass/fail gates, error handling, security escalation) is strictly enforced.
* **Cloud Tasks:** Acts as the entry queue for the asynchronous route. When a batch upload of 3+ files is received, the API Server splits the batch and queues each file as an individual task. Cloud Tasks then rate-limits and invokes the workflow sequentially or in controlled concurrency, executing callbacks when complete.

## Consequences & Trade-offs

### Pros
* **Serverless Operations:** No workflow engines, VMs, or persistent workers to manage. We only pay for actual step transitions and task invocations.
* **Declarative and Auditable:** The entire ingestion flow is codified as YAML in `/workflows`, making it easy to review, version control in Git, and deploy via Terraform.
* **Downstream Rate Protection:** Cloud Tasks natively supports token-bucket rate limiting, protecting downstream resources (like Google AI APIs and ClamAV functions) from database or network saturation during bulk uploads.
* **Resilience & Fault Tolerance:** Cloud Tasks handles exponential backoffs and retry limits before escalating failures to the Dead-Letter Queue (DLQ), mitigating transient errors (e.g., API timeouts).

### Cons
* **YAML Expressiveness & Debugging:** Managing complex loops, JSON parsing, or conditional logic in YAML can be verbose and harder to debug or test locally compared to native code (like Go goroutines).
* **Workflow Payload Restrictions:** Cloud Workflows enforces maximum execution state sizes, requiring us to pass files by reference (Cloud Storage URIs) rather than passing binary data directly within the workflow state.
* **HTTP/REST Boundary:** Cloud Workflows natively targets HTTP endpoints. Internal microservices built with gRPC require HTTP-to-gRPC translation or wrapper endpoints, which adds a minor serialization step.