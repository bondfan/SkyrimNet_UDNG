Scriptname skyrimnet_UDNG_PlayerAlias extends ReferenceAlias

skyrimnet_UDNG_Groups Property groups Auto

Event OnInit()
    Setup()
EndEvent

Event OnPlayerLoadGame()
    Setup()
EndEvent

Function Setup()
    SkyrimNetApi.RegisterEventSchema("DDUDNG","SkyrimNet_DDUDNG Event","Events related to actors wearing DDNG devices","[{\"name\":\"info\",\"type\":0,\"required\":true,\"description\":\"Event Info\"}]","{\"recent_events\":\"{{info}}\",\"raw\":\"{{info}}\",\"compact\":\"{{info}}\",\"verbose\":\"{{info}}\"}",true,20000)
    groups.Setup()
    skyrimnet_UDNG_MCM mcm = (groups as Quest) as skyrimnet_UDNG_MCM
    mcm.Setup()
    skynet_DeviousScript.RegisterDeviousActions(mcm)
    skynet_DeviousScript.RegisterDeviousDecorators()
    RegisterForModEvent("DeviceActorOrgasm", "OnOrgasm")
    RegisterForModEvent("UDEvent_DeviceLocked","DeviceLockedEvent")
    RegisterForModEvent("UDEvent_DeviceUnlocked","DeviceUnlockedEvent")
    RegisterForModEvent("UDEvent_DeviceMinigameBegin","OnStartMinigame")
    RegisterForModEvent("UDEvent_DeviceMinigameEnd","OnStopMinigame")
    RegisterForModEvent("UDEvent_VibDeviceEffectStart","OnVibrateStart")
    UnregisterForModEvent("UDEvent_VibDeviceEffectUpdate")
    RegisterForModEvent("UDEvent_VibDeviceEffectEnd","OnVibrateStop")
EndFunction

Event OnVibrateStart(String source, Form WearerF, Form Inv, Form Render,int zones,int baseStrength,int currentStrength)
    Actor Wearer = WearerF as Actor
    if Wearer == None || Inv == None
        return
    endif
    skynet_DeviousScript.SendPapyrusEvent(Wearer.GetDisplayName()+"'s "+Inv.getName()+" starts vibrating.",Wearer)
EndEvent
Event OnVibrateStop(String source, Form WearerF, Form Inv, Form Render,int zones,int baseStrength)
    Actor Wearer = WearerF as Actor
    if Wearer == None || Inv == None
        return
    endif
    skynet_DeviousScript.SendPapyrusEvent(Wearer.GetDisplayName()+"'s "+Inv.getName()+" stops vibrating.",Wearer)
EndEvent
Event DeviceLockedEvent(String source,Form WearerF,Form Inv,Form Render)
    Actor Wearer = WearerF as Actor
    if Wearer == None || Inv == None
        return
    endif
    skynet_DeviousScript.SendPapyrusEvent(Wearer.GetDisplayName()+" had a "+Inv.getName()+" locked on them.",Wearer)
EndEvent
Event DeviceUnlockedEvent(String source,Form WearerF,Form Inv,Form Render)
    Actor Wearer = WearerF as Actor
    if Wearer == None || Inv == None
        return
    endif
    skynet_DeviousScript.SendPapyrusEvent(Wearer.GetDisplayName()+" had a "+Inv.getName()+" unlocked from them.",Wearer)
EndEvent
Event OnStartMinigame(String source,Form WearerF,Form HelperF,String minigame,float durability, Form Inv,Form Render)
    Actor Wearer = WearerF as Actor
    Actor Helper = HelperF as Actor
    if Wearer == None || Inv == None
        return
    endif
    String w_name = Wearer.GetDisplayName()
    String device = Inv.getName()
    If StringUtil.Find(minigame,"Struggle") != -1
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" starts struggling to escape from their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" starts struggling to help "+w_name+" escape from their "+device+".",Wearer)
        EndIf
    EndIf
    If StringUtil.Find(minigame,"Lockpick") != -1
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" starts picking the lock on their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" starts picking the lock on "+w_name+"'s "+device+".",Wearer)
        EndIf
    EndIf
    If StringUtil.Find(minigame,"Cutting") != -1
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" starts trying to cut off their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" starts trying to cut off "+w_name+"'s "+device+".",Wearer)
        EndIf
    EndIf
    If StringUtil.Find(minigame,"KeyUnlock") != -1
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" starts trying to unlock their "+device+" with a key.",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" starts trying to unlock "+w_name+"'s "+device+" with a key.",Wearer)
        EndIf
    EndIf
    If StringUtil.Find(minigame,"RepairLock") != -1
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" starts trying to repair the jammed lock on their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" starts trying to repair the jammed lock on "+w_name+"'s "+device+".",Wearer)
        EndIf
    EndIf
EndEvent
Event OnStopMinigame(String source,Form WearerF,Form HelperF,String minigame,float durability,bool isUnlocked,Form Inv,Form Render)
    Actor Wearer = WearerF as Actor
    Actor Helper = HelperF as Actor
    if Wearer == None || Inv == None
        return
    endif
    String w_name = Wearer.GetDisplayName()
    String device = Inv.getName()
    If isUnlocked
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" finally escaped from their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" finally helped "+w_name+" escape from their "+device+".",Wearer)
        EndIf
    Else
        If helper==none
            skynet_DeviousScript.SendPapyrusEvent(w_name+" failed to escape from their "+device+".",Wearer)
        Else
            skynet_DeviousScript.SendPapyrusEvent(Helper.GetDisplayName()+" failed to help "+w_name+" escape from their "+device+".",Wearer)
        EndIf
    EndIf
EndEvent
; DD sends only the actor's leveled base name; match it against nearby actors, falling back to the player.
Event OnOrgasm(string eventName, string strArg, float numArg, Form sender)
    Actor player = Game.GetPlayer()
    Actor source = player
    String name = strArg
    if player.GetLeveledActorBase().GetName() != strArg
        Actor[] actors = MiscUtil.ScanCellActors(player, 2000)
        int i = actors.length - 1
        while 0 <= i && source == player
            if actors[i].GetLeveledActorBase().GetName() == strArg
                source = actors[i]
                name = source.GetDisplayName()
            endif
            i -= 1
        endwhile
    endif
    skynet_DeviousScript.SendPapyrusEvent(name+" is cumming!", source)
EndEvent
