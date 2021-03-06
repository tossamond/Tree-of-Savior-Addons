local acutil = require("acutil");

local settings = {
	maxNumberOfChannelsToShow = 30;
};

function CHANNELSURFER_ON_INIT(addon, frame)
	addon:RegisterMsg('GAME_START', 'CHSURF_CREATE_BUTTONS');

	acutil.setupHook(SELECT_ZONE_MOVE_CHANNEL_HOOKED, "SELECT_ZONE_MOVE_CHANNEL");
	acutil.setupHook(POPUP_CHANNEL_LIST_HOOKED, "POPUP_CHANNEL_LIST");
end

function SELECT_ZONE_MOVE_CHANNEL_HOOKED(index, channelID)
	local zoneInsts = session.serverState.GetMap();
	if zoneInsts.pcCount == -1 then
		ui.SysMsg(ClMsg("ChannelIsClosed"));
		return;
	end

	RUN_GAMEEXIT_TIMER("Channel", channelID);
end

function POPUP_CHANNEL_LIST_HOOKED(parent)
	if parent:GetUserValue("ISOPENDROPCHANNELLIST") == "YES" then
		parent:SetUserValue("ISOPENDROPCHANNELLIST", "NO");
		return;
	end

	parent:SetUserValue("ISOPENDROPCHANNELLIST", "YES");

	local frame = parent:GetTopParentFrame();
	local ctrl = frame:GetChild("btn");

	local zoneInsts = session.serverState.GetMap();

	local NUMBER_OF_CHANNELS = zoneInsts:GetZoneInstCount();
	local numberOfChannelsToShow = NUMBER_OF_CHANNELS;

	if numberOfChannelsToShow >= settings.maxNumberOfChannelsToShow then
		numberOfChannelsToShow = settings.maxNumberOfChannelsToShow;
	end

	local dropListFrame = ui.MakeDropListFrame(ctrl, -270, 0, 300, 600, numberOfChannelsToShow, ui.LEFT, "SELECT_ZONE_MOVE_CHANNEL");

	if zoneInsts == nil then
		app.RequestChannelTraffics();
	else
		if zoneInsts:NeedToCheckUpdate() == true then
			app.RequestChannelTraffics();
		end

		for i = 0, NUMBER_OF_CHANNELS - 1 do
			local zoneInst = zoneInsts:GetZoneInstByIndex(i);
			local str, gaugeString = GET_CHANNEL_STRING(zoneInst);
			ui.AddDropListItem(str, gaugeString, zoneInst.channel);
		end
	end
end

function CHSURF_CHANGE_CHANNEL(nextChannel)
	local zoneInsts = session.serverState.GetMap();
	local numberOfChannels = zoneInsts:GetZoneInstCount();
	local currentChannel = session.loginInfo.GetChannel();
	nextChannel = (1 + nextChannel + currentChannel) % numberOfChannels;

	if nextChannel == 0 then
		nextChannel = numberOfChannels;
	end

	SELECT_ZONE_MOVE_CHANNEL_HOOKED(0, nextChannel-1);
end

function CHSURF_CREATE_BUTTONS()
	local frame = ui.GetFrame("minimap");
	local btnsize = 30;
	local nextbutton = frame:CreateOrGetControl('button', "nextbutton", 5+34, 5, btnsize, btnsize);
	tolua.cast(nextbutton, "ui::CButton");
	nextbutton:SetText("{s22}>");
	nextbutton:SetEventScript(ui.LBUTTONUP, "CHSURF_CHANGE_CHANNEL(1)");
	nextbutton:SetClickSound('button_click_big');
	nextbutton:SetOverSound('button_over');

	local prevbutton = frame:CreateOrGetControl('button', "prevbutton", 5, 5, btnsize, btnsize);
	tolua.cast(prevbutton, "ui::CButton");
	prevbutton:SetText("{s22}<");
	prevbutton:SetEventScript(ui.LBUTTONUP, "CHSURF_CHANGE_CHANNEL(-1)");
	prevbutton:SetClickSound('button_click_big');
	prevbutton:SetOverSound('button_over');
end
