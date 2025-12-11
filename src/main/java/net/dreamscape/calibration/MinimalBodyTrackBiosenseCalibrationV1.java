package net.dreamscape.calibration;

import java.time.LocalDate;
import java.util.*;

/**
 * Minimal, implementation-agnostic descriptor layer for:
 * - AR/VR body-tracking calibration (optical + IMU)
 * - Neuromorphic biosensing calibration (multi-analyte)
 * - Hospital / lab logistics and ISO 13485-style traceability
 *
 * No vendor secrets, no PHI, suitable for public GitHub repositories.
 */
public final class MinimalBodyTrackBiosenseCalibrationV1 {

    // ----------------------------------------------------------
    // 1. Global calibration and traceability constants
    // ----------------------------------------------------------

    public static final class CalibrationConstants {
        public static final UUID REGISTRY_ID =
                UUID.fromString("ffffffff-ffff-4fff-8fff-ffffffffbb01");
        public static final String REGISTRY_LABEL =
                "Minimal-BodyTrack-Biosense-Calibration-Grid";
        public static final String REGISTRY_VERSION = "1.0.0";
        public static final String REGISTRY_COMPLIANCE_TAG =
                "ISO13485-CAL-READY";

        // Motion systems target sub‑cm error in well-calibrated volumes.
        public static final double MAX_ALLOWED_CAL_DRIFT_MM = 2.0;

        // Biosensor gain/offset drift per calibration interval (percentage).
        public static final double MAX_ALLOWED_CAL_DRIFT_PCT = 5.0;

        // Upper bound for non‑critical devices; critical devices may override to shorter intervals.
        public static final int MAX_CAL_INTERVAL_DAYS = 365;

        private CalibrationConstants() { }
    }

    // ----------------------------------------------------------
    // 2. Device families for body tracking and biosensing
    // ----------------------------------------------------------

    public enum DeviceClass {
        BODY_TRACKING,
        BIOSENSING,
        IMAGING,
        HYBRID
    }

    public static final class DeviceFamilyProfile {
        public final UUID id;
        public final String familyCode;
        public final DeviceClass deviceClass;
        public final List<String> modalityTags;
        public final String description;
        public final boolean requires3dReference;
        public final boolean requiresPhysicalPhantom;
        public final boolean iso13485Relevant;

        public DeviceFamilyProfile(
                UUID id,
                String familyCode,
                DeviceClass deviceClass,
                List<String> modalityTags,
                String description,
                boolean requires3dReference,
                boolean requiresPhysicalPhantom,
                boolean iso13485Relevant
        ) {
            this.id = Objects.requireNonNull(id);
            this.familyCode = Objects.requireNonNull(familyCode);
            this.deviceClass = Objects.requireNonNull(deviceClass);
            this.modalityTags = List.copyOf(modalityTags);
            this.description = Objects.requireNonNull(description);
            this.requires3dReference = requires3dReference;
            this.requiresPhysicalPhantom = requiresPhysicalPhantom;
            this.iso13485Relevant = iso13485Relevant;
        }
    }

    public static final List<DeviceFamilyProfile> DEVICE_FAMILIES =
            List.of(
                    new DeviceFamilyProfile(
                            UUID.fromString("11111111-1111-4111-8111-111111111111"),
                            "MOCAP_OPTICAL",
                            DeviceClass.BODY_TRACKING,
                            List.of("optical", "marker_based"),
                            "Optical motion capture camera arrays for gait, AR/VR movement " +
                            "science, and neuromorphic exoskeleton labs.",
                            true,
                            true,
                            true
                    ),
                    new DeviceFamilyProfile(
                            UUID.fromString("22222222-2222-4222-8222-222222222222"),
                            "IMU_BODY",
                            DeviceClass.BODY_TRACKING,
                            List.of("imu", "wearable"),
                            "Body‑worn IMUs for sensor‑to‑segment tracking, anatomical " +
                            "calibration, and immersive AR rehabilitation.",
                            false,
                            false,
                            true
                    ),
                    new DeviceFamilyProfile(
                            UUID.fromString("33333333-3333-4333-8333-333333333333"),
                            "MULTIPLEX_BIOSENSE",
                            DeviceClass.BIOSENSING,
                            List.of("electrochemical", "optical", "multi_analyte"),
                            "Multiplexed biosensing platforms for multi‑analyte " +
                            "point‑of‑care testing and neuromorphic closed‑loop feedback.",
                            false,
                            false,
                            true
                    )
            );

    // ----------------------------------------------------------
    // 3. Body‑tracking calibration requirements (logistics)
    // ----------------------------------------------------------

    public static final class BodyTrackingCalibrationProfile {
        public final UUID id;
        public final String familyCode; // FK into DEVICE_FAMILIES
        public final String description;
        public final int minMarkersOrSensors;
        public final int maxMarkersOrSensors;
        public final boolean requiresFullBodySweep;
        public final boolean requiresQuietStance;
        public final double targetRmsErrorMm;
        public final double maxAllowedRmsErrorMm;
        public final double minCalibrationDurationSec;
        public final double maxCalibrationDurationSec;

