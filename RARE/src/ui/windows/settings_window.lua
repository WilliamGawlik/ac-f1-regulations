local sim = ac.getSim()

local controls = require("src/ui/controls/slider")
local inject = require("src/controllers/injection")
local notifications = require("src/ui/windows/notification_window")
local injected = physics.allowed()

local presetNames = {
	"FORMULA 1",
	"FORMULA 2",
	"GT",
}

local presets = {
	["FORMULA 1"] = {
		DRS_RULES = 1,
		DRS_ACTIVATION_LAP = 2,
		DRS_GAP_DELTA = 1000,
		DRS_WET_DISABLE = 1,
		RACE_REFUELING = 0,
		LIMIT_TYRE_COMPOUNDS = 1,
		LIMIT_TYRE_START_PRESSURE = 1,
		LIMIT_EOS_CAMBER = 1,
		LIMIT_STATIC_CAMBER = 0,
	},
	["FORMULA 2"] = {
		DRS_RULES = 1,
		DRS_ACTIVATION_LAP = 2,
		DRS_GAP_DELTA = 1000,
		DRS_WET_DISABLE = 1,
		RACE_REFUELING = 0,
		LIMIT_TYRE_COMPOUNDS = 1,
		LIMIT_TYRE_START_PRESSURE = 1,
		LIMIT_EOS_CAMBER = 0,
		LIMIT_STATIC_CAMBER = 1,
	},
	["GT"] = {
		DRS_RULES = 0,
		DRS_ACTIVATION_LAP = 0,
		DRS_GAP_DELTA = 0,
		DRS_WET_DISABLE = 0,
		RACE_REFUELING = 1,
		LIMIT_TYRE_COMPOUNDS = 0,
		LIMIT_TYRE_START_PRESSURE = 0,
		LIMIT_EOS_CAMBER = 0,
		LIMIT_STATIC_CAMBER = 0,
	},
}

function table.match(a, b)
	local match = true

	for k, v in pairs(a) do
		if v == b[k] then
		else
			match = false
		end
	end

	return match
end

local function setRareConfigPreset(preset)
	for k, v in pairs(presets[preset]) do
		RARE_CONFIG:set("RULES", k, v, false)
	end
end

local selectedPreset = "CUSTOM"

