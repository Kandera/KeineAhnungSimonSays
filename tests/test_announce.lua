C_VoiceChat = { SpeakText = function() end }
C_TTSSettings = {
	GetVoiceOptionID = function() return 1 end,
	GetSpeechRate = function() return 0 end,
}
Enum = { TtsVoiceType = { Standard = 1 } }
KASSDB = { voice = { enabled = true, style = "marker", volume = 100 } }

KASSTEST.lastSound = nil
function PlaySoundFile(path, channel)
	KASSTEST.lastSound = path
	KASSTEST.lastSoundChannel = channel
end

dofile("Announce.lua")

T.eq(KASS.MarkerName(1), "Stern", "marker 1 is Stern")
T.eq(KASS.MarkerName(3), "Diamant", "marker 3 is Diamant")
T.eq(KASS.MarkerName(8), "Totenkopf", "marker 8 is Totenkopf")

KASS.Turn = function()
	return "left"
end
KASS.Speak()
T.eq(type(KASSTEST.lastSound) == "string" and string.find(KASSTEST.lastSound, "en%-left%.ogg", 1) ~= nil, true, "speak plays en-left.ogg")
T.eq(KASSTEST.lastSoundChannel, "Master", "turn tone uses Master channel")

KASSTEST.lastSound = nil
KASSDB.voice.enabled = false
KASS.Speak()
T.eq(KASSTEST.lastSound, nil, "disabled voice plays nothing")
