# Implementation Plan - Cloud Integration (Skeleton)

This plan outlines the steps to implement the foundation for remote battery monitoring. This include a `CloudService` for telemetry uploads, persistent cloud settings, and a dedicated UI section in the Settings screen.

## User Review Required

> [!IMPORTANT]
> **API Endpoint**: This skeleton uses a placeholder URL. For a production environment, a real backend (e.g., Firebase, AWS IoT, or a custom REST API) would be required.

## Proposed Changes

### [Component] Services

#### [NEW] [cloud_service.dart](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/services/cloud_service.dart)
- Create `CloudService` class to handle http communication with a remote telemetry endpoint.
- Implement `uploadTelemetry(BmsData data)` method with logging for observability.
- Implement a `testConnection(String endpoint, String apiKey)` method.

#### [MODIFY] [persistence_service.dart](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/services/persistence_service.dart)
- Add keys: `_keyCloudEnabled`, `_keyCloudEndpoint`, `_keyCloudApiKey`.
- Implement getters and setters for these keys.

#### [MODIFY] [service_manager.dart](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/services/service_manager.dart)
- Integrate `CloudService` into the constructor.
- Add `_cloudSyncTimer` to handle periodic uploads (e.g., every 30 seconds).
- Listen to the active [BmsService](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/services/bms_service.dart#6-18) stream and store the latest [BmsData](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/core/models.dart#1-140) for the sync loop.

### [Component] Features

#### [MODIFY] [settings_screen.dart](file:///Users/ieb/timefields/antigravity/bmsapp/bms_app/lib/features/settings/settings_screen.dart)
- Add a "Cloud Integration" `GlassCard` (before Maintenance).
- Include `SwitchListTile` for "Enable Sync".
- Add `TextField` sections for "Endpoint URL" and "API Key".
- Add a "SAVE CLOUD SETTINGS" button.
- Add a "TEST CONNECTION" button with a loading indicator.

---

## Verification Plan

### Automated Tests
- N/A (Unit tests for `CloudService` can be added later once a real protocol is defined).

### Manual Verification
1. **Cloud Settings Persistence**:
   - Toggle "Enable Sync", change the endpoint to `https://api.example.com`, and save.
   - Refesh the app and verify the values are still there.
2. **Telemetry Sync**:
   - Enable sync.
   - Observe terminal logs for periodic `[CloudService] Uploading telemetry to...` messages.
3. **Connection Test**:
   - Click "TEST CONNECTION".
   - Verify a "Connection Successful" or "Connection Failed" snackbar appears.
