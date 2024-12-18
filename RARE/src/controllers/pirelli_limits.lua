local sim = ac.getSim()

local round = math.round

local pirelliLimits = {}

local function setTyreCompoundsColor(driver, force)
	local driverCompound = driver.car.compoundIndex
	local compoundHardness = ""

	if tonumber(driver.tyreCompoundSoft) == driverCompound then
		compoundHardness = driver.tyreCompoundSoftTexture
	elseif tonumber(driver.tyreCompoundMedium) == driverCompound then
		compoundHardness = driver.tyreCompoundMediumTexture
	elseif tonumber(driver.tyreCompoundHard) == driverCompound then
		compoundHardness = driver.tyreCompoundHardTexture
	elseif tonumber(driver.tyreCompoundInter) == driverCompound then
		compoundHardness = driver.tyreCompoundInterTexture
	elseif tonumber(driver.tyreCompoundWet) == driverCompound then
		compoundHardness = driver.tyreCompoundWetTexture
	end

	if compoundHardness == "" or compoundHardness == nil then
		return
	end

	local compoundTexture = driver.extensionDir .. compoundHardness .. ".dds"
	local compoundBlurTexture = driver.extensionDir .. compoundHardness .. "_Blur.dds"

	driver.tyreCompoundNode:setMaterialTexture("txDiffuse", compoundTexture)
	driver.tyreCompoundNode:setMaterialTexture("txBlur", compoundBlurTexture)
end

