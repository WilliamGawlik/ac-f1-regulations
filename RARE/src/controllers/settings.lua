require("src/classes/mapped_config")

local sim = ac.getSim()

local settings = {}

function settings:load()
	local settingsDir = ac.getFolder(ac.FolderID.ACApps) .. "\\lua\\" .. SCRIPT_SHORT_NAME .. "\\settings"
	local settingsFile = settingsDir .. "\\settings.ini"
	local settingsDefaultFile = settingsDir .. "\\default_settings.ini"

	if not io.fileExists(settingsFile) then
		io.copyFile(settingsDefaultFile, settingsFile)
	end

	if sim.isOnlineRace then
		ac.INIConfig.onlineExtras()
	end

	RARE_CONFIG = MappedConfig(settingsFile, {
		RULES = {
			DRS_RULES = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			DRS_ACTIVATION_LAP = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 3,
			DRS_GAP_DELTA = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1000,
			DRS_WET_DISABLE = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			PIRELLI_LIMITS = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			VSC_RULES = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			VSC_INIT_TIME = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 300,
			VSC_DEPLOY_TIME = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 300,
			RACE_REFUELING = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
		},
		DRIVER = {
			TANK_FILL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
		},
		AI = {
			FORCE_PIT_TYRES = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			ALTERNATE_LEVEL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			RELATIVE_SCALING = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 0,
			RELATIVE_LEVEL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 69,
			MGUK_CONTROL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			TANK_FILL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			INTERS_WET_LEVEL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 2,
			WETS_WET_LEVEL = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 4,
		},
		AUDIO = {
			MASTER = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 100,
			DRS_BEEP = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 50,
			DRS_FLAP = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 50,
		},
		NOTIFICATIONS = {
			X_POS = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or (sim.windowWidth / 2 - 360),
			Y_POS = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 50,
			SCALE = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
			DURATION = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 5,
		},
		MISC = {
			PHYSICS_REBOOT = (ac.INIConfig.OptionalNumber == nil) and ac.INIConfig.OptionalNumber or 1,
		},
	})
end

return settings
