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