local function rulesTab()
	ui.tabItem("RULES", ui.TabItemFlags.None, function()
		ui.newLine(1)

		selectedPreset = "CUSTOM"
		for preset in pairs(presets) do
			if table.match(presets[preset], RARE_CONFIG.data.RULES) then
				selectedPreset = preset
			end
		end

		ui.header("RACE SERIES PRESETS")
		ui.setNextItemWidth(ui.windowWidth() - 75)
		local changed = false
		ui.combo("##presetNames", selectedPreset, ui.ComboFlags.None, function()
			for i = 1, #presetNames do
				if ui.selectable(presetNames[i]) then
					selectedPreset, changed = presetNames[i], true
				end
			end
		end)

		if changed then
			setRareConfigPreset(selectedPreset)
		end

		ui.newLine(1)

		ui.header("RACING RULES")
		controls.slider(
			RARE_CONFIG,
			"RULES",
			"DRS_RULES",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.RULES.DRS_RULES == 1 and "DRS Rules: ENABLED" or "DRS Rules: DISABLED",
			"Enable DRS being controlled by the app",
			function(v)
				return math.round(v, 0)
			end
		)

		if RARE_CONFIG.data.RULES.DRS_RULES == 1 then
			DRS_ENABLED_LAP = controls.slider(
				RARE_CONFIG,
				"RULES",
				"DRS_ACTIVATION_LAP",
				1,
				5,
				1,
				false,
				"Activation Lap: %.0f",
				"First lap to allow DRS activation",
				function(v)
					return v
				end
			)
			controls.slider(
				RARE_CONFIG,
				"RULES",
				"DRS_GAP_DELTA",
				100,
				2000,
				1,
				false,
				"Gap Delta: %.0f ms",
				"Max gap to car ahead when crossing detection line to allow DRS for the next zone",
				function(v)
					return math.floor(v / 50 + 0.5) * 50
				end
			)

			controls.slider(
				RARE_CONFIG,
				"RULES",
				"DRS_WET_DISABLE",
				0,
				1,
				1,
				true,
				RARE_CONFIG.data.RULES.DRS_WET_DISABLE == 1 and "Disable DRS When Wet: ENABLED"
					or "Disable DRS When Wet: DISABLED",
				"Disable DRS activation if track wetness gets above the limit below",
				function(v)
					return math.round(v, 0)
				end
			)
			ui.newLine(1)

			controls.slider(
				RARE_CONFIG,
				"RULES",
				"RACE_REFUELING",
				0,
				1,
				1,
				true,
				RARE_CONFIG.data.RULES.RACE_REFUELING == 1 and "Race Refueling: ENABLED" or "Race Refueling: DISABLED",
				"Enable or disable refueling during a race",
				function(v)
					return math.round(v, 0)
				end
			)
		end
		ui.newLine(1)

		ui.header("SETUP LIMITS")

		controls.slider(
			RARE_CONFIG,
			"RULES",
			"LIMIT_TYRE_COMPOUNDS",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.RULES.LIMIT_TYRE_COMPOUNDS == 1 and "Tyre Compounds: RESTRICTED" or "Tyre Compounds: FREE",
			"Enable or disable restricting compound choice, starting pressures, and EOS camber limits\nRequires configration in the 'config' tab in order to work",
			function(v)
				return math.round(v, 0)
			end
		)
		controls.slider(
			RARE_CONFIG,
			"RULES",
			"LIMIT_TYRE_START_PRESSURE",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.RULES.LIMIT_TYRE_START_PRESSURE == 1 and "Tyre Starting Pressures: RESTRICTED"
				or "Tyre Starting Pressures: FREE",
			"Enable or disable restricting compound choice, starting pressures, and EOS camber limits\nRequires configration in the 'config' tab in order to work",
			function(v)
				return math.round(v, 0)
			end
		)
		controls.slider(
			RARE_CONFIG,
			"RULES",
			"LIMIT_EOS_CAMBER",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.RULES.LIMIT_EOS_CAMBER == 1 and "EOS Camber: RESTRICTED" or "EOS Camber: FREE",
			"Enable or disable restricting compound choice, starting pressures, and EOS camber limits\nRequires configration in the 'config' tab in order to work",
			function(v)
				return math.round(v, 0)
			end
		)
		controls.slider(
			RARE_CONFIG,
			"RULES",
			"LIMIT_STATIC_CAMBER",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.RULES.LIMIT_STATIC_CAMBER == 1 and "Static Camber: RESTRICTED" or "Static Camber: FREE",
			"Enable or disable restricting compound choice, starting pressures, and EOS camber limits\nRequires configration in the 'config' tab in order to work",
			function(v)
				return math.round(v, 0)
			end
		)

		ui.newLine(1)
	end)
end

local compoundConfigDir = ac.dirname() .. "\\configs"
local uniqueCarIDs = {}

for i = 0, sim.carsCount - 1 do
	local carID = ac.getCarID(i)
	if not table.contains(uniqueCarIDs, carID) then
		table.insert(uniqueCarIDs, carID)
	end
end

local selectedCarID = uniqueCarIDs[1]
local selectedCarIDConfigFile, selectedCarConfigINI, selectedCarConfig, selectedCarExtConfigINI

local function updateCarConfig()
	selectedCarIDConfigFile = compoundConfigDir .. "\\" .. selectedCarID .. ".ini"
	selectedCarConfigINI = ac.INIConfig.load(selectedCarIDConfigFile, ac.INIFormat.Default)
	selectedCarExtConfigINI = ac.INIConfig.load(
		ac.getFolder(ac.FolderID.ContentCars) .. "/" .. ac.getCarID(0) .. "/extension/ext_config.ini",
		ac.INIFormat.ExtendedIncludes
	)
	selectedCarConfig = MappedConfig(selectedCarIDConfigFile, {
		COMPOUND_DEFAULTS = {
			SOFT_COMPOUND = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			MEDIUM_COMPOUND = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			HARD_COMPOUND = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			INTER_COMPOUND = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			WET_COMPOUND = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
		},
		COMPOUND_TEXTURES = {
			COMPOUND_TARGET_MATERIAL = (ac.INIConfig.OptionalString == nil) and ac.INIConfig.OptionalString or "",
			SOFT_COMPOUND_TEXTURE = (ac.INIConfig.OptionalString == nil) and ac.INIConfig.OptionalString or "",
			MEDIUM_COMPOUND_TEXTURE = (ac.INIConfig.OptionalString == nil) and ac.INIConfig.OptionalString or "",
			HARD_COMPOUND_TEXTURE = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or "",
			INTER_COMPOUND_TEXTURE = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or "",
			WET_COMPOUND_TEXTURE = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or "",
		},
	})
