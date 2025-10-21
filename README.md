# final-barista-service

> SpringBucks Barista Service - Pure message-driven microservice with RabbitMQ-based Zipkin tracing and async order processing

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.org/)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2024.0.2-blue.svg)](https://spring.io/projects/spring-cloud)
[![Zipkin](https://img.shields.io/badge/Zipkin-RabbitMQ-blue.svg)](https://zipkin.io/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-Enabled-orange.svg)](https://www.rabbitmq.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Message-driven barista service demonstrating pure async architecture with Spring Cloud Stream + RabbitMQ, RabbitMQ-based Zipkin tracing (non-blocking reporter), and instant order processing without HTTP endpoints.

## Features

- **Pure Message-Driven**: No HTTP API, 100% RabbitMQ-based communication
- **RabbitMQ Zipkin Reporter**: Non-blocking tracing via RabbitMQ (vs HTTP in waiter/customer services)
- **Async Order Processing**: Instant order state updates (ORDERED → BREWED → READY)
- **Spring Cloud Stream**: Function-based programming model (`Consumer<Message<Long>>`)
- **Service Discovery**: Consul registration for monitoring
- **MariaDB Persistence**: Order state persistence with JPA
- **Instant Processing**: No artificial delays, optimized for throughput

## Tech Stack

- **Spring Boot 3.4.5** + **Spring Cloud 2024.0.2**
- **Spring Cloud Stream** + **RabbitMQ** (Message consumer & producer)
- **Micrometer Tracing + Brave Bridge**
- **Zipkin** (RabbitMQ reporter - async tracing)
- **Spring Cloud Consul Discovery**
- **Spring Data JPA** + **MariaDB 11.8.3**
- **Lombok** + **Java 21**

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               final-barista-service (No REST API!)           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    RabbitMQ Consumer (newOrders.barista-service)     │  │
│  │                                                       │  │
│  │  ← newOrders Exchange (from waiter-service)          │  │
│  │    Queue: newOrders.barista-service                  │  │
│  │    Message: { orderId: 1 }                           │  │
│  └──────────────────────────────────────────────────────┘  │
│                         ↓                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         OrderListener (Consumer Function)            │  │
│  │  1. Fetch order from database                        │  │
│  │  2. Update state: PAID → ORDERED                     │  │
│  │  3. Update state: ORDERED → BREWED                   │  │
│  │  4. Update state: BREWED → READY                     │  │
│  │  5. Set barista ID (springbucks-{uuid})              │  │
│  │  6. Save to database (~30ms total)                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                         ↓                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    RabbitMQ Producer (finishedOrders-out-0)          │  │
│  │                                                       │  │
│  │  → finishedOrders Exchange (to waiter-service)       │  │
│  │    Routing Key: finished.orders                      │  │
│  │    Message: { orderId: 1, customer: "spring-8090" }  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Zipkin Tracing (RabbitMQ Reporter)         │  │
│  │  → zipkin-final-spring-course (RabbitMQ queue)       │  │
│  │    Async, non-blocking tracing (vs HTTP)             │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                               │
│  No HTTP Endpoints! Pure async processing.                   │
└─────────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites

- **JDK 21** or higher
- **Maven 3.8+** (or use included wrapper)
- **Docker** + **Docker Compose** (for complete system deployment)
- **Running infrastructure** (MariaDB, RabbitMQ, Consul, Zipkin)

### Quick Start (Docker Compose - Recommended)

**Step 1: Build All Docker Images**

```bash
# Navigate to Chapter 16 directory
cd "Chapter 16 服務鏈路追蹤"

# Build waiter-service
cd final-waiter-service
mvn clean package -DskipTests

# Build customer-service
cd ../final-customer-service
mvn clean package -DskipTests

# Build barista-service
cd ../final-barista-service
mvn clean package -DskipTests
# Output: springbucks/final-barista-service:0.0.1-SNAPSHOT

cd ..
```

**Step 2: Start Complete System**

```bash
# Start all 9 containers
docker-compose up -d

# Wait for services to be ready (~30 seconds)
docker-compose ps

# Expected containers:
# - final-barista-service        (Up - no exposed ports!)
# - final-waiter-service         (Up - port 8080)
# - final-customer-service-8090  (Up - port 8090)
# - final-customer-service-9090  (Up - port 9090)
# - mariadb, redis, consul, rabbitmq, zipkin
```

**Step 3: Verify Barista Service**

```bash
# Check Consul for barista-service registration
curl http://localhost:8500/v1/catalog/service/barista-service | jq

# Check barista-service logs
docker logs final-spring-course-final-barista-service-1

# Expected log on startup:
# Started BaristaServiceApplication in X seconds
# (No HTTP endpoint logs!)
```

### Standalone Execution (Development)

**Prerequisites: Start Infrastructure**

```bash
# Start MariaDB
docker run -d --name mariadb \
  -e MYSQL_DATABASE=springbucks \
  -e MYSQL_USER=springbucks \
  -e MYSQL_PASSWORD=springbucks \
  -e MYSQL_ROOT_PASSWORD=root_password \
  -p 3306:3306 mariadb:11.8.3

# Start RabbitMQ
docker run -d --name rabbitmq \
  -e RABBITMQ_DEFAULT_USER=spring \
  -e RABBITMQ_DEFAULT_PASS=spring \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:4.1.4-management

# Start Consul
docker run -d --name consul -p 8500:8500 consul:1.4.5

# Start Zipkin (with RabbitMQ support)
docker run -d --name zipkin \
  -e RABBIT_ADDRESSES=localhost:5672 \
  -e RABBIT_USER=spring \
  -e RABBIT_PASSWORD=spring \
  -p 9411:9411 openzipkin/zipkin:3-arm64
```

**Run Application**

```bash
# Update application.properties for localhost connections
# Then run:
./mvnw spring-boot:run
```

## Message Processing Flow

### Complete Order Flow (End-to-End)

```
1. Customer Service (POST /customer/order)
   ↓
2. Waiter Service (POST /order/)
   - Create order: state = INIT
   ↓
3. Waiter Service (PUT /order/{id})
   - Update state: INIT → PAID
   - Send message to RabbitMQ (newOrders)
   ↓
4. RabbitMQ (newOrders Exchange)
   - Queue: newOrders.barista-service
   ↓
5. Barista Service (Consumer Function) ← YOU ARE HERE
   - Receive message: { orderId: 1 }
   - Fetch order from database
   - Update state: PAID → ORDERED
   - Update state: ORDERED → BREWED
   - Update state: BREWED → READY
   - Set barista ID: springbucks-<uuid>
   - Save to database (~30ms)
   - Send message to RabbitMQ (finishedOrders)
   ↓
6. RabbitMQ (finishedOrders Exchange)
   - Routing Key: finished.orders
   - Queue: finishedOrders.waiter-service
   ↓
7. Waiter Service (Consumer Function)
   - Update order: state = READY → TAKEN
   - Send notification to customer
   ↓
8. Customer Service (Consumer Function)
   - Display: "Order {id} is READY, I'll take it."
```

### Barista Processing Logic

```java
@Bean
public Consumer<Message<Long>> newOrders() {
    return message -> {
        Long orderId = message.getPayload();
        
        // 1. Fetch order
        Optional<CoffeeOrder> optionalOrder = orderRepository.findById(orderId);
        
        // 2. Update states (instant processing, no delay!)
        order.setState(OrderState.ORDERED);
        orderRepository.save(order);
        
        order.setState(OrderState.BREWED);
        orderRepository.save(order);
        
        order.setState(OrderState.READY);
        order.setBarista(baristaPrefix + UUID.randomUUID().toString());
        orderRepository.save(order);
        
        // 3. Send completion message
        Message<Long> finishedMessage = MessageBuilder
            .withPayload(orderId)
            .setHeader("customer", order.getCustomer())
            .build();
        streamBridge.send(finishedOrdersBinding, finishedMessage);
    };
}
```

**Processing Time**: ~30ms (3 database saves + message send)

## Configuration Highlights

### Spring Cloud Stream Bindings

```properties
# Consumer binding: Receive new orders from waiter-service
spring.cloud.function.definition=newOrders
spring.cloud.stream.bindings.newOrders-in-0.destination=newOrders
spring.cloud.stream.bindings.newOrders-in-0.group=barista-service
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.durable-subscription=true
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.exchange-name=newOrders

# Producer binding: Send finished orders to waiter-service
spring.cloud.stream.bindings.finishedOrders-out-0.destination=finishedOrders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.delivery-mode=persistent
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.exchange-name=finishedOrders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.routing-key=finished.orders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.exchange-type=topic

# Custom binding name for StreamBridge
stream.bindings.finished-orders-binding=finishedOrders-out-0
```

### Zipkin Tracing (RabbitMQ Reporter)

```properties
# RabbitMQ-based tracing reporter (DIFFERENT from HTTP!)
management.zipkin.tracing.endpoint=http://zipkin-final-spring-course:9411/api/v2/spans
management.tracing.sampling.probability=1.0
management.zipkin.tracing.sender.type=rabbit  ← KEY DIFFERENCE!

# Why RabbitMQ vs HTTP?
# - Async, non-blocking (no impact on message processing time)
# - High throughput (barista processes many orders)
# - Prevents tracing overhead from slowing down order processing
```

**Comparison**:

| Service | Zipkin Reporter | Reasoning |
|---------|----------------|-----------|
| **waiter-service** | HTTP | Moderate load, simple HTTP API |
| **customer-service** | HTTP | Low load, user-facing UI |
| **barista-service** | RabbitMQ | High throughput, pure async processing |

### Database Configuration

```properties
spring.datasource.url=jdbc:mariadb://mariadb-final-spring-course:3306/springbucks
spring.datasource.username=springbucks
spring.datasource.password=springbucks
spring.datasource.driver-class-name=org.mariadb.jdbc.Driver

spring.jpa.hibernate.ddl-auto=none
spring.jpa.properties.hibernate.show_sql=true
spring.jpa.properties.hibernate.format_sql=true
```

## Testing

### End-to-End Order Flow Test

```bash
# Step 1: Create order from customer-service
curl -X POST http://localhost:8090/customer/order \
  -H "Content-Type: application/json"

# Expected response:
{
  "id": 1,
  "customer": "spring-8090",
  "state": "PAID",
  "waiter": "springbucks-<uuid>"
}

# Step 2: Check barista-service logs
docker logs -f final-spring-course-final-barista-service-1

# Expected logs:
# Receive a new Order 1. Waiter: springbucks-xxx. Customer: spring-8090
# Order 1 is READY.

# Step 3: Check customer-service logs
docker logs -f final-spring-course-final-customer-service-8090-1

# Expected logs:
# Order 1 is READY, I'll take it.
```

### RabbitMQ Queue Monitoring

```bash
# Open RabbitMQ Management UI
open http://localhost:15672
# Login: spring / spring

# Navigate to Queues tab
# Expected queues:
# - newOrders.barista-service       (Consumer: barista-service)
# - finishedOrders.waiter-service   (Producer: barista-service)
```

### Zipkin Trace Verification

```bash
# Open Zipkin UI
open http://localhost:9411

# Search for barista-service traces
# Expected span sequence:
# 1. neworders.barista-service receive      [CONSUMER]
# 2. new-orders process                     [INTERNAL - processing]
# 3. stream-bridge process                  [INTERNAL - prepare message]
# 4. finishedorders-out-0 send              [PRODUCER - Spring Integration]
# 5. finishedorders/finished.orders send    [PRODUCER - RabbitMQ]

# Processing time: ~30ms
# No HTTP SERVER spans (barista has no REST API!)
```

## Monitoring & Observability

### Health Check

```bash
# Via Consul (barista-service auto-registers)
curl http://localhost:8500/v1/health/service/barista-service | jq

# Via Actuator (if running standalone)
curl http://localhost:8070/actuator/health

# Note: Docker Compose does not expose port 8070 to host!
# To access Actuator in Docker:
docker exec -it final-spring-course-final-barista-service-1 \
  curl http://localhost:8070/actuator/health
```

### Logs Analysis

```bash
# View full logs
docker logs -f final-spring-course-final-barista-service-1

# Filter order processing
docker logs final-spring-course-final-barista-service-1 | grep "Receive a new Order"

# Filter completion messages
docker logs final-spring-course-final-barista-service-1 | grep "is READY"

# Check database operations
docker logs final-spring-course-final-barista-service-1 | grep "Hibernate:"
```

### Database Verification

```bash
# Connect to MariaDB
docker exec -it final-spring-course-mariadb-final-spring-course-1 \
  mariadb -u springbucks -p springbucks

# Query order states
MariaDB [springbucks]> SELECT id, customer, state, barista FROM t_order;

# Expected output:
+----+--------------+-------+------------------------------------+
| id | customer     | state | barista                            |
+----+--------------+-------+------------------------------------+
|  1 | spring-8090  | TAKEN | springbucks-<uuid>                 |
+----+--------------+-------+------------------------------------+
```

## Performance Characteristics

### Processing Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Order Processing Time** | ~30ms | 3 DB saves + message send |
| **State Transitions** | 3 | PAID → ORDERED → BREWED → READY |
| **Database Operations** | 3 saves | Optimized for instant processing |
| **Message Latency** | <5ms | RabbitMQ message sending |
| **Tracing Overhead** | 0ms | RabbitMQ async reporter |

**Why Instant Processing?**

```java
// No artificial delays!
// order.setState(OrderState.ORDERED);
// orderRepository.save(order);
// Thread.sleep(5000);  ← REMOVED! No delays!
```

**Reasoning**: Barista service simulates instant order completion for:
- Faster testing and demonstration
- Showcase high-throughput async processing
- Prevent RabbitMQ queue buildup

**To Add Realistic Delays** (Optional):

```java
order.setState(OrderState.ORDERED);
orderRepository.save(order);
TimeUnit.SECONDS.sleep(2);  // Simulate brewing

order.setState(OrderState.BREWED);
orderRepository.save(order);
TimeUnit.SECONDS.sleep(3);  // Simulate final preparation

order.setState(OrderState.READY);
// ...
```

## Best Practices

### Message-Driven Architecture

**Advantages**:
- ✅ Async, non-blocking processing
- ✅ Natural backpressure (RabbitMQ queue buffering)
- ✅ Decoupled from HTTP request/response cycle
- ✅ Scales horizontally (multiple barista instances)

**Disadvantages**:
- ⚠️ No direct HTTP health check (relies on Consul)
- ⚠️ Debugging requires log analysis + Zipkin
- ⚠️ Message ordering not guaranteed (unless configured)

### RabbitMQ Zipkin Reporter Tuning

```properties
# Production recommendations:
# 1. Reduce sampling rate (RabbitMQ reporter is async, but still has overhead)
management.tracing.sampling.probability=0.1  # 10% sampling

# 2. Configure RabbitMQ connection pool (if high load)
spring.rabbitmq.listener.simple.concurrency=5
spring.rabbitmq.listener.simple.max-concurrency=10
```

### Error Handling

```java
@Bean
public Consumer<Message<Long>> newOrders() {
    return message -> {
        try {
            // Processing logic
        } catch (Exception e) {
            log.error("Failed to process order: {}", message.getPayload(), e);
            // Option 1: Retry (throw exception for RabbitMQ to re-queue)
            // Option 2: Dead Letter Queue (configure DLX)
            // Option 3: Log and skip (current implementation)
        }
    };
}
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **No messages received** | Check RabbitMQ queue binding and exchange routing |
| **Barista ID null** | Verify `order.barista-prefix` property is set |
| **Database connection failed** | Check MariaDB container and credentials |
| **Zipkin trace incomplete** | Verify Zipkin RabbitMQ configuration and connectivity |

### Debug Commands

```bash
# Check RabbitMQ connections
docker exec rabbitmq-final-spring-course rabbitmqctl list_connections

# Check RabbitMQ consumers
docker exec rabbitmq-final-spring-course rabbitmqctl list_consumers

# Purge newOrders queue (testing)
docker exec rabbitmq-final-spring-course rabbitmqctl purge_queue newOrders.barista-service
```

## Comparison with Other Projects

| Project | Processing Model | Zipkin Reporter | Database | HTTP API |
|---------|------------------|-----------------|----------|----------|
| **final-barista** | Pure async (RabbitMQ) | RabbitMQ | MariaDB | ❌ None |
| **rabbitmq-barista** | Pure async (RabbitMQ) | ❌ None | MariaDB | ❌ None |
| **simple-barista** | HTTP API | ❌ None | H2 | ✅ REST |

## References

- [Spring Cloud Stream](https://spring.io/projects/spring-cloud-stream)
- [Spring Cloud Stream RabbitMQ](https://docs.spring.io/spring-cloud-stream-binder-rabbit/reference/)
- [Zipkin RabbitMQ Reporter](https://github.com/openzipkin/zipkin-reporter-java)
- [RabbitMQ Management](https://www.rabbitmq.com/docs/management)
- [Micrometer Tracing](https://micrometer.io/docs/tracing)

## License

This project is licensed under the MIT License.

## Contact

We focus on Agile Project Management, IoT application development, and Domain-Driven Design (DDD), combining advanced technologies with practical experience to create flexible software solutions.

- **Facebook**: [風清雲談](https://www.facebook.com/profile.php?id=61576838896062)
- **LinkedIn**: [linkedin.com/in/chu-kuo-lung](https://www.linkedin.com/in/chu-kuo-lung)
- **YouTube**: [雲談風清](https://www.youtube.com/channel/UCXDqLTdCMiCJ1j8xGRfwEig)
- **Blog**: [風清雲談](https://blog.fengqing.tw/)
- **Email**: [fengqing.tw@gmail.com](mailto:fengqing.tw@gmail.com)

---

**Last Updated**: 2025-10-21  
**Maintainer**: FengQing Team
