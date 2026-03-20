# ☮️ Paradise IDE — iOS Swift App

> Calm, creativity-first IDE for coding + stress-free learning + cross-platform builds.

---

## 📁 Project Structure

```
ParadiseIDE/
├── ParadiseIDE/
│   ├── ParadiseIDEApp.swift       # @main entry
│   ├── Models/
│   │   ├── Theme.swift            # All 4 paradise themes
│   │   └── EditorViewModel.swift  # All IDE state & logic
│   ├── Views/
│   │   ├── ContentView.swift      # Root layout
│   │   ├── TopBarView.swift       # Nav bar + theme picker
│   │   ├── FileTreeView.swift     # Sidebar file explorer
│   │   ├── EditorView.swift       # Code editor + AI panel
│   │   ├── VirtualPetView.swift   # Animated companion pet
│   │   ├── RightPanelView.swift   # AI status + build targets
│   │   ├── ExportView.swift       # YAML export + build sheet
│   │   └── SupportViews.swift     # Status bar, toast, particles
│   └── Resources/
│       └── Assets.xcassets
├── project.yaml                   # XcodeGen project spec
└── .github/workflows/build.yml    # iOS IPA build pipeline
```

---

## 🚀 Quick Start (Local)

### Prerequisites
```bash
brew install xcodegen
# Xcode 15+ required
```

### Generate & open project
```bash
git clone <your-repo>
cd ParadiseIDE
xcodegen generate --spec project.yaml
open ParadiseIDE.xcodeproj
```

Then press **⌘R** in Xcode to run on simulator or device.

---

## 📦 Build IPA via GitHub Actions

### Unsigned IPA (no Apple account needed)
1. Push to `main` or trigger **workflow_dispatch**
2. Set `sign_ipa = false` (default)
3. Download `ParadiseIDE-unsigned-ipa` from the Actions artifacts tab

### Signed IPA (for TestFlight / App Store)
Add these **repository secrets** in GitHub → Settings → Secrets:

| Secret | Description |
|--------|-------------|
| `CERTIFICATE_BASE64` | `base64 -i Certificates.p12` output |
| `CERTIFICATE_PASSWORD` | P12 password |
| `PROVISIONING_PROFILE_BASE64` | `base64 -i YourProfile.mobileprovision` |
| `APPLE_TEAM_ID` | 10-character Apple Team ID |

Then trigger workflow_dispatch with `sign_ipa = true`.

---

## 🎨 Themes

| Theme | Pet | Vibe |
|-------|-----|------|
| Deep Ocean | 🐠 | Cool blues, bubble particles |
| Golden Beach | 🦀 | Warm sunset, palm particles |
| Hawaii | 🦜 | Lush greens, tropical flowers |
| Sunset Palms | 🦩 | Pink magentas, dreamy sunset |

---

## 🌴 Core Philosophy

**Paradise IDE = flow state + calm companion + AI co-pilot + universal export**

- Errors never interrupt. They arrive as friendly "texts" from Paradise Tools.
- The virtual pet reacts to your coding intensity — never demanding, always supportive.
- Performance Mode disables all animations for maximum focus.
- Guide Mode provides gentle next-step hints for learners.
