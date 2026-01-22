---
description: Build and install the ETPattern app to the connected iPhone 16 Plus
---

# Deploy to iPhone 16 Plus

This workflow automates the process of building, installing, and launching the ETPattern application on a connected iPhone 16 Plus device.

## Prerequisites

- Your iPhone 16 Plus must be connected via USB or available over the network.
- Developer Mode must be enabled on the device.
- The `xcbeautify` tool is recommended for readable build output.

## Deployment Steps

// turbo

1. Run the deployment script from the project root:

```bash
# This script automatically detects the booted simulator or connected device.
# It performs a clean install (uninstall -> install) to ensure stability.
./deploy.sh
```

## Troubleshooting

- **Launch Failed**: If `simctl launch` fails with a "denied by service delegate" error, launch the app **manually** from the Simulator home screen.
- **Device not found**: Ensure your device is "trusted" and visible in `xcrun devicectl list devices`.
- **Build fails**: Check if there are any code errors or signing issues in Xcode.
- **Permission denied**: Ensure you've run `chmod +x deploy.sh`.