local previousIndex = 0
local function restrictCompoundChoice(driver)
	if RARE_CONFIG.data.RULES.LIMIT_TYRE_COMPOUNDS ~= 1 then
		return
	end

	local compoundIndex = driver.car.compoundIndex
	local isIndexIncreasing = compoundIndex > previousIndex and true or false
	local validTyreCompoundIndex = table.containsValue(driver.tyreCompoundsAvailable, compoundIndex)

	if not validTyreCompoundIndex then
		local nextValidTyreCompound = math.clamp(
			tonumber(compoundIndex + (isIndexIncreasing and 1 or -1)),
			tonumber(driver.tyreCompoundsAvailable[1]),
			tonumber(driver.tyreCompoundsAvailable[#driver.tyreCompoundsAvailable])
		)
		ac.setSetupSpinnerValue("COMPOUND", nextValidTyreCompound)
	end

	previousIndex = compoundIndex
end

local wheelPostfix = {
	[0] = "LF",
	[1] = "RF",
	[2] = "LR",
	[3] = "RR",
}

local eosCamber = { [0] = 0, [1] = 0, [2] = 0, [3] = 0 }

local infringed = false
local function restrictEOSCamber(driver)
	if RARE_CONFIG.data.RULES.LIMIT_EOS_CAMBER ~= 1 then
		return
	end

	for i = 0, 1 do
		if driver.car.speedKmh >= 280 and math.abs(driver.car.steer) < 1.5 then
			if driver.car.wheels[i].camber < eosCamber[i] then
				eosCamber[i] = math.applyLag(eosCamber[i], driver.car.wheels[i].camber, 0.98, ac.getScriptDeltaT())
			end
		elseif driver.eosCamberLimitFront <= eosCamber[i] then
			eosCamber[i] = 0
		end
	end

	for i = 2, 3 do
		if driver.car.speedKmh >= 280 and math.abs(driver.car.steer) < 1.5 then
			if driver.car.wheels[i].camber < eosCamber[i] then
				eosCamber[i] = math.applyLag(eosCamber[i], driver.car.wheels[i].camber, 0.98, ac.getScriptDeltaT())
			end
		elseif driver.eosCamberLimitRear <= eosCamber[i] then
			eosCamber[i] = 0
		end
	end

	local infringementString = ""
	for i = 0, 1 do
		if eosCamber[i] < driver.eosCamberLimitFront then
			infringed = true
			infringementString = infringementString
				.. "CAMBER "
				.. wheelPostfix[i]
				.. ": "
				.. math.round(eosCamber[i], 3)
				.. " < "
				.. driver.eosCamberLimitFront

			if i ~= 3 then
				infringementString = infringementString .. "	"
			end
		end
	end

	for i = 2, 3 do
		if eosCamber[i] < driver.eosCamberLimitRear then
			infringed = true
			infringementString = infringementString
				.. "CAMBER "
				.. wheelPostfix[i]
				.. ": "
				.. math.round(eosCamber[i], 3)
				.. " < "
				.. driver.eosCamberLimitRear

			if i ~= 3 then
				infringementString = infringementString .. "	"
			end
		end
	end

	if infringed then
		ac.setSystemMessage("EOS Camber Limits Infringed", infringementString)
	end
end

local delay = 0
local menuDelay = false
local function restrictStartingTyrePressure(driver)
	if RARE_CONFIG.data.RULES.LIMIT_TYRE_START_PRESSURE ~= 1 then
		return
	end

	local tyreMinimumStartingPressureFront = driver.tyreSlicksMinimumStartingPressureFront
	local tyreMinimumStartingPressureRear = driver.tyreSlicksMinimumStartingPressureRear

	if driver.car.compoundIndex == tonumber(driver.tyreCompoundInter) then
		tyreMinimumStartingPressureFront = driver.tyreIntersMinimumStartingPressureFront
		tyreMinimumStartingPressureRear = driver.tyreIntersMinimumStartingPressureRear
	elseif driver.car.compoundIndex == tonumber(driver.tyreCompoundWet) then
		tyreMinimumStartingPressureFront = driver.tyreWetsMinimumStartingPressureFront
		tyreMinimumStartingPressureRear = driver.tyreWetsMinimumStartingPressureRear
	end

	if menuDelay then
		delay = os.clock() + 1
		menuDelay = false
	end

	if delay > os.clock() then
		return
	end

	for i = 0, 1 do
		if
			driver.car.wheels[i].tyreWear > 0.000001
			and driver.car.wheels[i].tyrePressure < tyreMinimumStartingPressureFront
		then
			ac.setSetupSpinnerValue("PRESSURE_" .. wheelPostfix[i], driver.car.wheels[i].tyreStaticPressure + 1)
		end
	end

	for i = 2, 3 do
		if
			driver.car.wheels[i].tyreWear > 0.000001
			and driver.car.wheels[i].tyrePressure < tyreMinimumStartingPressureRear
		then
			ac.setSetupSpinnerValue("PRESSURE_" .. wheelPostfix[i], driver.car.wheels[i].tyreStaticPressure + 1)
		end
	end
end

local delay = 0
local menuDelay = false
local function restrictStaticCamber(driver)
	if RARE_CONFIG.data.RULES.LIMIT_STATIC_CAMBER ~= 1 then
		return
	end

	local camberMinimumFront = round(driver.camberLimitFront * 10)
	local camberMinimumRear = round(driver.camberLimitRear * 10)

	if menuDelay then
		delay = os.clock() + 1
		menuDelay = false
	end

	if delay > os.clock() then
		return
	end

	for i = 0, 1 do
		local camber = ac.getSetupSpinnerValue("CAMBER_" .. wheelPostfix[i])

		if driver.car.wheels[i].tyreWear > 0.000001 and camber < camberMinimumFront then
			ac.setSetupSpinnerValue("CAMBER_" .. wheelPostfix[i], camber + 1)
		end
	end

	for i = 2, 3 do
		local camber = ac.getSetupSpinnerValue("CAMBER_" .. wheelPostfix[i])

		if driver.car.wheels[i].tyreWear > 0.000001 and camber < camberMinimumRear then
			ac.setSetupSpinnerValue("CAMBER_" .. wheelPostfix[i], camber + 1)
		end
	end
end

function pirelliLimits.update()
	for i = 0, #DRIVERS do
		local driver = DRIVERS[i]

		if
			driver.car.isInPit
			or (
				sim.isInMainMenu
				and (sim.raceSessionType == ac.SessionType.Race or ac.getSessionSpawnSet(0) == ac.SpawnSet.HotlapStart)
			)
		then
			setTyreCompoundsColor(driver, false)
		end

		if i ~= 0 then
			return
		end

		if sim.isInMainMenu then
			local tyreBlanketTemp = driver.tyreSlicksTyreBlanketTemp
			local setTyreBlankets = true
			if driver.car.compoundIndex == tonumber(driver.tyreCompoundInter) then
				tyreBlanketTemp = driver.tyreIntsTyreBlanketTemp
			elseif driver.car.compoundIndex == tonumber(driver.tyreCompoundWet) then
				tyreBlanketTemp = driver.tyreWetsTyreBlanketTemp
			end

			if tyreBlanketTemp <= sim.ambientTemperature then
				setTyreBlankets = false
			end

			for i = 0, 3 do
				eosCamber[i] = 0
			end

			if setTyreBlankets then
				physics.setTyresTemperature(
					driver.car.index,
					ac.Wheel.All,
					math.max(tyreBlanketTemp, sim.ambientTemperature)
				)
			end

			infringed = false

			restrictCompoundChoice(driver)
			restrictStartingTyrePressure(driver)
			restrictStaticCamber(driver)
		else
			restrictEOSCamber(driver)
			menuDelay = true
		end
	end
end

return pirelliLimits
