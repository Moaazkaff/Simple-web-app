# Simple Web App: Ansible, Jenkins, Docker, and EC2

This project deploys a small static web page to an AWS EC2 instance. Terraform creates the networking and EC2 resources, Ansible installs Docker, Jenkins, and Ansible on that instance, and Jenkins runs an Ansible playbook that builds and starts the website as an Nginx Docker container.

## Architecture

```text
Developer / Git repository
        |
        v
Jenkins on an EC2 instance -- runs --> playbook2.yml
        |                                  |
        v                                  v
  Docker build and run <----------- Dockerfile + index.html
        |
        v
Website available at http://<EC2_PUBLIC_IP>/
```

## Repository contents

| Path | Purpose |
| --- | --- |
| `index.html` | Static page served to visitors. |
| `Dockerfile` | Builds an Nginx image containing `index.html`. |
| `playbook1.yml` | Installs Docker, Jenkins, and Ansible on the EC2 instance. |
| `playbook2.yml` | Rebuilds the website image and runs it as `front-container` on port 80. |
| `host-example.ini` | Example Ansible inventory for the EC2 instance. |
| `terraform/` | Terraform configuration for the VPC, public subnet, security group, and Jenkins EC2 instance. |

## Prerequisites

- An AWS account, configured AWS credentials, and an EC2 key pair.
- Terraform and Ansible installed on the machine used to provision the server.
- SSH access to the EC2 instance using the key pair.
- A Git repository accessible by Jenkins if you want Jenkins to check out the project automatically.

> **Security:** The Terraform security group exposes port `80` publicly for the website. It limits SSH (`22`) and Jenkins (`8080`) to `my_public_ip`. Set `my_public_ip` to your current public IP in CIDR notation, for example `203.0.113.10/32`. Do not commit AWS credentials, private keys, or a `terraform.tfvars` file containing sensitive values.

## 1. Provision the EC2 instance

The Terraform configuration expects values for the variables in `terraform/variable.tf`. Create a local `terraform/terraform.tfvars` file (keep it out of source control) with values appropriate for your AWS account:

```hcl
vpc-cidr           = "10.0.0.0/16"
public-subnet-cidr = "10.0.1.0/24"
default_route      = "0.0.0.0/0"
my_public_ip       = "YOUR.PUBLIC.IP/32"
instance_type      = "t3.micro"
key_pair           = "your-ec2-key-pair-name"
```

Then run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
terraform output -raw ec2-public-ip
```

> The current Terraform configuration contains `import` blocks for a specific VPC and subnet. Update or remove those blocks before applying if you are not intentionally importing those existing AWS resources.

## 2. Prepare the EC2 instance with Ansible

Copy the example inventory and replace the placeholder values with the EC2 public IP and the Ubuntu SSH user (usually `ubuntu`):

```bash
cp host-example.ini hosts.ini
```

Example `hosts.ini`:

```ini
[jenkins]
jenkins-server ansible_host=EC2_PUBLIC_IP ansible_user=ubuntu
```

Run the bootstrap playbook, supplying the path to your EC2 private key:

```bash
ansible-playbook -i hosts.ini playbook1.yml --private-key /path/to/key.pem
```

`playbook1.yml` installs Docker, adds the `jenkins` user to the Docker group, installs Jenkins and Ansible, and starts Jenkins. When it completes, open `http://EC2_PUBLIC_IP:8080` from the IP address allowed by `my_public_ip` and finish Jenkins' initial setup. Retrieve the initial administrator password on the EC2 instance with:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## 3. Run the website manually

To test the deployment before configuring Jenkins, run the application playbook from the repository root on the EC2 instance:

```bash
ansible-playbook playbook2.yml
```

The playbook stops and removes any existing `front-container`, removes the previous `front-image`, builds a fresh image from `Dockerfile`, and starts Nginx with port `80` exposed. Visit:

```text
http://EC2_PUBLIC_IP/
```

## 4. Create a Jenkins job for `playbook2.yml`

The following creates a Freestyle job that deploys the website on every build.

1. Open Jenkins at `http://EC2_PUBLIC_IP:8080` and sign in.
2. Select **New Item**, enter a name such as `deploy-simple-web-app`, choose **Freestyle project**, and select **OK**.
3. In **Source Code Management**, choose **Git** and enter this project's repository URL. Add Jenkins credentials if the repository is private. If the project is already copied to the EC2 instance instead, you can leave source control unconfigured and set the job's custom workspace to the repository directory.
4. Under **Build Steps**, choose **Execute shell** and use:

   ```bash
   ansible-playbook playbook2.yml
   ```

5. Save the job and select **Build Now**. Jenkins checks out the project, then runs the playbook locally on the EC2 instance.
6. Open `http://EC2_PUBLIC_IP/` to confirm the updated page is live.

For automatic deployments, configure a repository webhook to trigger the Jenkins job on pushes, or enable **Poll SCM** with a schedule suitable for your project.

## Troubleshooting

- **Jenkins cannot run Docker:** Confirm the service was restarted after `jenkins` joined the Docker group, then run `sudo systemctl restart jenkins`.
- **Website does not open:** Confirm port `80` is allowed in the EC2 security group and inspect the container with `docker ps` and `docker logs front-container`.
- **Jenkins does not open:** Verify port `8080` is allowed from your current public IP and check `sudo systemctl status jenkins`.
- **Ansible cannot connect during bootstrap:** Verify the EC2 public IP, `ansible_user`, SSH key path, and the port `22` inbound rule.
