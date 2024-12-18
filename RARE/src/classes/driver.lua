local sim = ac.getSim()

Driver = class("Driver")
function Driver:initialize(carIndex)
	self.car = ac.getCar(carIndex)

	if sim.isOnlineRace then
		self.index = self.car.sessionID
	else
		self.index = carIndex
	end

	self.name = ac.getDriverName(self.index)

	self.aiThrottleLimitBase = math.lerp(0.5, 1, 1 - ((1 - self.car.aiLevel) / 0.3))
	self.aiThrottleLimit = 1
	self.aiLevel = self.car.aiLevel
	self.aiLevelRelative = self:setAIRelativeLevel()
	self.aiAggression = self.car.aiAggression

	self.aiPrePitFuel = 0
	self.isAIPitCall = false
	self.isAIPitting = false
	self.aiSplineOffset = 0
	self.isAIMoveAside = false
	self.isAISpeedUp = false
	self.aiMgukDelivery = 0
	self.aiMgukRecovery = 0
	self.aiBrakeHint = 1
	self.aiGasBrakeLookAhead = 0
	self.aiCaution = 1
	self.aiInitialCompoundApplied = false
	self.aiPitFix = false

	self.isOnOutlap = false
	self.isOnFlyingLap = false
	self.isOnInLap = false
	self.inLap = 0

	self.pitstopCount = 0
	self.pitstopTime = 0
	self.pitlane = false
	self.pitlaneTime = 0
	self.isPitStopComplete = false
	self.hasPitted = false
	self.lapPitted = 0
	self.pittedLaps = {}
	self.tyreLaps = 0
	self.tyreCompoundStart = self.car.compoundIndex
	self.tyreCompoundNext = self.car.compoundIndex
	self.hasChangedTyreCompound = false
	self.tyreStints = {}

	self.extensionDir = ac.getFolder(ac.FolderID.ContentCars) .. "/" .. ac.getCarID(self.index) .. "/extension/"

	self.tyreCompoundTextureTimer = 0
	self.tyreCompoundTextureIndex = self.car.compoundIndex

	self.fuelCons = ac.INIConfig.carData(self.index, "fuel_cons.ini"):get("FUEL_EVAL", "KM_PER_LITER", 0.0)

	self.eosCamberLimitFront = -5
	self.eosCamberLimitRear = -5

	self.camberLimitFront = -50
	self.camberLimitRear = -50

	self.tyreSlicksMinimumStartingPressureFront = 22
	self.tyreSlicksMinimumStartingPressureRear = 20

	self.tyreIntersMinimumStartingPressureFront = 23
	self.tyreIntersMinimumStartingPressureRear = 21

	self.tyreWetsMinimumStartingPressureFront = 20
	self.tyreWetsMinimumStartingPressureRear = 18

	self.tyreSlicksTyreBlanketTemp = 70
	self.tyreIntsTyreBlanketTemp = 60
	self.tyreWetsTyreBlanketTemp = 40

	self.trackPosition = -1
	self.carAhead = -1
	self.carAheadDelta = -1
	self.miniSectors = {}
	self.currentMiniSector = 0
	self.lapsCompleted = self.car.lapCount

	self.isInDrsActivationZone = self.car.drsAvailable
	self.drsZoneNextId = 0
	self.drsZoneId = 1
	self.drsZonePrevId = 0
	self.isDrsAvailable = false
	self.drsDetection = {}

	self.drsBeepFx = false
	self.drsFlapFx = false

	self.timePenalty = 0
	self.returnRacePosition = -1
	self.returnPostionTimer = -1

	self:updatePirelliLimitsConfig()
	self:updateAITyreLife()
	self:updateTyreCompoundConfig()

	self.tyreCompoundNode = ac.findNodes("carRoot:" .. self.index)
		:findMeshes("material:" .. self.tyreCompoundMaterialTarget)

	for i = 0, #DRS_ZONES.startLines do
		self.drsDetection[i] = false
	end

	for i = 0, math.floor(sim.trackLengthM / 50) do
		self.miniSectors[i] = 0
	end

	if self.car.isAIControlled then
		self:setAITyreCompound()
	end

	self.aiLevel = self.car.aiLevel
	self.aiGasBrakeLookAheadBase =
		ac.INIConfig.carData(self.index, "ai.ini"):get("LOOKAHEAD", "GAS_BRAKE_LOOKAHEAD", 10)
	self.aiBrakeHintBase = ac.INIConfig.carData(self.index, "ai.ini"):get("PEDALS", "BRAKE_HINT", 1)
	self.aiThrottleLimitBase = math.lerp(0.5, 1, 1 - ((1 - self.aiLevel) / 0.3))
	self.aiAggression = self.car.aiAggression

	if RARE_CONFIG.data.AI.RELATIVE_SCALING == 1 then
		self.aiLevel = self.aiLevel * RARE_CONFIG.data.AI.RELATIVE_LEVEL / 100
		self.aiThrottleLimitBase = math.lerp(0.5, 1, 1 - ((1 - self.aiLevel) / 0.3))
	end

	physics.setAILevel(self.index, 1)
	physics.setAIAggression(self.index, self.aiAggression)

	log("[" .. self.index .. "] " .. self.name .. " initialized")

	return self