        public BodyTrackingCalibrationProfile(
                UUID id,
                String familyCode,
                String description,
                int minMarkersOrSensors,
                int maxMarkersOrSensors,
                boolean requiresFullBodySweep,
                boolean requiresQuietStance,
                double targetRmsErrorMm,
                double maxAllowedRmsErrorMm,
                double minCalibrationDurationSec,
                double maxCalibrationDurationSec
        ) {
            this.id = Objects.requireNonNull(id);
            this.familyCode = Objects.requireNonNull(familyCode);
            this.description = Objects.requireNonNull(description);
            this.minMarkersOrSensors = minMarkersOrSensors;
            this.maxMarkersOrSensors = maxMarkersOrSensors;
            this.requiresFullBodySweep = requiresFullBodySweep;
            this.requiresQuietStance = requiresQuietStance;
            this.targetRmsErrorMm = targetRmsErrorMm;
            this.maxAllowedRmsErrorMm = maxAllowedRmsErrorMm;
            this.minCalibrationDurationSec = minCalibrationDurationSec;
            this.maxCalibrationDurationSec = maxCalibrationDurationSec;
        }
    }

    public static final List<BodyTrackingCalibrationProfile> BODYTRACK_CAL_PROFILES =
            List.of(
                    new BodyTrackingCalibrationProfile(
                            UUID.fromString("44444444-4444-4444-8444-444444444444"),
                            "MOCAP_OPTICAL",
                            "Optical motion‑capture volume calibration with wand grid, " +
                            "static reference, and AR alignment anchors.",
                            8,
                            64,
                            true,
                            true,
                            0.5,
                            CalibrationConstants.MAX_ALLOWED_CAL_DRIFT_MM,
                            30.0,
                            600.0
                    ),
                    new BodyTrackingCalibrationProfile(
                            UUID.fromString("55555555-5555-4555-8555-555555555555"),
                            "IMU_BODY",
                            "Anatomical calibration using quiet stance and standard " +
                            "movement tests, suitable for mixed AR/VR + IMU tracking.",
                            4,
                            32,
                            false,
                            true,
                            5.0,
                            10.0,
                            60.0,
                            900.0
                    )
            );

    // ----------------------------------------------------------
    // 4. Biosensing calibration requirements (multi‑analyte)
    // ----------------------------------------------------------

    public static final class BiosenseCalibrationProfile {
        public final UUID id;
        public final String familyCode; // FK into DEVICE_FAMILIES
        public final String description;
        public final int minAnalytes;
        public final int maxAnalytes;
        public final boolean requiresReferenceControls;
        public final boolean requiresTempCompensation;
        public final double targetBiasPct;
        public final double maxAllowedBiasPct;
        public final double targetCvPct;
        public final double maxAllowedCvPct;
        public final int maxIntervalDays;

        public BiosenseCalibrationProfile(
                UUID id,
                String familyCode,
                String description,
                int minAnalytes,
                int maxAnalytes,
                boolean requiresReferenceControls,
                boolean requiresTempCompensation,
                double targetBiasPct,
                double maxAllowedBiasPct,
                double targetCvPct,
                double maxAllowedCvPct,
                int maxIntervalDays
        ) {
            this.id = Objects.requireNonNull(id);
            this.familyCode = Objects.requireNonNull(familyCode);
            this.description = Objects.requireNonNull(description);
            this.minAnalytes = minAnalytes;
            this.maxAnalytes = maxAnalytes;
            this.requiresReferenceControls = requiresReferenceControls;
            this.requiresTempCompensation = requiresTempCompensation;
            this.targetBiasPct = targetBiasPct;
            this.maxAllowedBiasPct = maxAllowedBiasPct;
            this.targetCvPct = targetCvPct;
            this.maxAllowedCvPct = maxAllowedCvPct;
            this.maxIntervalDays = maxIntervalDays;
        }
    }

    public static final List<BiosenseCalibrationProfile> BIOSENSE_CAL_PROFILES =
            List.of(
                    new BiosenseCalibrationProfile(
                            UUID.fromString("66666666-6666-4666-8666-666666666666"),
                            "MULTIPLEX_BIOSENSE",
                            "Multi‑analyte biosensing calibration using traceable controls " +
                            "and temperature‑compensated curves for neuromorphic " +
                            "closed‑loop AR/VR feedback.",
                            2,
                            16,
                            true,
                            true,
                            3.0,
                            CalibrationConstants.MAX_ALLOWED_CAL_DRIFT_PCT,
                            5.0,
                            10.0,
                            CalibrationConstants.MAX_CAL_INTERVAL_DAYS
                    )
            );

    // ----------------------------------------------------------
    // 5. Calibration logistics for hospital / lab routing
    // ----------------------------------------------------------

    public enum FacilityType {
        HOSPITAL,
        LAB,
        REHAB
    }

