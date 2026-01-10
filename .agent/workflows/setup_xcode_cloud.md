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
