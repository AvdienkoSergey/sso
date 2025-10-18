# SSO

## Setting up the environment

### If you use Windows

1) Taskfile.yml

```bash
# Create a directory for binaries
mkdir -p ~/bin

# Download last version program
curl -L https://github.com/go-task/task/releases/download/v3.39.2/task_windows_amd64.zip -o /tmp/task.zip

# Open
cd /tmp
unzip -o task.zip

# Move to в ~/bin
mv task.exe ~/bin/

# Add ~/bin in PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Restart bashrc
source ~/.bashrc

# Check result
task --version
```

2)  task check-deps

```bash
# Install gh
go install github.com/cli/cli/v2/cmd/gh@latest

# Добавить в PATH, если еще не добавлено
echo 'export PATH="$(go env GOPATH)/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Проверить
gh --version
```