end

function Driver:updateAITyreLife()
	local carID = ac.getCarID(self.index)
	local compoundsINI = ac.INIConfig.load(
		ac.getFolder(ac.FolderID.ACApps) .. "/lua/RARE/configs/" .. carID .. ".ini",
		ac.INIFormat.Default
	)

	self.aiTyreLifeAvgRange = compoundsINI:get("AI", "AVG_TYRE_LIFE_RANGE", 5)
	self.aiTyreLifeAvg = compoundsINI:get("AI", "AVG_TYRE_LIFE", 62)
	self.aiTyrePitBelowAvg = self.aiTyreLifeAvg + math.randomizer(self.index, self.aiTyreLifeAvgRange)
	self.aiTyreLifeSingleRange = compoundsINI:get("AI", "SINGLE_TYRE_LIFE_RANGE", 5)
	self.aiTyreLifeSingle = compoundsINI:get("AI", "SINGLE_TYRE_LIFE", 45)
	self.aiTyrePitBelowSingle = self.aiTyreLifeSingle + math.randomizer(self.index, self.aiTyreLifeSingleRange)
end

local function getLapPitted(driver)
	return (driver.tyreLaps > 0 and driver.car.isInPitlane) and driver.car.lapCount or driver.lapPitted
end

local function getTyreLapCount(driver)
	return (driver.car.isInPitlane and not driver.hasPitted) and driver.tyreLaps
		or (driver.car.lapCount - driver.lapPitted)
end

local function updatePistopCount(driver)
	if driver.car.isInPit and not driver.hasPitted then
		driver.hasPitted = true
		driver.aiTyrePitBelowAvg = driver.aiTyreLifeAvg + math.randomizer(driver.index, driver.aiTyreLifeAvgRange)
		driver.aiTyrePitBelowSingle = driver.aiTyreLifeSingle
			+ math.randomizer(driver.index, driver.aiTyreLifeSingleRange)
		return driver.pitstopCount + 1
	elseif not driver.car.isInPitlane and driver.hasPitted then
		driver.hasPitted = false
	end

	return driver.pitstopCount
end

local function getPitTime(dt, driver)
	if driver.car.isInPitlane then
		if driver.pitlaneTime > 0 and not driver.pitlane then
			driver.pitlane = true
			return 0
		else
			return driver.pitlaneTime + dt
		end
	else
		driver.pitlane = false
		return driver.pitlaneTime
	end
end

local function getPitstopTime(dt, driver)
	if driver.car.isInPit then
		if not driver.isPitStopComplete then
			driver.isPitStopComplete = true
			return 0
		else
			return driver.pitstopTime + dt
		end
	else
		driver.isPitStopComplete = false
		return driver.pitstopTime
	end
end

local function getMiniSectorGap(driver, carAheadIndex)
	return driver.miniSectors[driver.currentMiniSector] - DRIVERS[carAheadIndex].miniSectors[driver.currentMiniSector]
end

