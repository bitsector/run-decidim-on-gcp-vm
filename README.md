# Deploying a Docker Compose App on GCP Using Terraform and Snapshots

This README provides concise steps and bash commands for deploying a Docker Compose app on a Google Cloud Platform (GCP) virtual machine (VM) using Terraform and snapshots.


## Steps to Deploy

### 1. Initialize and Apply Terraform Configuration
Provision the VM using Terraform.

```bash
terraform init
terraform plan
terraform apply
```
---

### 2. SSH into the VM
Access the VM to configure Docker and deploy the app.

```bash
gcloud compute ssh decidim-vm --zone=us-central1-a
```
---

### 3. Configure Docker and Docker Compose on the VM
Run these commands inside the VM to set up Docker.

```bash
apt-get update
apt-get install -y
apt-transport-https
ca-certificates
curl
software-properties-common
git

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -aG docker $USER
```
---

### 4. Clone and Run the Decidim App (Example App)
Set up and run the Decidim app using Docker Compose.
```bash
mkdir -p /opt/decidim && cd /opt/decidim
git clone https://github.com/decidim/docker.git
cd docker
docker compose up -d
```
Check logs to ensure the app is running:
```bash
docker-compose logs -f
```
---

### 5. Verify Application Port (3000)
Ensure the application is listening on port `3000`.
```bash
sudo lsof -i :3000
```
---

### 6. Create a Snapshot of the Disk (Optional)
Create a snapshot for backup or future deployments.
```bash
gcloud compute disks snapshot decidim-boot-disk --zone=us-central1-a --storage-location=us-central1 --snapshot-names=decidim-snapshot-feb2025
```
Verify the snapshot:
```bash
gcloud compute snapshots describe decidim-snapshot-feb2025
```

---

### 7. Redeploy VM from Snapshot (Optional)
Use Terraform to provision a new VM from the snapshot.
```bash
terraform init
terraform plan
terraform apply -var="snapshot_name=decidim-snapshot-feb2025"
```
---

### 8. Access the Application

#### Option A: Port Forwarding to Local Machine
```bash
gcloud compute ssh decidim-vm --zone=us-central1-a -- -L 3000:localhost:3000
```

Visit `http://localhost:3000` in your browser.

#### Option B: External IP Access
```bash
gcloud compute instances describe decidim-vm --format='get(networkInterfaces.accessConfigs.natIP)'
```

Visit `http://<external-ip>:3000` in your browser.

---

## Clean Up Resources

Delete the VM when no longer needed:
```bash
gcloud compute instances delete decidim-vm --zone=us-central1-a
```