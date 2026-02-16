# Omarchy Forge

Automated setup and configuration management for Omarchy desktop environment.

## Directory Structure

```
omarchy-forge/
├── apps/           # Application installation scripts
├── scripts/        # Utility scripts
├── configs/        # Configuration files to be deployed
├── hooks/          # Omarchy hooks integration
└── bootstrap.sh    # Main setup script
```

## Usage

Run the bootstrap script to apply all configurations:

```bash
./bootstrap.sh
```

Or install specific applications:

```bash
./apps/brave-browser.sh
```

## Adding New Applications

1. Create a new script in `apps/` directory
2. Make it executable: `chmod +x apps/your-app.sh`
3. Add it to the bootstrap script if it should run automatically
