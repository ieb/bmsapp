# Implementation Plan - Cloud Protocol Implementation

This plan outlines the steps to finalize a production-ready telemetry protocol for remote battery monitoring.

## User Review Required

> [!IMPORTANT]
> **Privacy**: The `DeviceID` will be an anonymized UUID generated on the first run. No PII is sent to the cloud.

## Proposed Changes

### [Component] Services

#### [MODIFY] [cloud_service.dart](bms_app/lib/services/cloud_service.dart)
- Update [uploadTelemetry](bms_app/lib/services/cloud_service.dart#6-47) to use the refined JSON schema:
  - Header: `deviceId`, `protocolVersion`, `timestamp`, `appVersion`.
  - Data: `voltage`, `current`, `soc`, `temp`, `cells` (list), `activeAlerts` (list), `mosfetState`.
- Implement simple retry logic (3 attempts) using a loop or helper.

#### [MODIFY] [persistence_service.dart](bms_app/lib/services/persistence_service.dart)
- Add `_keyDeviceId`.
- Implement `getOrCreateDeviceId()`: Generate a UUID using [Random](bms_app/lib/services/bms_service.dart#87-118) or similar if not present, then persist and return.

#### [MODIFY] [service_manager.dart](bms_app/lib/services/service_manager.dart)
- Fetch `deviceId` from [PersistenceService](bms_app/lib/services/persistence_service.dart#5-81) on initialization.
- Pass `deviceId` and other metadata to `CloudService.uploadTelemetry`.

### [Component] Models

#### [MODIFY] [models.dart](bms_app/lib/core/models.dart)
- Add a `toJson()` helper to [BmsData](bms_app/lib/core/models.dart#1-140) to encapsulate protocol formatting logic.

---

## Verification Plan

### Manual Verification
1. **Schema Check**: Enable sync and inspect terminal logs to verify the new JSON structure contains `deviceId`, `cells`, and `activeAlerts`.
2. **DeviceID Persistence**: Verify the same `deviceId` is sent after app restart.
3. **Alert Sync**: Trigger a mock alert and verify it appears in the `activeAlerts` list in the cloud payload.
