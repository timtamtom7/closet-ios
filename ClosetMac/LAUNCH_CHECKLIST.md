# ClosetMac — Launch Checklist

## Pre-Launch

### App Store
- [ ] App Store Connect account active (paid developer or free)
- [ ] App name confirmed: **ClosetMac**
- [ ] Tagline: *"Your wardrobe, curated."*
- [ ] Description written (see `Marketing/APPSTORE.md`)
- [ ] Screenshots captured at 1280×800 and 900×600
- [ ] Keywords set: wardrobe, closet, outfit, fashion, style, clothing, tracker, mac
- [ ] Category: Lifestyle
- [ ] Age rating: 4+
- [ ] Privacy policy URL ready
- [ ] Support URL ready

### Build & Sign
- [ ] Bundle ID: `com.closet.closetmac`
- [ ] Team ID configured in Xcode
- [ ] Hardened Runtime enabled (for notarization)
- [ ] Sandbox enabled
- [ ] `com.apple.security.app-sandbox` = true
- [ ] `com.apple.security.network.client` = true (if weather API calls)
- [ ] Release build succeeds: `xcodebuild -scheme ClosetMac -configuration Release`
- [ ] Code signed with Developer ID (for direct distribution)
- [ ] Notarized (if distributing outside App Store)

### Code & Assets
- [ ] App icon: 16, 32, 128, 256, 512, 1024 px + macOS @1x/@2x
- [ ] No placeholder strings in UI
- [ ] All hardcoded colors replaced with Theme tokens ✅ (R13 audit done)
- [ ] `LSMinimumSystemVersion` set correctly
- [ ] `NSSupportsAutomaticTermination` = false (if background services needed)
- [ ] Privacy descriptions in Info.plist:
  - `NSLocationWhenInUseUsageDescription` (if weather uses location)
  - `NSPhotoLibraryUsageDescription` (if importing photos)

### Documentation
- [ ] `Marketing/APPSTORE.md` complete
- [ ] `README.md` updated with install/run instructions
- [ ] License file present (MIT default)

---

## Launch Day

- [ ] Upload build to App Store Connect
- [ ] Fill in all Storefront metadata
- [ ] Upload screenshots
- [ ] Select build version
- [ ] Submit for review
- [ ] Monitor App Store Connect for "In Review" → "Approved"

---

## Post-Launch

- [ ] Confirm app is live on the Mac App Store
- [ ] Test fresh install on a clean machine
- [ ] Announce (if applicable)
- [ ] Monitor for crash reports / reviews
- [ ] Update MEMORY.md with launch date
