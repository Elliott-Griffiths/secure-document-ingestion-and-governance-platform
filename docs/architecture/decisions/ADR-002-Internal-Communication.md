# ADR 002: Internal Communication

**Status:** Approved

---

## Context

The Secure Document Ingestion and Governance Platform consists of multiple internal services (the GoLang API Server, Cloud Functions for virus scanning and content checking, Cloud Tasks, Firestore, and Cloud Storage). We need an internal communication protocol that:
* Handles high-throughput, concurrent file transfer and metadata coordination.
* Minimizes serialization/deserialization overhead.
* Enforces strict API contracts between services to prevent runtime integration errors.
* Integrates cleanly with a secure Gateway that translates external client requests (HTTPS 1.1) to internal services.

## Decision

We selected gRPC (running over HTTP/2) as the primary communication protocol for all custom service-to-service communication (e.g., between the GoLang API Server and secondary microservices), while leveraging native Google Cloud Client Libraries for highly optimized gRPC streaming to Firestore and Cloud Storage. 

For the boundary between the external Gateway and the internal Cloud Run services (API Server and Security UI), we utilize **HTTP/2 (H2C) / TLS**. External client requests into the Gateway remain on standard **HTTPS 1.1 / TLS**.

## Consequences & Trade-offs

### Pros
* **High Performance & Low Latency:** By utilizing Protocol Buffers (Protobuf) and HTTP/2, gRPC provides binary serialization and multiplexed connections. This significantly reduces latency and payload sizes compared to JSON-over-HTTP/1.1 REST.
* **Strict Type Safety:** API contracts are explicitly defined in `.proto` files, providing automatic client/server code generation in Go and other target languages, preventing schema drift.
* **Efficient Streaming:** HTTP/2 supports native streaming, which is optimal for handling large document and file transfers throughout the ingestion lifecycle.
* **Standardization:** Aligns internal integrations around a single, highly performant protocol, simplifying API design and service definitions.

### Cons
* **Tooling & Compilation Complexity:** Developers must compile `.proto` files using protoc and manage code-generation dependencies within the build/deployment pipeline.
* **Reduced Human Readability:** Because gRPC uses a binary format, tracing and debugging network traffic requires specialized tools (like `grpcurl` or proxy captures) instead of plain JSON inspection.
* **External Client Compatibility:** Web browsers and standard external APIs do not natively support standard gRPC client requests directly, necessitating the Gateway translation layer (HTTPS 1.1 to H2C/gRPC).