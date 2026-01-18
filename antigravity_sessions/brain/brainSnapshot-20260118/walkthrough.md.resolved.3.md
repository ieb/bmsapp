# Walkthrough - BMS Monitor App

I have successfully built the initial version of the BMS Monitor App using Flutter, based on the Stitch designs.

## Features Implemented

### 1. **Core Architecture**
-   **Flutter Project**: Created `bms_app` with a structured feature-based folder layout.
-   **Theme**: Implemented [AppTheme](bms_app/lib/core/theme.dart#4-54) using the specific color palette from Stitch's HTML export (`#107070` Primary, Dark Mode support).
-   **Services**: 
    -   [BmsService](bms_app/lib/services/bms_service.dart#5-12): Abstract base class.
    -   [BleBmsService](bms_app/lib/services/ble_service.dart#8-271): **(UPDATED)** Implemented robust **JBD / Xiaoxiang BMS Protocol** (Service UUID: `0000ff00...`). 
        -   Includes persistent `autoConnect` logic and state management.
        -   **Polling**: Automatically polls for Basic Info (`0x03`) and Cell Voltages (`0x04`) every 2 seconds.
        -   **Parsing**: Decodes voltage, current, power, SoC, temperatures, protections (partial), and individual cell voltages.
    -   [SeaSmartService](bms_app/lib/services/seasmart_service.dart#7-232): **(UPDATED)** Implemented **SeaSmart / NMEA 2000 Protocol**.
        -   **Stream**: Connects to HTTP stream awaiting `$PCDIN` sentences.
        -   **Parsing**: Decodes PGN `127508` (DC Battery Status) and PGN `130829` (JBD Registers mapped to N2K).
    -   [MockBmsService](bms_app/lib/services/bms_service.dart#13-76): Available for testing.

### 2. **Screens**

#### **Connection Screen**
-   **HTTP**: "Connect via HTTP" button wires up [SeaSmartService](bms_app/lib/services/seasmart_service.dart#7-232) (currently transitions to Dashboard, assumes successful connection).
-   **BLE**: "Scan & Connect BLE" shows a live list of Bluetooth devices. Clicking "Connect" pairs with the device using [BleBmsService](bms_app/lib/services/ble_service.dart#8-271), discovers the JBD service, starts polling, and navigates to the Dashboard.

#### **Dashboard Screen**
-   **SoC Gauge**: Custom-painted circular gauge showing State of Charge.
-   **Metrics**: Real-time Voltage, Current, and Power display using "Glass Card" UI components.
-   **Navigation**: Bottom navigation bar to switch between views.

#### **Details Screen**
-   **Cell Voltages**: Grid view showing individual cell voltages (populates from JBD protocol `0x04` command).
-   **Temperatures**: Display of internal and MOSFET temperatures (populates from JBD protocol `0x03` command).

#### **Settings Screen**
-   Placeholder implementation showing protection limits and app settings.

## Verification

### Static Analysis
Ran `flutter analyze` to ensure code quality.
-   **Result**: All issues resolved. Codebase is clean.

### Real Services
-   **BLE**: 
    -   Downgraded to `flutter_blue_plus` 1.32.0 for stability.
    -   Scanning works.
    -   **Protocol Verified**: Implemented logic matches `bmsblereader.js` reference provided by user.
-   **HTTP**:
    -   Implemented logic matches `bmsseasmartreader.js`.
    -   Parses PGNs `127508` and `130829`.

## Next Steps
-   **Historical Charts**: Add `fl_chart` integration for voltage/current trends.
-   **Alerts & Logs**: Implement event logging based on protection status bits.
