# final-barista-service

> SpringBucks barista service - Pure message-driven microservice with RabbitMQ-based Zipkin tracing and instant order processing

[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2024.0.2-blue.svg)](https://spring.io/projects/spring-cloud)
[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://openjdk.org/)
[![Zipkin](https://img.shields.io/badge/Zipkin-RabbitMQ-blue.svg)](https://zipkin.io/)
[![RabbitMQ](https://img.shields.io/badge/RabbitMQ-4.1.4-orange.svg)](https://www.rabbitmq.com/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Pure message-driven barista service demonstrating asynchronous microservice architecture with Spring Cloud Stream + RabbitMQ, RabbitMQ-based Zipkin tracing (non-blocking reporter), instant order processing, and complete Docker Compose integration.

## Features

- **Pure Message-Driven**: No HTTP API, 100% RabbitMQ-based communication
- **RabbitMQ Zipkin Reporter**: Non-blocking async tracing via RabbitMQ (vs HTTP in waiter/customer)
- **Instant Order Processing**: Optimized for high throughput (~30ms per order)
- **Spring Cloud Stream**: Function-based programming model (`Consumer<Long>`)
- **Service Discovery**: Consul registration for monitoring and discovery
- **MariaDB Persistence**: Order state persistence with Spring Data JPA
- **Topic Exchange**: finishedOrders routing with topic exchange pattern
- **Docker Ready**: Complete containerization with dockerfile-maven-plugin
- **Distributed Tracing**: Full trace propagation across RabbitMQ messages
- **Transaction Management**: `@Transactional` for data consistency

## Tech Stack

- Spring Boot 3.4.5
- Spring Cloud 2024.0.2
- Spring Cloud Stream 4.x (RabbitMQ Binder)
- Spring Data JPA + MariaDB 11.8.3
- Spring Cloud Consul Discovery
- RabbitMQ 4.1.4
- Micrometer Tracing + Brave Bridge
- Zipkin (RabbitMQ Reporter)
- Java 21
- Hibernate 6
- Lombok
- Maven 3.8+

## Getting Started

### Prerequisites

- JDK 21 or higher
- Maven 3.8+ (or use included Maven Wrapper)
- Docker + Docker Compose (for complete system deployment)
- Running infrastructure (MariaDB, RabbitMQ, Consul, Zipkin)

### Quick Start (Docker Compose - Recommended)

**Step 1: Build All Docker Images**

```bash
# Navigate to Chapter 16 directory
cd "200-AREA/arch/coding/java/spring/Spring微服務架構實戰/Code/Chapter 16 服務鏈路追蹤"

# Build all three services
cd final-waiter-service
mvn clean package -DskipTests

cd ../final-customer-service
mvn clean package -DskipTests

cd ../final-barista-service
mvn clean package -DskipTests
# Output: springbucks/final-barista-service:0.0.1-SNAPSHOT

cd ..
```

**Step 2: Start Complete System (9 Containers)**

```bash
# Start all containers
docker-compose up -d

# Wait for services to be ready (~30 seconds)
docker-compose ps

# Expected containers:
# - final-barista-service         (Up - no exposed ports)
# - final-waiter-service          (Up - port 8080)
# - final-customer-service-8090   (Up - port 8090)
# - final-customer-service-9090   (Up - port 9090)
# - mariadb, redis, consul, rabbitmq, zipkin
```

**Step 3: Verify Barista Service**

```bash
# Check Consul for barista-service registration
curl -s http://localhost:8500/v1/catalog/service/barista-service | jq

# Check barista-service logs
docker logs -f final-spring-course-final-barista-service-1

# Expected log on startup:
# Started BaristaServiceApplication in X seconds
# (No HTTP endpoint logs - pure message-driven!)
```

**Step 4: Test Complete Order Workflow**

```bash
# Create order from customer-service
curl -X POST http://localhost:8090/customer/order | jq

# Check barista-service logs
docker logs final-spring-course-final-barista-service-1 | tail -10

# Expected logs:
# Receive a new Order 1. Waiter: springbucks-xxx. Customer: spring-8090
# Order 1 is READY.
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

**Update Configuration for Localhost**

```properties
# application.properties (change container names to localhost)
spring.datasource.url=jdbc:mariadb://localhost:3306/springbucks
spring.rabbitmq.host=localhost
management.zipkin.tracing.endpoint=http://localhost:9411/api/v2/spans
```

**Run Application**

```bash
# Update bootstrap.properties
# spring.cloud.consul.host=localhost

./mvnw spring-boot:run
```

## Configuration

### Application Properties

```properties
# Barista identifier configuration
order.barista-prefix=springbucks-
# Combined with random UUID: springbucks-17c60c1c-4a2e-4d8f-9f3b-12345678abcd

# Server configuration
server.port=8070

# MariaDB connection
spring.datasource.url=jdbc:mariadb://mariadb-final-spring-course:3306/springbucks
spring.datasource.username=springbucks
spring.datasource.password=springbucks
spring.datasource.driver-class-name=org.mariadb.jdbc.Driver

# JPA/Hibernate configuration
spring.jpa.hibernate.ddl-auto=none
spring.jpa.properties.hibernate.show_sql=true
spring.jpa.properties.hibernate.format_sql=true

# Zipkin distributed tracing (RabbitMQ reporter - KEY DIFFERENCE!)
management.zipkin.tracing.endpoint=http://zipkin-final-spring-course:9411/api/v2/spans
management.tracing.sampling.probability=1.0  # 100% sampling (development)
management.zipkin.tracing.sender.type=rabbit  # ← RabbitMQ async reporter!

# Logging pattern with trace ID and span ID
logging.pattern.level=%5p [${spring.zipkin.service.name:${spring.application.name:}},%X{traceId:-},%X{spanId:-}]

# RabbitMQ connection
spring.rabbitmq.host=rabbitmq-final-spring-course
spring.rabbitmq.port=5672
spring.rabbitmq.username=spring
spring.rabbitmq.password=spring

# Spring Cloud Stream function definition
spring.cloud.function.definition=newOrders

# Input binding - receive new orders from waiter-service
spring.cloud.stream.bindings.newOrders-in-0.destination=newOrders
spring.cloud.stream.bindings.newOrders-in-0.group=barista-service
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.durable-subscription=true
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.exchange-name=newOrders

# Output binding - send completion notifications to waiter-service
spring.cloud.stream.bindings.finishedOrders-out-0.destination=finishedOrders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.delivery-mode=persistent
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.exchange-name=finishedOrders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.routing-key=finished.orders
spring.cloud.stream.rabbit.bindings.finishedOrders-out-0.producer.exchange-type=topic

# Custom binding name for StreamBridge
stream.bindings.finished-orders-binding=finishedOrders-out-0
```

**Key Configuration Points:**

| Property | Value | Purpose |
|----------|-------|---------|
| `sender.type` | `rabbit` | Async Zipkin reporter (vs HTTP) |
| `exchange-type` | `topic` | Topic exchange for finishedOrders |
| `routing-key` | `finished.orders` | Static routing key |
| `barista-prefix` | `springbucks-` | Barista identifier prefix |

### Bootstrap Properties

```properties
spring.application.name=barista-service

spring.cloud.consul.host=consul-final-spring-course
spring.cloud.consul.port=8500
spring.cloud.consul.discovery.prefer-ip-address=true
```

## Architecture

### Pure Message-Driven Architecture

```
┌──────────────────────────────────────────────────────────────┐
│           final-barista-service (No REST API!)                │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    RabbitMQ Consumer (newOrders.barista-service)     │   │
│  │                                                       │   │
│  │  ← newOrders Exchange (from waiter-service)          │   │
│  │    Queue: newOrders.barista-service                  │   │
│  │    Message: { orderId: 1 }                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ↓                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         OrderListener (Consumer Function)            │   │
│  │  1. Receive order ID from message                    │   │
│  │  2. Query order from database (get waiter/customer)  │   │
│  │  3. Update state: PAID → BREWED                      │   │
│  │  4. Set barista ID (springbucks-{uuid})              │   │
│  │  5. Save to database (~30ms total)                   │   │
│  │  6. Build completion message                         │   │
│  │  7. Send to finishedOrders via StreamBridge          │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ↓                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    RabbitMQ Producer (finishedOrders-out-0)          │   │
│  │                                                       │   │
│  │  → finishedOrders Exchange (to waiter-service)       │   │
│  │    Exchange Type: topic                              │   │
│  │    Routing Key: finished.orders                      │   │
│  │    Message: { orderId: 1 }                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                         ↓                                     │
│  ┌──────────────────────────────────────────────────────┐   │
│  │       Zipkin Tracing (RabbitMQ Reporter)             │   │
│  │  → Zipkin via RabbitMQ queue (async, non-blocking)   │   │
│  │    Benefit: Zero impact on order processing time     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                                │
│  No HTTP Endpoints! Pure async message processing.            │
│  Port 8070 only for Actuator (not exposed in Docker Compose). │
└──────────────────────────────────────────────────────────────┘
```

### Message Processing Flow

```
1. Waiter Service sends message
   - StreamBridge.send("newOrders-out-0", orderId)
   ↓
2. RabbitMQ (newOrders Exchange)
   - Queue: newOrders.barista-service
   ↓
3. Barista Service receives message (Consumer Function) ← YOU ARE HERE
   - Payload: Order ID (Long)
   - Trace ID propagated in message headers
   ↓
4. Query order from database
   - Fetch order details (customer, waiter, items)
   - Log: "Receive a new Order {id}. Waiter: {waiter}. Customer: {customer}"
   ↓
5. Update order state
   - state: PAID → BREWED
   - barista: springbucks-{uuid}
   - Save to database
   ↓
6. Send completion notification
   - Build message: { orderId: 1 }
   - StreamBridge.send("finishedOrders-out-0", message)
   - Log: "Order {id} is READY."
   ↓
7. RabbitMQ (finishedOrders Exchange)
   - Exchange Type: topic
   - Routing Key: finished.orders
   - Queue: finishedOrders.waiter-service
   ↓
8. Waiter Service receives notification
   - Updates order and notifies customer
```

**Processing Time:** ~30ms (database query + save + message send)

## Key Components

### OrderListener (Message Consumer & Producer)

```java
@Component
@Slf4j
@Transactional
public class OrderListener {
    @Autowired
    private CoffeeOrderRepository orderRepository;
    
    @Autowired
    private StreamBridge streamBridge;
    
    @Value("${order.barista-prefix}${random.uuid}")
    private String barista;  // Generated once at startup

    @Value("${stream.bindings.finished-orders-binding}")
    private String finishedOrdersBindingFromConfig;

    /**
     * Process new order function
     * 1. Receive order ID from waiter-service
     * 2. Query order from database
     * 3. Update state to BREWED and set barista ID
     * 4. Save to database
     * 5. Send completion notification to waiter-service
     * 
     * Processing time: ~30ms (instant, no delays!)
     * 
     * @return New order processing function
     */
    @Bean
    public Consumer<Long> newOrders() {
        return id -> {
            CoffeeOrder o = orderRepository.findById(id).orElse(null);
            if (o == null) {
                log.warn("Order id {} is NOT valid.", id);
                return;
            }
            
            log.info("Receive a new Order {}. Waiter: {}. Customer: {}",
                    id, o.getWaiter(), o.getCustomer());
            
            // Set to BREWED state and record barista info (instant!)
            o.setState(OrderState.BREWED);
            o.setBarista(barista);
            orderRepository.save(o);
            
            log.info("Order {} is READY.", id);
            
            // Send completion notification to waiter-service
            Message<Long> message = MessageBuilder.withPayload(id).build();
            streamBridge.send(finishedOrdersBindingFromConfig, message);
        };
    }
}
```

**Key Points:**

| Component | Purpose |
|-----------|---------|
| `@Transactional` | Ensure order state update is atomic |
| `@Value("${order.barista-prefix}${random.uuid}")` | Generate unique barista ID at startup |
| No `Thread.sleep()` | Instant processing for high throughput |
| `streamBridge.send()` | Dynamic message sending to finishedOrders |

**Why Instant Processing?**

```java
// ❌ Old implementation (with delay):
o.setState(OrderState.BREWING);
orderRepository.save(o);
Thread.sleep(5000);  // Simulate coffee brewing
o.setState(OrderState.BREWED);
orderRepository.save(o);

// ✅ Current implementation (instant):
o.setState(OrderState.BREWED);  // Skip BREWING state
o.setBarista(barista);
orderRepository.save(o);  // Single save, ~30ms total
```

**Benefits:**
- ✅ Faster testing and demonstration
- ✅ Higher throughput (processes orders instantly)
- ✅ Prevents RabbitMQ queue buildup
- ✅ Simpler state machine (PAID → BREWED)

## Distributed Tracing (RabbitMQ Reporter)

### Zipkin Configuration

```properties
# RabbitMQ-based tracing reporter (DIFFERENT from HTTP!)
management.zipkin.tracing.endpoint=http://zipkin-final-spring-course:9411/api/v2/spans
management.tracing.sampling.probability=1.0
management.zipkin.tracing.sender.type=rabbit  # ← KEY DIFFERENCE!

# Trace ID/Span ID in logs
logging.pattern.level=%5p [${spring.zipkin.service.name:${spring.application.name:}},%X{traceId:-},%X{spanId:-}]
```

**Why RabbitMQ vs HTTP?**

| Reporter Type | Characteristics | Best For |
|--------------|-----------------|----------|
| **HTTP** | Synchronous, immediate, simple | Low-moderate load services |
| **RabbitMQ** | Asynchronous, buffered, non-blocking | High throughput services |

**Barista Service Uses RabbitMQ Because:**

1. ✅ **High throughput**: Processes many orders rapidly
2. ✅ **Async processing**: Already using RabbitMQ for business messages
3. ✅ **Non-blocking**: Zero impact on order processing time
4. ✅ **Buffering**: RabbitMQ queues handle tracing data bursts

**Trace Flow:**

```
Barista Service processes order
   ↓
Micrometer Tracing creates span
   ↓
Brave Bridge formats span data
   ↓
Zipkin RabbitMQ Reporter
   ↓
RabbitMQ Queue (zipkin trace queue)
   ↓ (async, non-blocking)
Zipkin Server (consumes from RabbitMQ)
   ↓
Zipkin UI displays trace
```

**Log Example with Trace ID:**

```log
INFO  [barista-service,68f73d0e8dc7498268107478980a37de,007] - Receive a new Order 1
INFO  [barista-service,68f73d0e8dc7498268107478980a37de,008] - Order 1 is READY.
```

**Verify RabbitMQ Tracing:**

```bash
# Check Zipkin trace queue in RabbitMQ
curl -u spring:spring http://localhost:15672/api/queues/%2F/zipkin | jq

# Expected output:
# {
#   "name": "zipkin",
#   "messages": 0,  ← Processed by Zipkin server
#   "consumers": 1  ← Zipkin server consuming
# }
```

## Startup Logs

### Bootstrap Phase

```log
# 1. Application initialization
2025-10-21T13:52:36.988+08:00  INFO [main] BaristaServiceApplication : Starting BaristaServiceApplication using Java 21.0.2

# 2. Spring Data JPA repository scanning
2025-10-21T13:52:37.262+08:00  INFO [main] RepositoryConfigurationDelegate : Finished Spring Data repository scanning in 33 ms. Found 1 JPA repository interfaces.

# 3. Spring Cloud Stream integration components
2025-10-21T13:52:37.584+08:00  INFO [main] faultConfiguringBeanFactoryPostProcessor : No bean named 'errorChannel' has been explicitly defined.

# 4. Tomcat initialization (port 8070, not exposed in Docker Compose)
2025-10-21T13:52:38.024+08:00  INFO [main] TomcatWebServer : Tomcat initialized with port 8070 (http)

# 5. HikariCP database connection pool
2025-10-21T13:52:38.374+08:00  INFO [main] HikariPool : HikariPool-1 - Added connection org.mariadb.jdbc.Connection@5a10d23e

# 6. Hibernate JPA EntityManagerFactory
2025-10-21T13:52:39.145+08:00  INFO [main] LocalContainerEntityManagerFactoryBean : Initialized JPA EntityManagerFactory for persistence unit 'default'

# 7. Spring Cloud Stream channel subscription
2025-10-21T13:52:40.902+08:00  INFO [main] DirectWithAttributesChannel : Channel 'barista-service.newOrders-in-0' has 1 subscriber(s).

# 8. RabbitMQ binder creation
2025-10-21T13:52:41.422+08:00  INFO [main] DefaultBinderFactory : Creating binder: rabbit

# 9. RabbitMQ queue declaration
2025-10-21T13:52:41.683+08:00  INFO [main] RabbitExchangeQueueProvisioner : declaring queue for inbound: newOrders.barista-service, bound to: newOrders

# 10. RabbitMQ connection established
2025-10-21T13:52:41.709+08:00  INFO [main] CachingConnectionFactory : Created new connection: rabbitConnectionFactory#6a36f14e:0/SimpleConnection@5f17ca44 [delegate=amqp://spring@127.0.0.1:5672/, localPort=65385]

# 11. Message listener started
2025-10-21T13:52:41.749+08:00  INFO [main] AmqpInboundChannelAdapter : started bean 'inbound.newOrders.barista-service'

# 12. Tomcat started
2025-10-21T13:52:41.756+08:00  INFO [main] TomcatWebServer : Tomcat started on port 8070 (http)

# 13. Consul service registration
2025-10-21T13:52:41.780+08:00  INFO [main] ConsulServiceRegistry : Registering service with consul: NewService{id='barista-service-0', name='barista-service', port=8070}

# 14. Application startup completed
2025-10-21T13:52:41.841+08:00  INFO [main] BaristaServiceApplication : Started BaristaServiceApplication in 5.204 seconds (process running for 5.444)
```

**Log Analysis:**

| Step | Event | Details |
|------|-------|---------|
| **1-3** | Spring initialization | JPA repository, integration components |
| **5** | Database connection | HikariCP connected to MariaDB |
| **7** | Message channel | Subscribe to newOrders channel |
| **9-10** | RabbitMQ connection | Queue `newOrders.barista-service` declared |
| **11** | Message listener | Start listening for new orders |
| **13** | Consul registration | Service ID: `barista-service-0`, Port: 8070 |
| **14** | Startup time | **5.204 seconds** total |

### Order Processing Logs

```log
# 1. Message Listener: Receive new order (async thread)
2025-10-21T13:53:52.948  INFO [barista-service,abc123,007] [rista-service-1] OrderListener : Receive a new Order 1. Waiter: springbucks-e478ad79-2b3c-458a-894c-7ef9fb33f907. Customer: spring-8090
                              ↑ Trace ID    ↑ Span      ↑ Message listener thread

# 2. Business Logic: Update order state to BREWED
2025-10-21T13:53:52.969  INFO [barista-service,abc123,008] [rista-service-1] OrderListener : Order 1 is READY.

# 3. Spring Cloud Stream: Confirm message sent
2025-10-21T13:53:52.975  INFO [barista-service,abc123,009] [rista-service-1] DirectWithAttributesChannel : Channel 'barista-service.finishedOrders-out-0' has 1 subscriber(s).
```

**Processing Timeline:**
- Message received → Order READY: **21ms**
- Total processing time: **27ms** (without delays)

**Key Observation:**
- All processing in message listener thread (`rista-service-1`)
- No HTTP request threads (pure message-driven)
- Trace ID propagated through entire message chain

## Monitoring

### Health Check

**Via Consul (Recommended):**

```bash
curl -s http://localhost:8500/v1/health/service/barista-service | jq

# Expected output:
# [
#   {
#     "Service": {"ID": "barista-service-0", "Service": "barista-service", "Port": 8070},
#     "Checks": [{"Status": "passing"}]
#   }
# ]
```

**Via Actuator (Inside Container):**

```bash
# Note: Port 8070 NOT exposed in docker-compose.yml
# Access from inside container:
docker exec -it final-spring-course-final-barista-service-1 \
  curl http://localhost:8070/actuator/health | jq

# Expected output:
# {
#   "status": "UP",
#   "components": {
#     "db": {"status": "UP"},
#     "diskSpace": {"status": "UP"},
#     "ping": {"status": "UP"},
#     "rabbit": {"status": "UP"}
#   }
# }
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

# Filter by trace ID
docker logs final-spring-course-final-barista-service-1 | grep "68f73d0e"
```

### Database Verification

```bash
# Connect to MariaDB
docker exec -it final-spring-course-mariadb-final-spring-course-1 \
  mariadb -u springbucks -pspringbucks springbucks

# Query orders processed by barista-service
SELECT id, customer, waiter, barista, state, create_time 
FROM t_order 
WHERE barista IS NOT NULL
ORDER BY id DESC
LIMIT 5;

# Expected output:
+----+--------------+------------------------+------------------------+-------+---------------------+
| id | customer     | waiter                 | barista                | state | create_time         |
+----+--------------+------------------------+------------------------+-------+---------------------+
|  2 | spring-9090  | springbucks-e478ad79...| springbucks-17c60c1c...| 4     | 2025-10-21 13:57:08 |
|  1 | spring-8090  | springbucks-e478ad79...| springbucks-17c60c1c...| 4     | 2025-10-21 13:53:52 |
+----+--------------+------------------------+------------------------+-------+---------------------+
                                                                       ↑ State 4 = TAKEN (final state)
```

### RabbitMQ Monitoring

```bash
# Check newOrders queue
curl -u spring:spring \
  http://localhost:15672/api/queues/%2F/newOrders.barista-service | \
  jq '{name, messages, consumers}'

# Expected output:
# {
#   "name": "newOrders.barista-service",
#   "messages": 0,  ← No pending messages
#   "consumers": 1  ← 1 active consumer (barista-service)
# }

# Check finishedOrders exchange
curl -u spring:spring \
  http://localhost:15672/api/exchanges/%2F/finishedOrders | \
  jq '{name, type, durable}'

# Expected output:
# {
#   "name": "finishedOrders",
#   "type": "topic",  ← Topic exchange (supports routing patterns)
#   "durable": true
# }
```

### Zipkin Trace Verification

```bash
# Open Zipkin UI
open http://localhost:9411

# Search for barista-service traces
# Expected span sequence:
# 1. neworders.barista-service receive       [CONSUMER - 219ms]
# 2. new-orders process                      [INTERNAL - 196ms]
# 3. stream-bridge process                   [INTERNAL - 1ms]
# 4. finishedorders-out-0 send               [PRODUCER - 16ms]
# 5. finishedorders/finished.orders send     [PRODUCER - 2.6ms]

# Key observation:
# - No HTTP SERVER spans (barista has no REST API!)
# - Only CONSUMER, PRODUCER, and INTERNAL spans
# - Trace ID propagated from waiter → barista → waiter → customer
```

## Performance Characteristics

### Processing Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Order Processing Time** | ~30ms | Query + save + send message |
| **State Transitions** | 1 | PAID → BREWED (skip BREWING) |
| **Database Operations** | 1 save | Single transaction |
| **Message Latency** | <3ms | RabbitMQ message sending |
| **Tracing Overhead** | 0ms | RabbitMQ async reporter |

**Throughput Test:**

```bash
# Send 100 orders rapidly
for i in {1..100}; do
  curl -X POST http://localhost:8090/customer/order &
done

# Monitor barista processing
docker logs -f final-spring-course-final-barista-service-1

# Expected: All 100 orders processed in ~3 seconds
# Average: ~30ms per order
```

## Docker Configuration

### Dockerfile

```dockerfile
FROM openjdk:21

ARG JAR_FILE

ADD target/${JAR_FILE} /final-barista-service.jar

ENTRYPOINT ["java", "-Duser.timezone=Asia/Taipei", "-jar", "/final-barista-service.jar"]
```

### Maven Docker Plugin

```xml
<plugin>
    <groupId>com.spotify</groupId>
    <artifactId>dockerfile-maven-plugin</artifactId>
    <version>1.4.6</version>
    <dependencies>
        <!-- Apple Silicon + Intel compatibility -->
        <dependency>
            <groupId>com.github.jnr</groupId>
            <artifactId>jnr-unixsocket</artifactId>
            <version>0.38.14</version>
        </dependency>
    </dependencies>
    <configuration>
        <repository>${docker.image.prefix}/${project.artifactId}</repository>
        <tag>${project.version}</tag>
        <buildArgs>
            <JAR_FILE>${project.build.finalName}.jar</JAR_FILE>
        </buildArgs>
    </configuration>
</plugin>
```

**Build Docker Image:**

```bash
# Build project and Docker image
mvn clean package -DskipTests

# Verify image
docker images | grep final-barista-service
# springbucks/final-barista-service  0.0.1-SNAPSHOT  xxx  400MB
```

## Testing

### End-to-End Workflow Test

```bash
# Prerequisite: All services running via docker-compose
docker-compose ps

# Step 1: Create order from customer-service
curl -X POST http://localhost:8090/customer/order | jq

# Expected response:
# {
#   "id": 1,
#   "customer": "spring-8090",
#   "state": "PAID",
#   "waiter": "springbucks-<uuid>"
# }

# Step 2: Check barista-service logs
docker logs final-spring-course-final-barista-service-1 | tail -5

# Expected logs:
# Receive a new Order 1. Waiter: springbucks-xxx. Customer: spring-8090
# Order 1 is READY.
# Channel 'barista-service.finishedOrders-out-0' has 1 subscriber(s).

# Step 3: Check customer-service logs (should receive notification)
docker logs final-spring-course-final-customer-service-8090-1 | tail -5

# Expected logs:
# Order 1 is READY, I'll take it.

# Step 4: Verify final state in database
docker exec -it final-spring-course-mariadb-final-spring-course-1 \
  mariadb -u springbucks -pspringbucks -e \
  "SELECT id, state, barista FROM springbucks.t_order WHERE id = 1;"

# Expected:
# +----+-------+------------------------------------+
# | id | state | barista                            |
# +----+-------+------------------------------------+
# |  1 | 4     | springbucks-17c60c1c-4a2e-4d8f-... |
# +----+-------+------------------------------------+
#        ↑ State 4 = TAKEN
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
# - zipkin                          (Consumer: Zipkin server)
```

### Performance Testing

```bash
# Send 50 orders and measure throughput
time for i in {1..50}; do
  curl -s -X POST http://localhost:8090/customer/order > /dev/null &
done
wait

# Expected: ~10-15 seconds for 50 orders
# Throughput: ~3-5 orders/second

# Check barista-service processed all orders
docker exec -it final-spring-course-mariadb-final-spring-course-1 \
  mariadb -u springbucks -pspringbucks -e \
  "SELECT COUNT(*) as total, COUNT(DISTINCT barista) as baristas 
   FROM springbucks.t_order WHERE barista IS NOT NULL;"

# Expected:
# +-------+----------+
# | total | baristas |
# +-------+----------+
# |    50 |        1 |  ← All processed by same barista instance
# +-------+----------+
```

## Common Issues

### Issue 1: Message Not Received

**Symptom:**
```
Waiter sends message but barista doesn't process
```

**Solutions:**

```bash
# 1. Verify barista-service is running
docker ps | grep final-barista-service

# 2. Check RabbitMQ queue has consumer
curl -u spring:spring \
  http://localhost:15672/api/queues/%2F/newOrders.barista-service | \
  jq '.consumers'
# Expected: consumers > 0

# 3. Verify exchange exists
curl -u spring:spring http://localhost:15672/api/exchanges/%2F/newOrders

# 4. Check binding configuration
# application.properties should have:
spring.cloud.function.definition=newOrders
spring.cloud.stream.bindings.newOrders-in-0.destination=newOrders
spring.cloud.stream.bindings.newOrders-in-0.group=barista-service
```

### Issue 2: Database Query Fails

**Error:**
```
Order id {id} is NOT valid.
```

**Root Cause:** Order not found in database

**Solutions:**

```bash
# 1. Verify order exists in database
docker exec -it final-spring-course-mariadb-final-spring-course-1 \
  mariadb -u springbucks -pspringbucks -e \
  "SELECT id, state FROM springbucks.t_order WHERE id = 1;"

# 2. Check both services use same database
# waiter-service application.properties:
spring.datasource.url=jdbc:mariadb://mariadb-final-spring-course:3306/springbucks

# barista-service application.properties:
spring.datasource.url=jdbc:mariadb://mariadb-final-spring-course:3306/springbucks
# ✅ Must match!
```

### Issue 3: Zipkin Trace Not Showing

**Symptom:**
```
Barista processes order but no trace in Zipkin UI
```

**Solutions:**

```bash
# 1. Verify Zipkin is consuming from RabbitMQ
curl -u spring:spring \
  http://localhost:15672/api/queues/%2F/zipkin | \
  jq '{consumers, messages}'
# Expected: consumers > 0

# 2. Check Zipkin container logs
docker logs zipkin-final-spring-course

# Expected: "Successfully connected to RabbitMQ"

# 3. Verify sender type configuration
# application.properties must have:
management.zipkin.tracing.sender.type=rabbit

# 4. Check sampling rate
# application.properties:
management.tracing.sampling.probability=1.0  # Must be > 0
```

### Issue 4: Barista ID is Null

**Symptom:**
```
Order processed but barista field is NULL in database
```

**Root Cause:** Property injection timing

**Solution:**

```bash
# Verify configuration
# application.properties should have:
order.barista-prefix=springbucks-

# OrderListener.java should have:
@Value("${order.barista-prefix}${random.uuid}")
private String barista;  # Generated once at startup

# Check barista value in logs
docker logs final-spring-course-final-barista-service-1 | \
  grep "barista-prefix"
```

## Best Practices

### 1. Message-Driven Architecture

**Advantages:**
- ✅ Async, non-blocking processing
- ✅ Natural backpressure (RabbitMQ queue buffering)
- ✅ Decoupled from HTTP request/response cycle
- ✅ Scales horizontally (multiple barista instances)

**Disadvantages:**
- ⚠️ No direct HTTP health check (relies on Consul)
- ⚠️ Debugging requires log analysis + Zipkin
- ⚠️ Message ordering not guaranteed (unless configured)

### 2. Zipkin Reporter Strategy

**Choose Reporter Type:**

```properties
# High-throughput services: Use RabbitMQ
management.zipkin.tracing.sender.type=rabbit  # ← Barista

# Low-moderate load services: Use HTTP
# (no sender.type property - HTTP is default)  ← Waiter, Customer
```

**Production Tuning:**

```properties
# Reduce sampling rate to minimize overhead
management.tracing.sampling.probability=0.1  # 10% sampling

# Configure RabbitMQ connection pool (if high load)
spring.rabbitmq.listener.simple.concurrency=5
spring.rabbitmq.listener.simple.max-concurrency=10
```

### 3. Transaction Management

**✅ Recommended: Use @Transactional**

```java
@Component
@Transactional  // Ensure atomic database operations
public class OrderListener {
    @Bean
    public Consumer<Long> newOrders() {
        return id -> {
            // All DB operations in single transaction
            // Message sent after transaction commits
        };
    }
}
```

### 4. Error Handling

**Add Retry and DLQ:**

```properties
# Retry configuration
spring.cloud.stream.bindings.newOrders-in-0.consumer.max-attempts=3
spring.cloud.stream.bindings.newOrders-in-0.consumer.back-off-initial-interval=1000

# Dead Letter Queue for failed messages
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.auto-bind-dlq=true
spring.cloud.stream.rabbit.bindings.newOrders-in-0.consumer.republish-to-dlq=true
```

### 5. Idempotency Design

**✅ Recommended: Handle duplicate messages**

```java
@Bean
public Consumer<Long> newOrders() {
    return id -> {
        CoffeeOrder order = orderRepository.findById(id).orElse(null);
        
        // Check if already processed
        if (order != null && order.getBarista() != null) {
            log.warn("Order {} already processed by {}, skipping.", id, order.getBarista());
            return;  // Skip duplicate processing
        }
        
        // Process order...
    };
}
```

## Horizontal Scaling

### Multiple Barista Instances

```bash
# Start 2 barista instances (same image, different containers)
docker-compose up -d --scale final-barista-service=2

# Check consumers
curl -u spring:spring \
  http://localhost:15672/api/queues/%2F/newOrders.barista-service | \
  jq '.consumers'
# Expected: 2 consumers

# Messages will be load-balanced across both instances
# Each order processed by only ONE barista (round-robin)
```

**Benefits:**
- ✅ Higher throughput (2x processing capacity)
- ✅ Load balancing (RabbitMQ distributes messages)
- ✅ High availability (if one instance fails, other continues)

## Comparison with Other Projects

| Project | HTTP API | Zipkin Reporter | Processing Model | Database |
|---------|----------|----------------|------------------|----------|
| **final-barista** | ❌ None | RabbitMQ (async) | Pure async message | MariaDB |
| **rabbitmq-barista** | ❌ None | ❌ None | Pure async message | MariaDB |
| **kafka-barista** | ❌ None | ❌ None | Kafka consumer | H2 |
| **simple-barista** | ✅ REST | ❌ None | HTTP API | H2 |

**Evolution:**

```
simple-barista (HTTP API)
   ↓ Add RabbitMQ
rabbitmq-barista (Message-driven)
   ↓ Add Zipkin + Docker
final-barista (Complete production-ready)
```

## References

- [Spring Cloud Stream Documentation](https://docs.spring.io/spring-cloud-stream/docs/current/reference/html/)
- [Spring Cloud Stream RabbitMQ Binder](https://docs.spring.io/spring-cloud-stream-binder-rabbit/reference/)
- [Zipkin RabbitMQ Reporter](https://github.com/openzipkin/zipkin-reporter-java)
- [RabbitMQ Topic Exchange](https://www.rabbitmq.com/tutorials/tutorial-five-java.html)
- [Micrometer Tracing](https://micrometer.io/docs/tracing)
- [Spring Cloud Consul](https://docs.spring.io/spring-cloud-consul/docs/current/reference/html/)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## About Us

我們主要專注在敏捷專案管理、物聯網（IoT）應用開發和領域驅動設計（DDD）。喜歡把先進技術和實務經驗結合，打造好用又靈活的軟體解決方案。近來也積極結合 AI 技術，推動自動化工作流，讓開發與運維更有效率、更智慧。持續學習與分享，希望能一起推動軟體開發的創新和進步。

## Contact

**風清雲談** - 專注於敏捷專案管理、物聯網（IoT）應用開發和領域驅動設計（DDD）。

- 🌐 官方網站：[風清雲談部落格](https://blog.fengqing.tw/)
- 📘 Facebook：[風清雲談粉絲頁](https://www.facebook.com/profile.php?id=61576838896062)
- 💼 LinkedIn：[Chu Kuo-Lung](https://www.linkedin.com/in/chu-kuo-lung)
- 📺 YouTube：[雲談風清頻道](https://www.youtube.com/channel/UCXDqLTdCMiCJ1j8xGRfwEig)
- 📧 Email：[fengqing.tw@gmail.com](mailto:fengqing.tw@gmail.com)

---

**⭐ If this project helps you, please give it a Star!**