end

updateCarConfig()

if not io.fileExists(selectedCarIDConfigFile) then
	io.save(
		selectedCarIDConfigFile,
		[[
[AI]
AVG_TYRE_LIFE=62
AVG_TYRE_LIFE_RANGE=5
SINGLE_TYRE_LIFE=45
SINGLE_TYRE_LIFE_RANGE=5

[COMPOUND_DEFAULTS]
SOFT_COMPOUND=1
MEDIUM_COMPOUND=2
HARD_COMPOUND=3
INTER_COMPOUND=5
WET_COMPOUND=6

[COMPOUND_TEXTURES]
COMPOUND_TARGET_MATERIAL=
SOFT_COMPOUND_TEXTURE=
MEDIUM_COMPOUND_TEXTURE=
HARD_COMPOUND_TEXTURE=
INTER_COMPOUND_TEXTURE=
WET_COMPOUND_TEXTURE=
]]
	)
end

local aiKeys = {
	"AVG_TYRE_LIFE",
	"AVG_TYRE_LIFE_RANGE",
	"SINGLE_TYRE_LIFE",
	"SINGLE_TYRE_LIFE_RANGE",
}

local trackCompoundKeys = {
	"SOFT_COMPOUND",
	"MEDIUM_COMPOUND",
	"HARD_COMPOUND",
}

local trackCamberKeys = {
	"EOS_CAMBER_LIMIT_FRONT",
	"EOS_CAMBER_LIMIT_FRONT",
	"STATIC_CAMBER_LIMIT_FRONT",
	"STATIC_CAMBER_LIMIT_REAR",
}

local trackMinStartingPressureKeys = {
	"SLICKS_MIN_HOT_START_PSI_FRONT",
	"SLICKS_MIN_HOT_START_PSI_REAR",
	"INTERS_MIN_HOT_START_PSI_FRONT",
	"INTERS_MIN_HOT_START_PSI_REAR",
	"WETS_MIN_HOT_START_PSI_FRONT",
	"WETS_MIN_HOT_START_PSI_REAR",
}

local trackMinStartingPressureDefaults = {
	22,
	20,
	23,
	21,
	20,
	18,
}

local trackTyreBlanketTempKeys = {
	"SLICKS_TYRE_BLANKET_TEMP",
	"INTERS_TYRE_BLANKET_TEMP",
	"WETS_TYRE_BLANKET_TEMP",
}

local compoundDefaultsKeys = {
	"SOFT_COMPOUND",
	"MEDIUM_COMPOUND",
	"HARD_COMPOUND",
	"INTER_COMPOUND",
	"WET_COMPOUND",
}

local compoundTexturesKeys = {
	"COMPOUND_TARGET_MATERIAL",
	"SOFT_COMPOUND_TEXTURE",
	"MEDIUM_COMPOUND_TEXTURE",
	"HARD_COMPOUND_TEXTURE",
	"INTER_COMPOUND_TEXTURE",
	"WET_COMPOUND_TEXTURE",
}

