---
description: How to setup Xcode Cloud for ETPattern
---

# Setup Xcode Cloud

1. **Open Xcode**: Open the `ETPattern.xcodeproj` project.
2. **Open Cloud Tab**: Go to the **Report Navigator** (last tab in left sidebar) or choose **Product** > **Xcode Cloud** from the menu bar.
3. **Create Workflow**: Click "Create Workflow" or "Get Started...".
4. **Select Product**: Ensure `ETPattern` app is selected.
5. **Review Workflow**:
    - Xcode creates a default "Default Workflow".
    - Click "Next".
6. **Grant Access**:
    - You will be prompted to grant Xcode Cloud access to your source code (likely GitHub).
    - Click "Grant Access..." and follow the browser prompts to authorize your Apple ID with GitHub.
7. **Complete Setup**:
    - Once authorized, click "Next" and then "Start Build".

## Verification

- After the setup, Xcode will trigger a build on Xcode Cloud.
- Monitor the build status in the Report Navigator.
- You should see a green checkmark indicating "Success".

## Troubleshooting

- **Bundle ID errors**: Ensure your Apple Developer Program membership is active and the Bundle ID `com.jackxhb.ETPattern` is registered.
- **Script errors**: If the build fails at "Post-Clone", check `ci_scripts/ci_post_clone.sh`.

## Alternative: Web Interface (App Store Connect)

If Xcode is crashing or unstable, you can configure the workflow directly on the web:

1. **Log in**: Go to [App Store Connect](https://appstoreconnect.apple.com) and log in.
2. **Select App**: Click on **My Apps** and select **ETPattern**.
3. **Xcode Cloud Tab**: Click on the **Xcode Cloud** tab in the top navigation bar.
4. **Manage Workflows**:
    - If this is your first time, click **Get Started**.
    - If you already have workflows, click **Manage Workflows** in the sidebar.
5. **Create Workflow**:
    - Click the **(+)** button next to "Workflows".
    - Select your repository (`jackyxhb/ETPattern`). You may need to authorize GitHub access if listed as "unconnected".
6. **Configuration**:
    - **Name**: "Default" (or verify default).
    - **Primary Repository**: Ensure `jackyxhb/ETPattern` / `main` is selected.
    - **Environment**: Select the latest **macOS** and **Xcode** versions compatible with your project (e.g., Xcode 15/16).
7. **Start Build**:
    - Save the workflow.
    - Click **Start Build** to verify everything connects correctly.
