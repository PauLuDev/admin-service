# ==========================================
# 1. Build Stage (Etapa de Compilación)
# ==========================================
FROM maven:3.9-eclipse-temurin-25-alpine AS build
WORKDIR /app

# Copiar el POM primero para aprovechar la caché de capas de Docker
COPY pom.xml ./

# Descargar dependencias en modo offline para acelerar futuras construcciones
RUN mvn dependency:go-offline -B

# Copiar el código fuente
COPY src ./src

# Compilar y empaquetar el JAR omitiendo tests
RUN mvn clean package -DskipTests

# ==========================================
# 2. Run Stage (Etapa de Ejecución en Producción)
# ==========================================
# Usamos la imagen oficial de ejecución de Eclipse Temurin para Java 25
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app

# Crear usuario de sistema no-root por seguridad en producción
RUN addgroup -S spring && adduser -S spring -G spring

# Copiar el .jar compilado desde el stage anterior
COPY --from=build /app/target/*.jar app.jar

# Asegurar que el usuario 'spring' sea el dueño del archivo JAR
RUN chown spring:spring app.jar

# Cambiar al usuario no-root
USER spring:spring

# Exponer el puerto por defecto que usa el microservicio (8081)
EXPOSE 9090

# Parámetros de optimización para la JVM en entornos de contenedores
ENTRYPOINT ["java", "-jar", "-Djava.security.egd=file:/dev/./urandom", "app.jar"]