local function compoundsTab()
	ui.tabItem("SETUP LIMITS", ui.TabItemFlags.None, function()
		ui.childWindow("compoundTabWindow", vec2(451, 491), function()
			if sim.raceSessionType == 3 then
				if not sim.isInMainMenu or sim.isSessionStarted then
					ui.newLine(1)

					ui.text("Can only edit CONFIGS while\nin the setup menu before a race session has started.")
					return
				end
			end

			ui.thinScrollbarBegin()

			ui.newLine(1)
			-- ui.pushFont(ui.Font.Small)
			-- ui.header("CONFIG CAR: ")

			-- ui.setNextItemWidth(ui.windowWidth() - 75)
			-- local changed = false
			-- ui.combo("##carIDs", selectedCarID, ui.ComboFlags.None, function()
			-- 	for i = 1, #uniqueCarIDs do
			-- 		if ui.selectable(uniqueCarIDs[i]) then
			-- 			selectedCarID, changed = uniqueCarIDs[i], true
			-- 		end
			-- 	end
			-- end)
			-- if changed then
			-- 	updateCarConfig()
			-- end
			-- ui.popFont()
			-- ui.newLine(1)

			if ui.textHyperlink("FIA Documents", rgbm.colors.red) then
				os.openURL("https://www.fia.com/documents/championships/fia-formula-one-world-championship-14/season")
				-- os.openURL("https://www.google.com/search?q=pirelli+press+" .. ac.getTrackName())
			end

			ui.newLine(1)

			ui.header("CURRENT TRACK MINIMUM HOT STARTING PRESSURE")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)

			for i = 1, #trackMinStartingPressureKeys do
				local key = trackMinStartingPressureKeys[i]
				local prefix = ""
				ui.text(prefix .. key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				local value, changed = ui.slider(
					"##track" .. key .. "label",
					selectedCarConfigINI:get(
						ac.getTrackID(),
						trackMinStartingPressureKeys[i],
						trackMinStartingPressureDefaults[i]
					),
					15,
					30,
					"%.1f psi",
					1
				)

				if changed then
					selectedCarConfigINI:setAndSave(
						ac.getTrackID(),
						trackMinStartingPressureKeys[i],
						math.floor(value / 0.5 + 0.5) * 0.5,
						false
					)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updatePirelliLimitsConfig()
					end
				end
			end
			ui.popFont()
			ui.newLine(1)

			ui.header("CURRENT TRACK TYRE BLANKET TEMPERATURES")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)

			for i = 1, #trackTyreBlanketTempKeys do
				local key = trackTyreBlanketTempKeys[i]
				local prefix = ""
				ui.text(prefix .. key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				local defaultTyreBlanketTemp = 70

				if i == 2 then
					defaultTyreBlanketTemp = 60
				elseif i == 3 then
					defaultTyreBlanketTemp = 40
				end

				local value, changed = ui.slider(
					"##track" .. key .. "label",
					selectedCarConfigINI:get(ac.getTrackID(), trackTyreBlanketTempKeys[i], defaultTyreBlanketTemp),
					0,
					100,
					"%.0f °C",
					1
				)

				if changed then
					selectedCarConfigINI:setAndSave(
						ac.getTrackID(),
						trackTyreBlanketTempKeys[i],
						math.floor(value / 5) * 5,
						false
					)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updatePirelliLimitsConfig()
					end
				end
			end
			ui.popFont()
			ui.newLine(1)

			ui.header("CURRENT TRACK CAMBER LIMITS")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)

			for i = 1, #trackCamberKeys do
				local key = trackCamberKeys[i]
				local prefix = ""
				ui.text(prefix .. key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				-- local value, changed = ui.inputText(
				-- 	"##track" .. key .. "label",
				-- 	selectedCarConfigINI:get(ac.getTrackID(), key, selectedCarConfig.data.COMPOUND_DEFAULTS[key]),
				-- 	ui.InputTextFlags.None
				-- )

				local defaultEOSCamberLimit = -3.25
				if i == 2 then
					defaultEOSCamberLimit = -2
				end

				local value, changed = ui.slider(
					"##track" .. key .. "label",
					selectedCarConfigINI:get(ac.getTrackID(), trackCamberKeys[i], defaultEOSCamberLimit),
					-5,
					0,
					"%.2f °",
					1
				)

				if changed then
					selectedCarConfigINI:setAndSave(
						ac.getTrackID(),
						trackCamberKeys[i],
						math.floor(value / 0.05 + 0.05) * 0.05,
						false
					)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updatePirelliLimitsConfig()
					end
				end
			end
			ui.popFont()
			ui.newLine(1)

			ui.header("CURRENT TRACK COMPOUNDS")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)

			for i = 1, #trackCompoundKeys do
				local key = trackCompoundKeys[i]
				local prefix = ""
				ui.text(prefix .. key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				-- local value, changed = ui.inputText(
				-- 	"##track" .. key .. "label",
				-- 	selectedCarConfigINI:get(ac.getTrackID(), key, selectedCarConfig.data.COMPOUND_DEFAULTS[key]),
				-- 	ui.InputTextFlags.None
				-- )

				local value, changed =
					selectedCarConfigINI:get(ac.getTrackID(), key, selectedCarConfig.data.COMPOUND_DEFAULTS[key]), false
				ui.combo("##track" .. key .. "label", ac.getTyresName(0, value), ui.ComboFlags.None, function()
					for i = 0, 10 do
						local tyresName = ac.getTyresName(0, i)
						if tyresName ~= "" then
							if ui.selectable(tyresName) then
								value, changed = i, true
							end
						end
					end
				end)

				if changed then
					selectedCarConfigINI:setAndSave(ac.getTrackID(), key, value, false)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updateTyreCompoundConfig()
						DRIVERS[i]:setAITyreCompound()
					end
				end
			end
			ui.popFont()
			ui.newLine(1)

			ui.header("COMPOUND DEFAULTS")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)

			for i = 1, #compoundDefaultsKeys do
				local key = compoundDefaultsKeys[i]
				local prefix = ""
				if key == "SOFT_COMPOUND" or key == "MEDIUM_COMPOUND" or key == "HARD_COMPOUND" then
					prefix = "DEFAULT "
				end
				ui.text(prefix .. key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				local value, changed = selectedCarConfig.data.COMPOUND_DEFAULTS[key], false
				ui.combo("##" .. key .. "label", ac.getTyresName(0, value), ui.ComboFlags.None, function()
					for i = 0, 10 do
						local tyresName = ac.getTyresName(0, i)
						if tyresName ~= "" then
							if ui.selectable(tyresName) then
								value, changed = i, true
							end
						end
					end
				end)

				if changed then
					selectedCarConfig:set("COMPOUND_DEFAULTS", key, value, false)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updateTyreCompoundConfig()
						DRIVERS[i]:setAITyreCompound()
					end
				end
			end
			ui.popFont()
			ui.newLine(1)

			ui.header("COMPOUND TEXTURES")
			ui.pushFont(ui.Font.Small)
			ui.newLine(1)
			for i = 1, #compoundTexturesKeys do
				local key = compoundTexturesKeys[i]
				ui.text(key:gsub("_", " ") .. ":")
				ui.sameLine(190)
				ui.setNextItemWidth(206)

				local value, changed
				if i == 1 then
					value, changed =
						selectedCarConfigINI:get(
							"COMPOUND_TEXTURES",
							key,
							selectedCarConfig.data.COMPOUND_TEXTURES[key]
						),
						false
					value, changed = ui.inputText("##" .. key .. "label", value, ui.InputTextFlags.None)
				else
					local tyreTextures = {}

					for i = 0, 10 do
						local tyresName = ac.getTyresName(0, i)

						if tyresName ~= "" then
							tyreTextures[i] = selectedCarExtConfigINI
								:get("TYRES_FX_CUSTOMTEXTURE_" .. tyresName, "TXDIFFUSE", "")
								:sub(1, -5)
						end
					end

					tyreTextures = table.distinct(tyreTextures)

					value, changed =
						selectedCarConfigINI:get(
							"COMPOUND_TEXTURES",
							key,
							selectedCarConfig.data.COMPOUND_TEXTURES[key]
						),
						false
					ui.combo("##" .. key .. "label", value, ui.ComboFlags.None, function()
						for i in ipairs(tyreTextures) do
							local tyresName = ac.getTyresName(0, i)
							if tyresName ~= "" then
								if ui.selectable(tyreTextures[i]) then
									value, changed = tyreTextures[i], true
								end
							end
						end
					end)
				end

				if changed then
					selectedCarConfigINI:setAndSave("COMPOUND_TEXTURES", key, value, false)
					for i = 0, #DRIVERS do
						DRIVERS[i]:updateTyreCompoundConfig()
						DRIVERS[i]:setAITyreCompound()
					end
				end
			end
			ui.newLine(1)
			ui.popFont()

			ui.thinScrollbarEnd()
		end)
	end)
