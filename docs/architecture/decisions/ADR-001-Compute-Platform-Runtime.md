# ADR 001: Choice of Compute Platform and Runtime for Microservices

**Status:** Approved

---

## Context

The platform must host two distinct services:
1. **API Server:** Handles citizen-facing and system-integrated document uploads. Ingestion volume fluctuates heavily throughout the day, with massive spikes during business hours and near-zero utilization overnight.
2. **Security UI:** Used infrequently by safeguarding officers for investigating flagged files.

We need a compute platform and runtime environment that:
* Scales rapidly to handle sudden traffic spikes.
* Minimizes operational overhead for a small engineering team.
* Optimizes infrastructure costs (especially during low-traffic/overnight periods).
* Maximizes security by keeping microservices isolated from direct public access.
* Provides high throughput with low memory footprints and fast startup times.

## Decision

1. **Google Cloud Run:** Selected as the primary serverless compute platform over Google Kubernetes Engine (GKE) and VM-based options (Compute Engine).
2. **GoLang:** Selected as the primary runtime language for both the API Server and Security UI due to its efficiency, concurrency features, and native gRPC compatibility.
3. **Internal-Only Service Configuration:** Cloud Run instances are configured to deny direct external access, forcing all incoming traffic to pass through the perimeter Gateway.
4. **Secret Manager Integration:** Credentials and API keys are managed dynamically via Cloud Secret Manager rather than stored in application environments or container images.

## Consequences & Trade-offs

### Pros
* **Dynamic Auto-Scaling & Scale-to-Zero:** Cloud Run automatically scales container instances up and down based on traffic. For the Security UI, setting `min-instances = 0` ensures we pay nothing when no security reviews are active.
* **Low Operational Maintenance:** Eliminates the operational overhead of managing Kubernetes control planes, node upgrades, cluster autoscalers, or operating system patching, aligning with GDS Point 11 (choosing the right tools).
* **Low Footprint and Quick Boot (GoLang):** Using Go ensures fast compilation, lightweight container images, minimal memory usage, and sub-second startup times, which directly reduces the impact of cold starts.
* **Granular IAM Security:** Cloud Run integrates natively with Google Cloud IAM service accounts, allowing us to grant least-privilege access to downstream resources (like Firestore, Cloud Storage, and Pub/Sub).

### Cons
* **Cold Starts:** Scale-to-zero (`min-instances = 0`) introduces a minor "cold start" latency penalty on initial requests. While acceptable for the internal Security UI, we mitigated this for the citizen-facing API Server by configuring a minimum instance of `min-instances = 1`.
* **Resource & Request Timeout Limits:** Cloud Run enforces a maximum request timeout (60 minutes) and strict CPU/memory limits. To prevent ingestion timeouts during large video uploads, long-running ingestion workflows are offloaded asynchronously to Cloud Tasks rather than handled synchronously within the container's HTTP request lifecycle.
* **No Local State:** Cloud Run containers are stateless. Any ephemeral transaction state must be stored in Firestore rather than in-memory or on local disk.