# Deployment of PaySoko Application with CI/CD Pipeline

This project demonstrates how to deploy a full-stack application consisting of a frontend, backend, and MongoDB database using Kubernetes, Helm, and a CI/CD pipeline.

## Design Decisions

- **Infrastructure as Code (IaC)**: Terraform is used to automate the provisioning of infrastructure, ensuring consistency and repeatability across environments.
  
- **Containerization**: Both the frontend and backend applications are containerized with Docker, ensuring that they run the same in every environment.

- **Kubernetes**: Kubernetes is used to manage the containerized applications. It helps with scaling, load balancing, and fault tolerance.

- **Helm**: Helm is used to simplify Kubernetes deployments and manage application configurations.

- **CI/CD Pipeline**: GitHub Actions is set up to automate the process of building, testing, and deploying the applications.

- **Monitoring**: Prometheus and Grafana are used for monitoring and visualizing the performance of the applications.

---

## Steps to Deploy the Infrastructure and Application

### 1. **Provision Infrastructure with Terraform**

1. Clone the repository and navigate to the Terraform configuration files.
2. Run the following commands to create the infrastructure:
    ```bash
    terraform init
    terraform plan
    terraform apply
    ```
   This will create:
   - Two web servers (frontend and backend).
   - A cloud-based MongoDB database.
   - Auto-scaling for web servers.

### 2. **Build and Push Docker Images**

1. Build the frontend and backend Docker images:
    ```bash
    docker build -f frontend/Dockerfile_Frontend -t paysoko_frontend frontend/
    docker build -f backend/Dockerfile_Backend -t paysoko_backend backend/
    ```

2. Push the images to your container registry (e.g., AWS ECR):
    ```bash
    docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/frontend:latest
    docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/backend:latest
    ```

### 3. **Deploy Applications to Kubernetes**

1. Apply the Kubernetes deployments:
    ```bash
    kubectl apply -f k8s/paysoko_frontend_deployment.yaml
    kubectl apply -f k8s/paysoko_backend_deployment.yaml
    ```

2. Apply the Kubernetes secrets:
    ```bash
    kubectl apply -f k8s/secrets.yaml
    ```

3. Ensure the deployments are successful:
    ```bash
    kubectl rollout status deployment/paysoko-frontend
    kubectl rollout status deployment/paysoko-backend
    ```

### 4. **Set Up Monitoring with Prometheus and Grafana**

1. Add Helm charts for Prometheus and Grafana:
    ```bash
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    ```

2. Deploy Prometheus and Grafana:
    ```bash
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
    helm upgrade --install grafana grafana/grafana --namespace monitoring --create-namespace
    ```

### 5. **Set Up CI/CD with GitHub Actions**

1. The pipeline in `.github/workflows/deploy.yml` handles:
   - Building Docker images for the frontend and backend.
   - Pushing the images to AWS ECR.
   - Deploying the applications to Kubernetes.
   - Installing Prometheus and Grafana.

2. To trigger the pipeline, push your changes to the `main` branch:
    ```bash
    git push origin main
    ```

The CI/CD pipeline will automatically build, push, and deploy the changes.

---

## Final Notes

- Prometheus and Grafana will monitor the paysoko applications.
- The CI/CD pipeline handles the automation of building and deploying the application.