end

local function aiTab()
	ui.tabItem("AI", ui.TabItemFlags.None, function()
		ui.newLine(1)

		-- if not sim.isInMainMenu then
		-- 	ui.text("Can only edit AI settings while\nin the setup menu before a session has started.")
		-- 	return
		-- elseif sim.isSessionStarted then
		-- 	ui.text("Can only edit AI settings while\nin the setup menu before a session has started.")
		-- 	return
		-- end

		ui.header("LEVEL")
		controls.slider(
			RARE_CONFIG,
			"AI",
			"ALTERNATE_LEVEL",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.AI.ALTERNATE_LEVEL == 1 and "Alternate AI Strength: ENABLED"
				or "Alternate AI Strength: DISABLED",
			"Changes the default AI level to be more competitive",
			function(v)
				return math.round(v, 0)
			end
		)

		ui.newLine(1)

		controls.slider(
			RARE_CONFIG,
			"AI",
			"RELATIVE_SCALING",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.AI.RELATIVE_SCALING == 1 and "Relative AI Scaling: ENABLED"
				or "Relative AI Scaling: DISABLED",
			"Enables relative AI scaling",
			function(v)
				return math.round(v, 0)
			end
		)

		controls.slider(
			RARE_CONFIG,
			"AI",
			"RELATIVE_LEVEL",
			70,
			100,
			1,
			true,
			RARE_CONFIG.data.AI.RELATIVE_LEVEL == 1 and "Relative AI Level %.0f%%" or "Relative AI Level %.0f%%",
			"Relative AI level, for easier scaling with BoP'd grids",
			function(v)
				for i = 0, #DRIVERS do
					DRIVERS[i]:setAIRelativeLevel()
				end

				return math.round(v, 0)
			end
		)

		ui.newLine(1)

		ui.header("TYRES")
		controls.slider(
			RARE_CONFIG,
			"AI",
			"FORCE_PIT_TYRES",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.AI.FORCE_PIT_TYRES == 1 and "Pit When Tyres Worn: ENABLED"
				or "Pit When Tyres Worn: DISABLED",
			"Force AI to pit for new tyres when their average tyre life is below AI TYRE LIFE",
			function(v)
				return math.round(v, 0)
			end
		)
		ui.newLine(1)

		controls.slider(
			RARE_CONFIG,
			"AI",
			"INTERS_WET_LEVEL",
			0,
			10,
			1,
			false,
			"Rain Level for Intermediates:%.2f %%",
			"Force AI to pit for new tyres when their average tyre life is below AI TYRE LIFE",
			function(v)
				return math.round(v, 2)
			end
		)
		controls.slider(
			RARE_CONFIG,
			"AI",
			"WETS_WET_LEVEL",
			0,
			10,
			1,
			false,
			"Rain Level for Full Wets:%.2f %%",
			"Force AI to pit for new tyres when their average tyre life is below AI TYRE LIFE",
			function(v)
				return math.round(v, 2)
			end
		)
		ui.newLine(1)

		local driver = DRIVERS[sim.focusedCar]

		if RARE_CONFIG.data.AI.FORCE_PIT_TYRES == 1 then
			if not sim.isInMainMenu and ac.getPatchVersionCode() >= 2278 then
				if driver.car.isAIControlled then
					local buttonFlags = ui.ButtonFlags.None
					if driver.isAIPitting or driver.car.isInPitlane then
						buttonFlags = ui.ButtonFlags.Disabled
					end
					if ui.button("FORCE FOCUSED AI TO PIT NOW", vec2(ui.windowWidth() - 77, 25), buttonFlags) then
						physics.setAIPitStopRequest(driver.index, true)
					end

					-- if ui.button("Awaken Car", vec2(ui.windowWidth()-77,25), ui.ButtonFlags.None) then
					--     driver.aiPrePitFuel = 140
					--     physics.setCarFuel(driver.index,140)
					--     physics.awakeCar(driver.index)
					--     physics.setCarFuel(driver.index,140)
					--     physics.resetCarState(driver.index)
					--     physics.engageGear(driver.index,1)
					--     physics.setEngineRPM(driver.index, 13000)
					--     physics.setCarVelocity(driver.index,vec3(0,0,5))
					-- end
				else
					if ui.button("FORCE ALL AI TO PIT NOW", vec2(ui.windowWidth() - 77, 25), ui.ButtonFlags.None) then
						for i = 0, #DRIVERS do
							local driver = DRIVERS[i]
							if driver.car.isAIControlled then
								physics.setAIPitStopRequest(driver.index, true)
							end
						end
					end

					-- if ui.button("TELEPORT ALL AI TO PIT NOW", vec2(ui.windowWidth()-77,25), ui.ButtonFlags.None) then
					--     for i=0, #DRIVERS do
					--         local driver = DRIVERS[i]
					--         if driver.car.isAIControlled then
					--             physics.teleportCarTo(driver.index,ac.SpawnSet.Pits)
					--         end
					--     end
					-- end
				end
			end
		end

		ui.header("PITSTOPS")
		ui.pushFont(ui.Font.Small)
		ui.newLine(1)

		for i = 1, #aiKeys do
			local key = aiKeys[i]
			local prefix = "PIT AT "
			ui.text(prefix .. key:gsub("_", " ") .. ":")
			ui.sameLine(190)
			ui.setNextItemWidth(206)

			-- local value, changed = ui.inputText(
			-- 	"##track" .. key .. "label",
			-- 	selectedCarConfigINI:get("AI", key, 0),
			-- 	ui.InputTextFlags.None
			-- )

			local value, changed =
				ui.slider("##track" .. key .. "label", selectedCarConfigINI:get("AI", key, 0), 0, 100, "%.0f %%", 1)

			if changed then
				selectedCarConfigINI:setAndSave("AI", key, value, false)
				for i = 0, #DRIVERS do
					DRIVERS[i]:updateTyreCompoundConfig()
					DRIVERS[i]:setAITyreCompound()
				end
			end
		end

		ui.popFont()
		ui.newLine(1)
	end)