function Driver:updatePirelliLimitsConfig()
	local trackID = ac.getTrackID()
	local carID = ac.getCarID(self.index)
	local compoundsINI = ac.INIConfig.load(
		ac.getFolder(ac.FolderID.ACApps) .. "/lua/RARE/configs/" .. carID .. ".ini",
		ac.INIFormat.Default
	)

	self.eosCamberLimitFront = compoundsINI:get(trackID, "EOS_CAMBER_LIMIT_FRONT", -3.25)
	self.eosCamberLimitRear = compoundsINI:get(trackID, "EOS_CAMBER_LIMIT_REAR", -2)

	self.camberLimitFront = compoundsINI:get(trackID, "STATIC_CAMBER_LIMIT_FRONT", -2)
	self.camberLimitRear = compoundsINI:get(trackID, "STATIC_CAMBER_LIMIT_REAR", -2)

	self.tyreSlicksMinimumStartingPressureFront = compoundsINI:get(trackID, "SLICKS_MIN_HOT_START_PSI_FRONT", 22)
	self.tyreSlicksMinimumStartingPressureRear = compoundsINI:get(trackID, "SLICKS_MIN_HOT_START_PSI_REAR", 20)
	self.tyreIntersMinimumStartingPressureFront = compoundsINI:get(trackID, "INTERS_MIN_HOT_START_PSI_FRONT", 23)
	self.tyreIntersMinimumStartingPressureRear = compoundsINI:get(trackID, "INTERS_MIN_HOT_START_PSI_REAR", 21)
	self.tyreWetsMinimumStartingPressureFront = compoundsINI:get(trackID, "WETS_MIN_HOT_START_PSI_FRONT", 20)
	self.tyreWetsMinimumStartingPressureRear = compoundsINI:get(trackID, "WETS_MIN_HOT_START_PSI_REAR", 18)
	self.tyreSlicksTyreBlanketTemp = compoundsINI:get(trackID, "SLICKS_TYRE_BLANKET_TEMP", 70)
	self.tyreIntsTyreBlanketTemp = compoundsINI:get(trackID, "INTERS_TYRE_BLANKET_TEMP", 60)
	self.tyreWetsTyreBlanketTemp = compoundsINI:get(trackID, "WETS_TYRE_BLANKET_TEMP", 40)
end