    public static final class CalibrationLogisticsProfile {
        public final UUID id;
        public final FacilityType facilityType;
        public final String description;
        public final int minStaffTrained;
        public final boolean requiresDedicatedRoom;
        public final boolean requiresForcePlateOrPhantom;
        public final boolean requiresTraceableId;
        public final boolean requiresAuditLog;

        public CalibrationLogisticsProfile(
                UUID id,
                FacilityType facilityType,
                String description,
                int minStaffTrained,
                boolean requiresDedicatedRoom,
                boolean requiresForcePlateOrPhantom,
                boolean requiresTraceableId,
                boolean requiresAuditLog
        ) {
            this.id = Objects.requireNonNull(id);
            this.facilityType = Objects.requireNonNull(facilityType);
            this.description = Objects.requireNonNull(description);
            this.minStaffTrained = minStaffTrained;
            this.requiresDedicatedRoom = requiresDedicatedRoom;
            this.requiresForcePlateOrPhantom = requiresForcePlateOrPhantom;
            this.requiresTraceableId = requiresTraceableId;
            this.requiresAuditLog = requiresAuditLog;
        }
    }

    public static final List<CalibrationLogisticsProfile> CAL_LOGISTICS_PROFILES =
            List.of(
                    new CalibrationLogisticsProfile(
                            UUID.fromString("77777777-7777-4777-8777-777777777777"),
                            FacilityType.HOSPITAL,
                            "Hospital gait lab and scanner calibration logistics, including " +
                            "AR/VR neuromorphic movement therapy suites.",
                            2,
                            true,
                            true,
                            true,
                            true
                    ),
                    new CalibrationLogisticsProfile(
                            UUID.fromString("88888888-8888-4888-8888-888888888888"),
                            FacilityType.LAB,
                            "Research lab body‑tracking and biosensor calibration logistics " +
                            "for experimental AR/VR and REM-sleep environments.",
                            1,
                            false,
                            false,
                            true,
                            true
                    )
            );

    // ----------------------------------------------------------
    // 6. Behavior-like guards as pure predicates
    // ----------------------------------------------------------

    public static boolean opticalMocapWithinGuard(BodyTrackingCalibrationProfile p) {
        return "MOCAP_OPTICAL".equals(p.familyCode)
                && p.maxAllowedRmsErrorMm <= CalibrationConstants.MAX_ALLOWED_CAL_DRIFT_MM;
    }

    public static boolean biosenseBiasWithinGuard(BiosenseCalibrationProfile p) {
        return p.maxAllowedBiasPct <= CalibrationConstants.MAX_ALLOWED_CAL_DRIFT_PCT;
    }

    public static boolean logisticsTraceabilityGuard(CalibrationLogisticsProfile p) {
        return p.requiresTraceableId && p.requiresAuditLog;
    }

    // ----------------------------------------------------------
    // 7. Descriptor-only service surface (in-memory reference impl)
    // ----------------------------------------------------------

    public interface CalibrationDescriptorService {

        List<DeviceFamilyProfile> listDeviceFamilies();

        List<BodyTrackingCalibrationProfile> listBodytrackProfiles();

        List<BiosenseCalibrationProfile> listBiosenseProfiles();

        List<CalibrationLogisticsProfile> listLogisticsProfiles();
    }

    /**
     * Minimal immutable in-memory implementation, suitable as a default
     * configuration module in AR/VR and neuromorphic lab software.
     */
    public static final class InMemoryCalibrationDescriptorService
            implements CalibrationDescriptorService {

        @Override
        public List<DeviceFamilyProfile> listDeviceFamilies() {
            return DEVICE_FAMILIES;
        }

        @Override
        public List<BodyTrackingCalibrationProfile> listBodytrackProfiles() {
            return BODYTRACK_CAL_PROFILES;
        }

        @Override
        public List<BiosenseCalibrationProfile> listBiosenseProfiles() {
            return BIOSENSE_CAL_PROFILES;
        }

        @Override
        public List<CalibrationLogisticsProfile> listLogisticsProfiles() {
            return CAL_LOGISTICS_PROFILES;
        }
    }

    // ----------------------------------------------------------
    // 8. Optional: simple calibration record for traceability
    // ----------------------------------------------------------

    public static final class CalibrationRecord {
        public final UUID recordId;
        public final UUID equipmentId;
        public final LocalDate performedOn;
        public final String performedByRole;
        public final String profileFamilyCode;
        public final boolean passed;
        public final String notes; // no PHI

        public CalibrationRecord(
                UUID recordId,
                UUID equipmentId,
                LocalDate performedOn,
                String performedByRole,
                String profileFamilyCode,
                boolean passed,
                String notes
        ) {
            this.recordId = Objects.requireNonNull(recordId);
            this.equipmentId = Objects.requireNonNull(equipmentId);
            this.performedOn = Objects.requireNonNull(performedOn);
            this.performedByRole = Objects.requireNonNull(performedByRole);
            this.profileFamilyCode = Objects.requireNonNull(profileFamilyCode);
            this.passed = passed;
            this.notes = Objects.requireNonNullElse(notes, "");
        }
    }

    private MinimalBodyTrackBiosenseCalibrationV1() { }
}