end

local function audioTab()
	ui.tabItem("AUDIO", ui.TabItemFlags.None, function()
		ui.newLine(1)
		ui.header("VOLUME")
		local acVolume = ac.getAudioVolume(ac.AudioChannel.Main)

		controls.slider(
			RARE_CONFIG,
			"AUDIO",
			"MASTER",
			0,
			100,
			1,
			false,
			"Master: %.0f%%",
			SCRIPT_SHORT_NAME .. " Master Volume",
			function(v)
				return math.round(v, 0)
			end
		)

		controls.slider(
			RARE_CONFIG,
			"AUDIO",
			"DRS_BEEP",
			0,
			100,
			1,
			false,
			"DRS Beep: %.0f%%",
			"DRS Beep Volume",
			function(v)
				return math.round(v, 0)
			end
		)
		DRS_BEEP:setVolume(acVolume * RARE_CONFIG.data.AUDIO.MASTER / 100 * RARE_CONFIG.data.AUDIO.DRS_BEEP / 100)

		ui.sameLine(0, 2)
		if ui.button("##drsbeeptest", vec2(20, 20), ui.ButtonFlags.None) then
			DRS_BEEP:play()
		end
		ui.addIcon(ui.Icons.Play, 10, 0.5, nil, 0)
		if ui.itemHovered() then
			ui.setTooltip("Test DRS Beep")
		end

		controls.slider(
			RARE_CONFIG,
			"AUDIO",
			"DRS_FLAP",
			0,
			100,
			1,
			false,
			"DRS Flap: %.0f%%",
			"DRS Flap Volume",
			function(v)
				return math.round(v, 0)
			end
		)
		DRS_FLAP:setVolume(acVolume * RARE_CONFIG.data.AUDIO.MASTER / 100 * RARE_CONFIG.data.AUDIO.DRS_FLAP / 100)

		ui.sameLine(0, 2)
		if ui.button("##drsflaptest", vec2(20, 20), ui.ButtonFlags.None) then
			DRS_FLAP:play()
		end
		ui.addIcon(ui.Icons.Play, 10, 0.5, nil, 0)
		if ui.itemHovered() then
			ui.setTooltip("Test DRS Flap")
		end

		ui.newLine(1)
	end)