function Driver:updateTyreCompoundConfig()
	local trackID = ac.getTrackID()
	local carID = ac.getCarID(self.index)
	local compoundsINI = ac.INIConfig.load(
		ac.getFolder(ac.FolderID.ACApps) .. "/lua/RARE/configs/" .. carID .. ".ini",
		ac.INIFormat.Default
	)

	self.tyreCompoundMaterialTarget = compoundsINI:get("COMPOUND_TEXTURES", "COMPOUND_TARGET_MATERIAL", "")
	self.tyreCompoundSoftTexture =
		compoundsINI:get("COMPOUND_TEXTURES", "SOFT_COMPOUND_TEXTURE", ""):gsub('"', ""):gsub("'", "")
	self.tyreCompoundMediumTexture =
		compoundsINI:get("COMPOUND_TEXTURES", "MEDIUM_COMPOUND_TEXTURE", ""):gsub('"', ""):gsub("'", "")
	self.tyreCompoundHardTexture =
		compoundsINI:get("COMPOUND_TEXTURES", "HARD_COMPOUND_TEXTURE", ""):gsub('"', ""):gsub("'", "")
	self.tyreCompoundInterTexture =
		compoundsINI:get("COMPOUND_TEXTURES", "INTER_COMPOUND_TEXTURE", ""):gsub('"', ""):gsub("'", "")
	self.tyreCompoundWetTexture =
		compoundsINI:get("COMPOUND_TEXTURES", "WET_COMPOUND_TEXTURE", ""):gsub('"', ""):gsub("'", "")

	self.tyreCompoundSoft = compoundsINI:get(trackID, "SOFT_COMPOUND", ""):gsub('"', ""):gsub("'", "") ~= ""
			and compoundsINI:get(trackID, "SOFT_COMPOUND", ""):gsub('"', ""):gsub("'", "")
		or compoundsINI:get("COMPOUND_DEFAULTS", "SOFT_COMPOUND", "1"):gsub('"', ""):gsub("'", "")
	self.tyreCompoundMedium = compoundsINI:get(trackID, "MEDIUM_COMPOUND", ""):gsub('"', ""):gsub("'", "") ~= ""
			and compoundsINI:get(trackID, "MEDIUM_COMPOUND", ""):gsub('"', ""):gsub("'", "")
		or compoundsINI:get("COMPOUND_DEFAULTS", "MEDIUM_COMPOUND", "2"):gsub('"', ""):gsub("'", "")
	self.tyreCompoundHard = compoundsINI:get(trackID, "HARD_COMPOUND", ""):gsub('"', ""):gsub("'", "") ~= ""
			and compoundsINI:get(trackID, "HARD_COMPOUND", ""):gsub('"', ""):gsub("'", "")
		or compoundsINI:get("COMPOUND_DEFAULTS", "HARD_COMPOUND", "3"):gsub('"', ""):gsub("'", "")
	self.tyreCompoundInter = compoundsINI:get("COMPOUND_DEFAULTS", "INTER_COMPOUND", "5"):gsub('"', ""):gsub("'", "")
	self.tyreCompoundWet = compoundsINI:get("COMPOUND_DEFAULTS", "WET_COMPOUND", "6"):gsub('"', ""):gsub("'", "")

	self.tyreCompoundsAvailable = {
		tonumber(self.tyreCompoundSoft),
		tonumber(self.tyreCompoundMedium),
		tonumber(self.tyreCompoundHard),
		tonumber(self.tyreCompoundInter),
		tonumber(self.tyreCompoundWet),
	}

	self.tyreDryCompounds = {
		self.tyreCompoundSoft,
		self.tyreCompoundMedium,
		self.tyreCompoundHard,
	}

	self.tyreWetCompounds = {
		self.tyreCompoundInter,
		self.tyreCompoundWet,
	}

	self.tyreCompoundNode = ac.findNodes("carRoot:" .. self.index)
		:findMeshes("material:" .. self.tyreCompoundMaterialTarget)

	table.sort(self.tyreCompoundsAvailable, function(a, b)
		return a < b
	end)

	log("[" .. self.index .. "] " .. self.name .. " has " .. #self.tyreCompoundsAvailable .. " compounds available")
end

function Driver:setFuelTankRace()
	local fuelload = 0
	local fuelPerLap = (sim.trackLengthM / 1000) / (self.fuelCons - (self.fuelCons * 0.1))

	if sim.raceSessionType == ac.SessionType.Race then
		fuelload = ((ac.getSession(sim.currentSessionIndex).laps + 2) * fuelPerLap)
	end

	if self.car.isAIControlled then
		if RARE_CONFIG.data.AI.TANK_FILL == 1 then
			physics.setCarFuel(self.index, fuelload)
		end
	elseif not sim.isOnlineRace then
		if RARE_CONFIG.data.DRIVER.TANK_FILL == 1 then
			ac.setSetupSpinnerValue("FUEL", fuelload)
		end
	end
end

function Driver:setFuelTankQuali()
	local fuelload = 0
	local fuelPerLap = (sim.trackLengthM / 1000) / (self.fuelCons - (self.fuelCons * 0.1))

	fuelload = 3.5 * fuelPerLap

	if self.car.isAIControlled then
		if RARE_CONFIG.data.AI.TANK_FILL == 1 then
			physics.setCarFuel(self.index, fuelload)
		end
	elseif not sim.isOnlineRace then
		if RARE_CONFIG.data.DRIVER.TANK_FILL == 1 then
			ac.setSetupSpinnerValue("FUEL", fuelload)
		end
	end
end

function Driver:setAITyreCompound(compoundIndex)
	local tyrevalue = 0

	if compoundIndex then
		tyrevalue = compoundIndex
	else
		math.randomseed(os.clock() * self.index)
		math.random()
		for i = 0, math.random(0, math.random(3)) do
			math.random()
		end
		tyrevalue = self.tyreDryCompounds[math.random(1, #self.tyreDryCompounds)]
		self.tyreCompoundStart = tyrevalue
	end

	if ac.getPatchVersionCode() >= 2278 then
		physics.setAITyres(self.index, tyrevalue)
		log("[" .. self.index .. "] " .. self.name .. " tyre compound set to " .. tyrevalue)
	end
end

function Driver:setAIRelativeLevel()
	self.aiLevelRelative = self.aiLevel * RARE_CONFIG.data.AI.RELATIVE_LEVEL / 100
	self.aiThrottleLimitBase = math.lerp(0.5, 1, 1 - ((1 - self.aiLevelRelative) / 0.3))
end

function Driver:update(dt)
	self.lapPitted = getLapPitted(self)
	self.tyreLaps = getTyreLapCount(self)
	self.pitstopCount = updatePistopCount(self)
	self.pitlaneTime = getPitTime(dt, self)
	self.pitstopTime = getPitstopTime(dt, self)

	if not self.car.isInPit and self.car.fuel > 1 then
		self.aiPrePitFuel = self.car.fuel
	end

	if self.currentMiniSector ~= math.floor((self.car.splinePosition * sim.trackLengthM) / 50) then
		self.currentMiniSector = math.floor((self.car.splinePosition * sim.trackLengthM) / 50)
		self.miniSectors[self.currentMiniSector] = os.clock()
	end

	if self.carAhead >= 0 then
		self.carAheadDelta = getMiniSectorGap(self, self.carAhead) or ac.getDelta(sim, self.index, self.carAhead)
	end

	if not sim.isSessionStarted and not self.aiInitialCompoundApplied then
		self:setAITyreCompound()
		self.aiInitialCompoundApplied = true
	elseif sim.isSessionStarted and self.aiInitialCompoundApplied then
		self.aiInitialCompoundApplied = false
	end
end
