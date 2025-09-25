# SpringBucks 咖啡師微服務 ⚡

[![Java](https://img.shields.io/badge/Java-21-orange.svg)](https://www.oracle.com/java/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.4.5-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Spring Cloud](https://img.shields.io/badge/Spring%20Cloud-2024.0.2-blue.svg)](https://spring.io/projects/spring-cloud)
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue.svg)](https://www.docker.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 專案介紹

本專案為 SpringBucks 咖啡店系統的咖啡師微服務，負責處理咖啡製作、訂單狀態更新、以及與訊息佇列系統的整合。此服務展示了現代微服務架構中後端處理服務的設計模式，包含訊息驅動架構、服務發現、鏈路追蹤等核心功能。

**核心功能：**
- **咖啡製作處理**：接收咖啡製作請求，處理咖啡製作流程
- **訂單狀態管理**：更新訂單狀態，追蹤製作進度
- **訊息驅動架構**：透過 RabbitMQ 接收與處理訊息
- **服務發現**：自動向 Consul 服務註冊中心註冊服務實例
- **鏈路追蹤**：整合 Zipkin 進行分散式鏈路追蹤
- **健康監控**：提供完整的服務健康檢查與監控指標

> 💡 **為什麼選擇此微服務架構？**
> - 展示訊息驅動微服務的完整設計模式
> - 整合現代化的服務治理與監控工具
> - 支援非同步處理與事件驅動架構
> - 提供完整的分散式系統追蹤能力

### 🎯 專案特色

- **訊息驅動架構**：使用 Spring Cloud Stream 實現訊息驅動的微服務
- **非同步處理**：透過 RabbitMQ 實現非同步訊息處理
- **服務發現**：整合 Consul 進行服務註冊與發現
- **鏈路追蹤**：整合 Zipkin 進行分散式系統的請求追蹤
- **容器化部署**：支援 Docker 打包與部署，便於環境一致性
- **監控整合**：支援 Prometheus 指標收集與健康檢查

## 技術棧

### 核心框架
- **Spring Boot 3.4.5** - 主框架，提供自動配置與生產就緒功能
- **Spring Cloud 2024.0.2** - 微服務框架，提供服務治理功能
- **Spring Cloud Stream** - 訊息驅動微服務框架
- **Spring Data JPA** - 資料持久層框架

### 微服務與監控
- **Consul** - 服務註冊與發現中心
- **Zipkin** - 分散式鏈路追蹤系統
- **Micrometer** - 應用程式指標收集
- **RabbitMQ** - 訊息佇列系統

### 資料庫與訊息
- **MariaDB** - 主要資料庫
- **RabbitMQ** - 訊息佇列系統
- **Spring Cloud Stream Binder Rabbit** - RabbitMQ 整合

### 開發工具與輔助
- **Lombok** - 減少樣板程式碼
- **Docker** - 容器化部署
- **Maven** - 專案建構與依賴管理

## 專案結構

```
final-barista-service/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── tw/fengqing/spring/springbucks/barista/
│   │   │       ├── BaristaServiceApplication.java          # 主要應用程式入口
│   │   │       ├── model/                                 # 資料模型
│   │   │       │   ├── Coffee.java                      # 咖啡實體
│   │   │       │   ├── CoffeeOrder.java                 # 咖啡訂單實體
│   │   │       │   └── OrderState.java                  # 訂單狀態枚舉
│   │   │       ├── repository/                          # 資料存取層
│   │   │       │   └── CoffeeOrderRepository.java      # 訂單資料存取
│   │   │       ├── service/                             # 業務邏輯層
│   │   │       │   └── BaristaService.java             # 咖啡師業務邏輯
│   │   │       └── integration/                        # 整合層
│   │   │           └── OrderListener.java              # 訂單訊息監聽器
│   │   └── resources/
│   │       ├── application.properties                    # 應用程式配置
│   │       └── bootstrap.properties                      # 啟動配置
│   └── test/
├── Dockerfile                                            # Docker 建構檔案
├── pom.xml                                              # Maven 專案配置
└── README.md                                            # 專案說明文件
```

## 快速開始

### 前置需求
- **Java 21** - 最新 LTS 版本的 Java
- **Maven 3.6+** - 專案建構工具
- **Docker** - 容器化部署（選用）
- **MariaDB** - 資料庫（或使用 Docker 容器）
- **RabbitMQ** - 訊息佇列系統（或使用 Docker 容器）
- **Consul** - 服務註冊中心（或使用 Docker 容器）
- **Zipkin** - 鏈路追蹤系統（或使用 Docker 容器）

### 安裝與執行

1. **克隆此倉庫：**
```bash
git clone https://github.com/username/springbucks-microservices.git
```

2. **進入專案目錄：**
```bash
cd Chapter\ 16\ 服務鏈路追蹤/final-barista-service
```

3. **編譯專案：**
```bash
mvn clean compile
```

4. **執行應用程式：**
```bash
mvn spring-boot:run
```

### Docker 部署

1. **建構 Docker 映像檔：**
```bash
mvn clean package dockerfile:build
```

2. **執行 Docker 容器：**
```bash
docker run -p 8070:8070 springbucks/final-barista-service:0.0.1-SNAPSHOT
```

3. **使用 Docker Compose 啟動完整環境：**
```bash
cd Chapter\ 16\ 服務鏈路追蹤
docker-compose up -d
```

## 進階說明

### 環境變數
```properties
# 資料庫配置
SPRING_DATASOURCE_URL=jdbc:mariadb://localhost:3306/springbucks
SPRING_DATASOURCE_USERNAME=springbucks
SPRING_DATASOURCE_PASSWORD=springbucks

# RabbitMQ 配置
SPRING_RABBITMQ_HOST=localhost
SPRING_RABBITMQ_PORT=5672
SPRING_RABBITMQ_USERNAME=spring
SPRING_RABBITMQ_PASSWORD=spring

# Consul 配置
SPRING_CLOUD_CONSUL_HOST=localhost
SPRING_CLOUD_CONSUL_PORT=8500

# Zipkin 配置
MANAGEMENT_TRACING_ENDPOINT=http://localhost:9411/api/v2/spans
```

### 設定檔說明
```properties
# application.properties 主要設定
spring.application.name=barista-service
server.port=8070

# 資料庫配置
spring.datasource.url=${SPRING_DATASOURCE_URL}
spring.jpa.hibernate.ddl-auto=update

# 服務發現配置
spring.cloud.consul.discovery.service-name=${spring.application.name}
spring.cloud.consul.discovery.health-check-interval=10s

# 訊息佇列配置
spring.cloud.stream.rabbit.binder.host=${SPRING_RABBITMQ_HOST}
spring.cloud.stream.rabbit.binder.port=${SPRING_RABBITMQ_PORT}
```

## 訊息處理架構

### 訂單處理流程
本服務透過 Spring Cloud Stream 處理來自 RabbitMQ 的訂單訊息：

```java
@StreamListener(OrderProcessor.ORDER_INPUT)
public void handleOrder(CoffeeOrder order) {
    log.info("收到訂單: {}", order);
    
    // 處理咖啡製作邏輯
    processCoffeeOrder(order);
    
    // 更新訂單狀態
    updateOrderState(order);
}
```

### 訊息綁定配置
```java
public interface OrderProcessor {
    String ORDER_INPUT = "orderInput";
    
    @Input(ORDER_INPUT)
    SubscribableChannel orderInput();
}
```

## API 端點

### 咖啡師服務
- `GET /actuator/health` - 健康檢查
- `GET /actuator/metrics` - 應用程式指標
- `GET /actuator/prometheus` - Prometheus 指標

### 訊息處理
- 自動處理來自 RabbitMQ 的訂單訊息
- 支援訂單狀態更新與追蹤
- 整合鏈路追蹤進行訊息處理監控

## 服務整合

### 與訊息佇列整合
本服務透過 Spring Cloud Stream 與 RabbitMQ 進行整合：

```java
@EnableBinding(OrderProcessor.class)
@SpringBootApplication
public class BaristaServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(BaristaServiceApplication.class, args);
    }
}
```

### 鏈路追蹤配置
```java
@Bean
public Sender sender(Tracer tracer) {
    return new TracingSender(tracer);
}
```

## 參考資源

- [Spring Boot 官方文件](https://spring.io/projects/spring-boot)
- [Spring Cloud Stream 官方文件](https://spring.io/projects/spring-cloud)
- [RabbitMQ 官方文件](https://www.rabbitmq.com/documentation.html)
- [Consul 官方文件](https://www.consul.io/docs)
- [Zipkin 官方文件](https://zipkin.io/)

## 注意事項與最佳實踐

### ⚠️ 重要提醒

| 項目 | 說明 | 建議做法 |
|------|------|----------|
| 訊息處理 | RabbitMQ 連線管理 | 設定適當的連線池與重試機制 |
| 資料庫操作 | JPA 事務管理 | 確保資料一致性與事務邊界 |
| 服務發現 | Consul 健康檢查 | 定期檢查服務健康狀態 |
| 鏈路追蹤 | Zipkin 採樣率 | 生產環境調整採樣率以降低效能影響 |

### 🔒 最佳實踐指南

- **訊息處理**：使用 Spring Cloud Stream 實現聲明式訊息處理，提升程式碼可讀性
- **非同步處理**：透過 RabbitMQ 實現非同步訊息處理，提升系統效能
- **資料一致性**：使用 JPA 事務管理確保資料一致性
- **監控告警**：整合 Prometheus 和 Grafana 進行系統監控
- **容器化**：使用 Docker 確保環境一致性，便於部署和擴展

## 授權說明

本專案採用 MIT 授權條款，詳見 LICENSE 檔案。

## 關於我們

我們主要專注在敏捷專案管理、物聯網（IoT）應用開發和領域驅動設計（DDD）。喜歡把先進技術和實務經驗結合，打造好用又靈活的軟體解決方案。

## 聯繫我們

- **FB 粉絲頁**：[風清雲談 | Facebook](https://www.facebook.com/profile.php?id=61576838896062)
- **LinkedIn**：[linkedin.com/in/chu-kuo-lung](https://www.linkedin.com/in/chu-kuo-lung)
- **YouTube 頻道**：[雲談風清 - YouTube](https://www.youtube.com/channel/UCXDqLTdCMiCJ1j8xGRfwEig)
- **風清雲談 部落格**：[風清雲談](https://blog.fengqing.tw/)
- **電子郵件**：[fengqing.tw@gmail.com](mailto:fengqing.tw@gmail.com)

---

**📅 最後更新：2025-01-27**  
**👨‍💻 維護者：風清雲談團隊**