end

local function uiTab()
	ui.tabItem("UI", ui.TabItemFlags.None, function()
		ui.newLine(1)
		ui.header("RACE CONTROL BANNER")

		controls.slider(
			RARE_CONFIG,
			"NOTIFICATIONS",
			"X_POS",
			0,
			sim.windowWidth,
			1,
			false,
			"X Pos: %.0f",
			"X position on screen for the notification UI element",
			function(v)
				return math.round(v, 0)
			end
		)

		ui.sameLine(0, 2)

		if ui.button("##rcbannerxpos", vec2(20, 20), ui.ButtonFlags.None) then
			RARE_CONFIG:set("NOTIFICATIONS", "X_POS", (sim.windowWidth / 2 - 360))
		end
		ui.addIcon(ui.Icons.Target, 10, 0.5, nil, 0)
		if ui.itemHovered() then
			ui.setTooltip("Center X")
		end

		controls.slider(
			RARE_CONFIG,
			"NOTIFICATIONS",
			"Y_POS",
			0,
			sim.windowHeight,
			1,
			false,
			"Y Pos: %.0f",
			"Y position on screen for the notification UI element",
			function(v)
				return math.round(v, 0)
			end
		)

		ui.sameLine(0, 2)
		if ui.button("##rcbannerypos", vec2(20, 20), ui.ButtonFlags.None) then
			RARE_CONFIG.data.NOTIFICATIONS.Y_POS = sim.windowHeight / 2
		end
		ui.addIcon(ui.Icons.Target, 10, 0.5, nil, 0)
		if ui.itemHovered() then
			ui.setTooltip("Center Y")
		end

		controls.slider(
			RARE_CONFIG,
			"NOTIFICATIONS",
			"DURATION",
			0,
			10,
			1,
			false,
			"Timer: %.0f s",
			'Duration (seconds) that the "Race Control" banner will stay on screen',
			function(v)
				return math.round(v, 0)
			end
		)

		controls.slider(
			RARE_CONFIG,
			"NOTIFICATIONS",
			"SCALE",
			0.1,
			5,
			1,
			false,
			"Scale: %.1f",
			"Scale of the notification UI element",
			function(v)
				return math.round(v, 2)
			end
		)

		local buttonFlags = ui.ButtonFlags.None

		if ui.button("TEST BANNER", vec2(ui.windowWidth() - 77, 25), ui.ButtonFlags.None) then
			notifications.popup("RACE CONTROL BANNER", 10)
		end

		ui.newLine(1)
	end)
