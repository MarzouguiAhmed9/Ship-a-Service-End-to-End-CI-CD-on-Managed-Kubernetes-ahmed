1️⃣ Make sure the remote VM has an Ansible user

On the remote VM (192.168.194.135):

# Log in as root or a user with sudo
sudo adduser ansible
sudo usermod -aG sudo ansible      # optional: allow sudo

2️⃣ Generate SSH keys on your control VM

On the control VM (the machine running Ansible):

ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
# Press Enter for no passphrase


This creates:

~/.ssh/id_rsa → private key

~/.ssh/id_rsa.pub → public key

3️⃣ Copy your public key to the remote VM
ssh-copy-id ansible@192.168.194.135


This adds your key to /home/ansible/.ssh/authorized_keys on the remote VM

Test login:

ssh ansible@192.168.194.135
# Should log in without password

4️⃣ Add the remote VM to your inventory

Create a file (if not exist) like inventories/hosts.ini on the control VM:

[ci_runner]
runner1 ansible_host=192.168.194.135 ansible_user=ansible ansible_ssh_private_key_file=~/.ssh/id_rsa


runner1 → name you give to this host in playbooks

ansible_user → the remote user

ansible_ssh_private_key_file → path to private key on control VM

5️⃣ Optional: add host key to known_hosts

To avoid first-time prompt:

ssh-keyscan -H 192.168.194.135 >> ~/.ssh/known_hosts

6️⃣ Test Ansible connection
ansible -i inventories/hosts.ini all -m ping


Should return:

runner1 | SUCCESS => { "changed": false, "ping": "pong" }


✅ Summary:

Create user ansible on remote VM

Generate SSH keys on control VM

Copy public key to remote VM

Add remote VM to inventory

(Optional) ssh-keyscan for host key

Test connection with ansible -m ping





/////////////////////////////////
//////////////////////CI Runner Setup Playbook///////////
//////////////////////////////////////////////////////////

Install prerequisites → Installs curl, unzip, certificates, and tools needed for other installs.

Install Docker → Checks if Docker is already installed. If not, installs Docker, Docker CLI, containerd, buildx, and compose plugin.

Install kubectl → Downloads and installs kubectl so the runner can manage Kubernetes clusters.

Install Helm → Installs Helm to deploy apps using Helm charts.

Install Terraform → Downloads and unzips Terraform so the runner can create and manage cloud infrastructure.

Install AWS CLI v2 → Installs the AWS CLI to interact with AWS resources.

Assume IAM role via OIDC →

Uses the GitHub Actions token (GITHUB_TOKEN) to request temporary AWS credentials.

Exports AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN so the runner can authenticate to AWS (ECR, EKS) without storing permanent keys.

Handler: Restart Docker → If Docker config changed (like enabling buildx), restarts Docker to apply changes.


////////////////////////////////////////////
//////////////////////////////
Idempotent parts

apt tasks for prerequisites with state: present → safe to run multiple times.

handlers for restarting Docker → only triggered if daemon.json changes.

creates: for kubectl, Helm, Terraform, AWS CLI → prevents re-downloading if already installed.