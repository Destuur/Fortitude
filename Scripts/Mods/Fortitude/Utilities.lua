--- Detects nearby bed quality and logs it.
--- Returns the normalized quality name and a numeric recovery factor (0–1).
---@param radius number|nil optional scan radius
---@return string quality, number factor
function Fortitude.DetectBedQuality(radius)
    local mod = Fortitude

    local pos = player:GetWorldPos() or player:GetPos()
    radius = radius or 7.0

    local quality = "ground"

    local bedTrigger = System.GetNearestEntityByClass(pos, radius, "BedTrigger")
    if bedTrigger then
        local linkedBed = bedTrigger:GetLinkedSmartObject()
        if linkedBed and linkedBed.Properties and linkedBed.Properties.Bed then
            quality = linkedBed.Properties.Bed.esSleepQuality or "unknown"
        end
    else
        local fallbackBed = System.GetNearestEntityByClass(pos, radius, "SmartObject")
        if fallbackBed and fallbackBed.Properties and fallbackBed.Properties.Bed then
            quality = fallbackBed.Properties.Bed.esSleepQuality or "ground"
        end
    end

    quality = string.lower(string.match(quality, "^%s*(.-)%s*$"))

    local qualityFactors = {
        ground      = 0.3,
        low         = 0.5,
        medium      = 0.7,
        good        = 0.9,
        high        = 1.0,
        exceptional = 1.0,
        unknown     = 0.4,
    }

    local factor = qualityFactors[quality] or 0.4

    mod.Logger:Info(string.format("[Sleep] 🛏️ Detected bed quality: '%s' (factor=%.2f)", quality, factor))

    return quality, factor
end
