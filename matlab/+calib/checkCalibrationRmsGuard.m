function isOk = checkCalibrationRmsGuard(profile, measuredRmsMm)
%CHECKCALIBRATIONRMSGUARD Guard to ensure motion-capture RMS is within limit.
maxAllowed = profile.maxRmsMm;
isOk = measuredRmsMm <= maxAllowed;
end