end

local function driverTab()
	ui.tabItem("DRIVER", ui.TabItemFlags.None, function()
		ui.newLine(1)

		ui.header("FUEL")
		controls.slider(
			RARE_CONFIG,
			"DRIVER",
			"TANK_FILL",
			0,
			1,
			1,
			true,
			RARE_CONFIG.data.DRIVER.TANK_FILL == 1 and "Fill Fuel Tank: ENABLED" or "Fill Fuel Tank: DISABLED",
			"Enable or disable refueling driver's car's fuel tank with enough fuel for the whole race, given the capacity is high enough",
			function(v)
				if v == 1 then
					if sim.raceSessionType == ac.SessionType.Race then
						DRIVERS[0]:setFuelTankRace()
					end
				end
				return math.round(v, 0)
			end
		)
	end)
end

function settingsMenu()
	local rareEnable = ac.isWindowOpen("rare")

	if rareEnable and sim.sessionsCount > 1 and ac.getPatchVersionCode() == 2501 then
		ui.newLine(3)

		ui.pushFont(ui.Font.Title)
		ui.textAligned(SCRIPT_NAME, vec2(0.5, 0.5), vec2(ui.availableSpaceX(), 34))
		ui.popFont()
		ui.newLine(3)

		ui.text(
			"CSP "
				.. ac.getPatchVersion()
				.. " "
				.. ac.getPatchVersionCode()
				.. " breaks RARE's race weekend usage.\nPlease downgrade to CSP 0.1.80-preview218 2363 to be on a \nstable CSP version."
		)
		return
	end

	if sim.isInMainMenu then
		ui.newLine(3)

		ui.pushFont(ui.Font.Title)
		ui.textAligned(SCRIPT_NAME, vec2(0.5, 0.5), vec2(ui.availableSpaceX(), 34))
		ui.popFont()

		if not sim.isOnlineRace then
			ui.sameLine(0, 0)
			ui.drawRectFilled(
				vec2(380, 30),
				vec2(420, 60),
				(rareEnable and injected) and rgbm(0, 1, 0, 0.5) or rgbm(1, 0, 0, 0.5)
			)

			ui.sameLine(380, 0)
			ui.setCursor(vec2(380, 30))

			local buttonLabel = (rareEnable and injected) and "ON" or "OFF"
			if ui.button(buttonLabel, vec2(40, 30), ui.ButtonFlags.None) then
				if injected then
					ac.setWindowOpen("rare", not ac.isWindowOpen("rare"))
				else
					inject.injectRare()
				end
			end

			if ui.itemHovered() then
				if not physics.allowed() then
					ui.setTooltip("Inject " .. SCRIPT_SHORT_NAME .. " App")
				else
					ui.setTooltip("Enable or Disable " .. SCRIPT_SHORT_NAME .. " App")
				end
			end
		else
			ui.newLine()
		end
	end

	if not sim.isOnlineRace then
		if ac.isWindowOpen("rare") and INITIALIZED and injected then
			ui.newLine(3)
		else
			ui.newLine(0)
			return
		end
	end

	ui.tabBar("settingstabbar", ui.TabBarFlags.None, function()
		if not sim.isOnlineRace then
			rulesTab()
			driverTab()
			aiTab()
			compoundsTab()
		end

		audioTab()
		uiTab()
	end)

	ui.setCursor(vec2(0, 601))
end
