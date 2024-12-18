local sim = ac.getSim()

if sim.isOnlineRace then
	return
end

require("app/version")
require("src/helpers/ac_ext")
require("src/init")
require("src/ui/windows/debug_window")
require("src/ui/windows/settings_window")
require("src/ui/windows/notification_window")
require("src/classes/audio")
local racecontrol = require("src/controllers/race_control")
local pirellilimits = require("src/controllers/pirelli_limits")

INITIALIZED = false
RARE_CONFIG = nil
RESTARTED = false

local rc = nil
local sfx = nil
local delay = 0

ac.onSessionStart(function(sessionIndex, restarted)
	delay = os.clock() + 1
end)

function script.update(dt)
	if ac.getLastError() then
		ui.toast(ui.Icons.Warning, "[RARE] AN ERROR HAS OCCURED")
		log(ac.getLastError())
	end

	if sim.isInMainMenu then
		ac.setWindowOpen("settings_setup", true)
	end

	if not ac.isWindowOpen("rare") then
		return
	elseif not physics.allowed() then
		ui.toast(
			ui.Icons.Warning,
			"[RARE] INJECT THE APP! Inject the app by clicking the 'OFF' button in the RARE window while in the setup menu."
		)
		return
	end

	if INITIALIZED then
		if not sfx then
			sfx = Audio()
		end

		if sim.isLive and os.clock() > delay then
			if not sim.isOnlineRace then
				rc = racecontrol.getRaceControl(dt, sim)
			end
			sfx:update()
			pirellilimits.update()
		end
	else
		if sim.isInMainMenu then
			INITIALIZED = initialize(sim)
		end
	end
end

function script.windowMain(dt)
	if INITIALIZED then
		ui.transparentWindow(
			"notifications",
			vec2(RARE_CONFIG.data.NOTIFICATIONS.X_POS - 1742, RARE_CONFIG.data.NOTIFICATIONS.Y_POS - 204),
			vec2(10000, 7500),
			function()
				notificationHandler(dt)
			end
		)
	end
end

function script.windowDebug(dt)
	if not INITIALIZED or rc == nil then
		return
	end

	ac.setWindowTitle(
		"debug",
		string.format(
			"%s Debug | %s (%s) | %s",
			SCRIPT_SHORT_NAME,
			SCRIPT_VERSION,
			SCRIPT_VERSION_CODE,
			(ac.isWindowOpen("rare") and "ENABLED" or "DISABLED")
		)
	)

	debug_window(sim, rc, ac.getLastError())
end

function script.windowSettings()
	if os.clock() < delay then
		return
	end

	ac.setWindowTitle(
		"settings",
		string.format("%s Settings | %s (%s)", SCRIPT_NAME, SCRIPT_VERSION, SCRIPT_VERSION_CODE)
	)

	settingsMenu()
end
