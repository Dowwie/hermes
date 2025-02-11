<div align="center">
<h1>Hermes - Webhook Processing Pipeline</h1>
<img src="/assets/logo.jpg" alt="Logo" width="300" style="display: block; margin-top: 0; margin-bottom: 0;"/>
</div>


## Quick Start

1. Install Erlang and Elixir dependencies using asdf:
```bash
asdf install
```

2. Install project dependencies and compile:
```bash
mix deps.get && mix compile
```

3. Set up database (requires local Postgres instance):
```bash
mix ecto.setup
```

4. Start the server:
```bash
mix phx.server
```

## Overview

The main reason that this project exists is to act as a working example of Elixir's pipeline processing capabilities.

Hermes is a webhook processing system designed for high throughput and low latency. The system implements a complete three-stage pipeline architecture:

1. **Ingestion** - Fast webhook acceptance with queue-based buffering
2. **Processing** - Message normalization and conversation management
3. **Dispatch** - Reliable delivery through provider-specific clients

The system features automatic back-pressure propagation from persistent storage through to upstream API clients, ensuring stability under load.



## Architecture

### Core Components

1. **Web API Layer**
   - Phoenix-based REST endpoints
   - HMAC-SHA256 signature verification
   - Immediate 202 Accepted responses
   - Queue-based request buffering

2. **Ingestion Pipeline**
   - Broadway-based message processing
   - GenStage producer with configurable buffer
   - Parallel processors for message normalization
   - Batched database writes

3. **Data Layer**
   - Postgres-backed relational model
   - Ecto schema validation
   - Automatic conversation resolution
   - Entity conflict handling

4. **Dispatch Layer**
   - Provider-specific API clients
   - Mock clients for development/testing
   - Automatic retries with exponential backoff

5. **Observability**
    - Telemetry with metrics
    - Structured JSON logging


## Back-Pressure Implementation

Hermes implements a comprehensive back-pressure strategy across all system layers:

1. **Web API Layer**
   - Immediate queue capacity checks on ingress
   - 503 Service Unavailable responses with Retry-After header
   - Configurable max buffer size (currently 100,000 messages)

2. **Ingestion Pipeline**
   - GenStage demand-based flow control
   - Batch size/timeout thresholds
   - Parallel processor pools scaled to CPU cores
   - Automatic message requeuing on failure

3. **Database Layer**
   - Connection pool sizing aligned with batch concurrency
   - Bulk insert optimizations
   - Transactional error handling with automatic retries

4. **Dispatch Layer**
   - Provider client rate limiting
   - Exponential backoff retry strategy


## Data Model

### Core Entities

| Entity         | Description                                  | Key Constraints              |
|----------------|----------------------------------------------|-------------------------------|
| **Party**      | Communication participant (email/phone)      | Unique email/phone            |
| **Provider**   | Service provider (Twilio, SendGrid, etc)     | Unique name                   |
| **Channel**    | Communication channel (SMS, Email, etc)      | Unique per provider           |
| **Conversation**| Persistent message thread between two parties| Ordered party pairs           |
| **Message**    | Individual communication unit                | Sent-at timestamp indexing    |
| **Attachment** | Media/file associated with messages          | URL validation                |


### Limitations
- Conversations limited to two participants
- Single channel per message
- Attachment storage metadata not tracked

## Security

**Webhook Verification**
   - HMAC-SHA256 signature validation middleware
   - Secret rotation support
   - Header-based channel authentication

*Note:* HMAC verification is implemented in `lib/hermes_web/plugs/webhook.ex` but needs route integration.


## Monitoring

Built-in telemetry includes:
- Message throughput metrics
- Attachment volume tracking
- Broadway pipeline performance
- VM resource utilization
- Phoenix endpoint latency


## Development

```bash
mix test --trace
```
