#!/bin/bash

# Cafeteria Management System - VM Deployment Script
# VM IP: 35.198.196.99

echo "🚀 Building and Deploying Cafeteria Platform Services to VM..."

# Build Configuration
VM_IP="35.198.196.99"
CONFIG_PROFILE="git"
CONFIG_REPO_URI="https://github.com/ChamathDilshanC/cafeteria-config-repo.git"

# Step 1: Build JAR Files
echo "📦 Step 1: Building JAR files..."

echo "   Building Config Server..."
cd platform/config-server
mvn clean package -DskipTests
cd ../..

echo "   Building Service Registry..."
cd platform/service-registry
mvn clean package -DskipTests
cd ../..

echo "   Building API Gateway..."
cd platform/api-gateway
mvn clean package -DskipTests
cd ../..

# Step 2: Create VM deployment directory
echo "📁 Step 2: Creating VM deployment structure..."
mkdir -p vm-deployment/platform/jars
mkdir -p vm-deployment/platform/configs
mkdir -p vm-deployment/platform/scripts
mkdir -p vm-deployment/logs

# Step 3: Copy JAR files
echo "📋 Step 3: Copying JAR files..."
cp platform/config-server/target/*.jar vm-deployment/platform/jars/config-server.jar
cp platform/service-registry/target/*.jar vm-deployment/platform/jars/service-registry.jar
cp platform/api-gateway/target/*.jar vm-deployment/platform/jars/api-gateway.jar

# Step 4: Create environment configuration
cat > vm-deployment/platform/configs/vm-environment.env << 'EOF'
# VM Environment Configuration
VM_IP=35.198.196.99
CONFIG_PROFILE=git
CONFIG_REPO_URI=https://github.com/ChamathDilshanC/cafeteria-config-repo.git
CONFIG_LABEL=main

# Database Configuration
MYSQL_HOST=35.198.196.99
MYSQL_USER=cafeteria_user
MYSQL_PASSWORD=password123
MYSQL_DATABASE=cafeteria_db

MONGO_HOST=35.198.196.99
MONGO_USER=admin
MONGO_PASSWORD=adminpassword
MONGO_DATABASE=kitchen_service_db

# Eureka Configuration
EUREKA_URI=http://35.198.196.99:8761/eureka

# Security
JWT_SECRET=your-production-secret-key-change-this

# Ports
CONFIG_SERVER_PORT=8888
EUREKA_PORT=8761
GATEWAY_PORT=8080
EOF

# Step 5: Create startup scripts
cat > vm-deployment/platform/scripts/start-config-server.sh << 'EOF'
#!/bin/bash
source ../configs/vm-environment.env

echo "Starting Config Server..."
java -jar ../jars/config-server.jar \
  --spring.profiles.active=production \
  --spring.cloud.config.server.git.uri=${CONFIG_REPO_URI} \
  --spring.cloud.config.server.git.default-label=${CONFIG_LABEL} \
  --server.port=${CONFIG_SERVER_PORT} \
  --eureka.instance.hostname=${VM_IP} \
  --eureka.instance.ip-address=${VM_IP} \
  --eureka.client.service-url.default-zone=${EUREKA_URI} \
  > ../logs/config-server.log 2>&1 &

echo "Config Server started. Check logs: vm-deployment/logs/config-server.log"
echo "Config Server will be available at: http://${VM_IP}:${CONFIG_SERVER_PORT}"
EOF

cat > vm-deployment/platform/scripts/start-service-registry.sh << 'EOF'
#!/bin/bash
source ../configs/vm-environment.env

echo "Starting Service Registry..."
java -jar ../jars/service-registry.jar \
  --spring.profiles.active=production \
  --spring.config.import=configserver:http://${VM_IP}:${CONFIG_SERVER_PORT} \
  --server.port=${EUREKA_PORT} \
  --eureka.instance.hostname=${VM_IP} \
  > ../logs/service-registry.log 2>&1 &

echo "Service Registry started. Check logs: vm-deployment/logs/service-registry.log"
echo "Eureka Dashboard: http://${VM_IP}:${EUREKA_PORT}"
EOF

cat > vm-deployment/platform/scripts/start-api-gateway.sh << 'EOF'
#!/bin/bash
source ../configs/vm-environment.env

echo "Starting API Gateway..."
java -jar ../jars/api-gateway.jar \
  --spring.profiles.active=production \
  --spring.config.import=configserver:http://${VM_IP}:${CONFIG_SERVER_PORT} \
  --server.port=${GATEWAY_PORT} \
  --eureka.instance.hostname=${VM_IP} \
  --eureka.client.service-url.default-zone=${EUREKA_URI} \
  > ../logs/api-gateway.log 2>&1 &

echo "API Gateway started. Check logs: vm-deployment/logs/api-gateway.log"
echo "API Gateway available at: http://${VM_IP}:${GATEWAY_PORT}"
EOF

# Step 6: Create comprehensive startup script
cat > vm-deployment/platform/scripts/start-all-platform.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting Cafeteria Platform Services on VM..."

# Start services in order with delays
echo "1. Starting Config Server..."
./start-config-server.sh
sleep 15

echo "2. Starting Service Registry..."
./start-service-registry.sh
sleep 10

echo "3. Starting API Gateway..."
./start-api-gateway.sh
sleep 5

echo "✅ All platform services started!"
echo ""
echo "🔗 Service URLs:"
echo "   Config Server: http://35.198.196.99:8888"
echo "   Service Registry: http://35.198.196.99:8761"
echo "   API Gateway: http://35.198.196.99:8080"
echo ""
echo "📋 Test Config Server:"
echo "   curl http://35.198.196.99:8888/service-registry/default"
echo "   curl http://35.198.196.99:8888/api-gateway/default"
echo ""
echo "📝 Check logs in: vm-deployment/logs/"
EOF

# Make scripts executable
chmod +x vm-deployment/platform/scripts/*.sh

echo "✅ VM Deployment package created!"
echo ""
echo "📦 Deployment structure:"
find vm-deployment -type f | head -15
echo ""
echo "🚀 Next steps:"
echo "1. Upload vm-deployment/ folder to your VM"
echo "2. SSH to VM: ssh user@35.198.196.99"
echo "3. Run: cd vm-deployment/platform/scripts && ./start-all-platform.sh"
echo ""
echo "🔗 Test Config Server endpoint:"
echo "   http://35.198.196.99:8888/service-registry/default"