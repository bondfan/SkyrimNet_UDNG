Scriptname skyrimnet_UDNG_Groups extends Quest 

int group_devices = 0 
zadLibs zlibs = None 

int style_forcefully = 0
int style_normally = 1
int style_gently = 2 
int style_silently = 3
int style_cancel = 4 


Actor player = None 
Function Setup()

    if zlibs == None 
        zlibs =Game.GetFormFromFile(0x00F624, "Devious Devices - Integration.esm") as zadlibs
    endif 

    if player == None 
        player = Game.GetPlayer() 
    endif 

    if group_devices != 0
        JValue.release(group_devices) 
    endif 
    group_devices = JValue.readFromFile("Data/SkyrimNet_UDNG/group-devices.json") 
    JValue.retain(group_devices) 
EndFunction 

Function UpdateDevices(Actor target) 
    String[] style_buttons = Utility.CreateStringArray(style_cancel + 1) 
    style_buttons[style_forcefully] = "Forcefully by player"
    style_buttons[style_normally] = "by player"
    style_buttons[style_gently] = "Gently by player"
    style_buttons[style_silently] = "(Silently)"
    style_buttons[style_cancel] = "Cancel"

    String msg = "How does "+target.getDisplayName() +" change devices: \n" \
        +" (Silently) with no message to LLM." 
    int style = SkyMessage.ShowArray(msg, style_buttons, getIndex = true) as int 
    if style < 0 || style >= style_cancel
        return 
    endif 
    ChangeGroup(style, target) 
EndFunction 

Function ChangeGroup(int style, Actor target) 
    int Done = JArray.count(group_devices) 
    String[] buttons = Utility.CreateStringArray(Done + 1) 
    String[] names = Utility.CreateStringArray(Done) 
    int[] devices = Utility.CreateIntArray(Done) 

    int[] equipped_original = Utility.CreateIntArray(Done,-1) 
    int[] equipped_current = Utility.CreateIntArray(Done,-1) 

    int i = 0
    while i < Done
        int group = JArray.getObj(group_devices, i) 
        names[i] = JMap.getStr(group,"name") 
        devices[i] = JMap.getObj(group,"devices")

        equipped_original[i] = -1 
        equipped_current[i] = -1 
        int j = JArray.count(devices[i]) - 1

        while 0 <= j && equipped_current[i] == -1
            int device = JArray.getObj(devices[i],j)
            if device > 0
                Armor deviceRendered = JMap.getForm(device, "formRendered") as Armor 
                Keyword kword = JMap.GetForm(device,"keyword") as Keyword
                if 1 == zlibs.IsWearingDevice(target, deviceRendered, kword) 
                    equipped_original[i] = device 
                    equipped_current[i] = device 
                endif 
            else 
                Trace("ChangeGroup no devices at "+i+","+j)
            endif 
            j -= 1
        endwhile 
        i += 1
    endwhile 
    buttons[Done] = "Done"

    int button = 0
    while button != Done
        uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") as uilistmenu
        i = 0 
        while i < Done 
            if equipped_current[i] <= 0
                listMenu.AddEntryItem(names[i]) 
            else
                listMenu.AddEntryItem("-- "+JMap.getStr(equipped_current[i],"name")+" --")
            endif 
            i += 1
        endwhile 
        listMenu.AddEntryItem("Done")

        listMenu.OpenMenu() 
        button = listMenu.GetResultInt()
        if button < 0
            button = Done
        elseif button < Done 
            equipped_current[button] = ChangeDevices(target, devices[button])
        endif 
    endwhile 

    if style >= style_silently
        return 
    endif 

    String[] style_desc = Utility.CreateStringArray(3) 
    style_desc[style_forcefully] = " forcefully"
    style_desc[style_normally] = ""
    style_desc[style_gently] = " gently"

    int removed = 0 
    int added = 1 
    String[] type_names = new String[2] 
    type_names[removed] = ""
    type_names[added] = ""
    String[] type_desc = new String[2] 
    type_desc[removed] = style_desc[style]+" unlocked and removed from "
    type_desc[added] = style_desc[style]+" locked onto "


    i = 0 
    String d_names = "" 
    while i < Done 
        if equipped_current[i] != equipped_original[i] 
            int type = removed 
            String name = ""
            if equipped_current[i] > 0
                type = added 
                name = JMap.getStr(equipped_current[i],"name")
            else 
                type = removed 
                name = JMap.getStr(equipped_original[i],"name")
            endif 

            if type_names[type] != "" 
                type_names[type] = type_names[type] + ", " 
            endif 
            type_names[type] = type_names[type] + name 
        endif 
        i += 1 
    endwhile 

    String msg = "" 
    int type = 0
    while type < 2 
        if type_names[type] != "" 
            msg = msg + player.GetDisplayName()+type_desc[type]+target.GetDisplayName() \
                +" the following: "+type_names[type]+". "
        endif 
        type += 1
    endwhile 
    if msg == ""
        return
    endif
    Debug.Notification(msg)
    SkyrimNetApi.DirectNarration(msg, player, target) 
EndFunction

int Function ChangeDevices(Actor target, int devices)
    uilistmenu listMenu = uiextensions.GetMenu("UIListMenu") as uilistmenu
    int button = 0
    int cancel = JArray.count(devices)
    int wearing = -1 
    while button < cancel
        int device = JArray.getObj(devices, button) 
        String name = JMap.getStr(device,"name")
        Armor deviceRendered = JMap.getForm(device, "formRendered") as Armor 
        Keyword kword = JMap.GetForm(device,"keyword") as Keyword
        if 1 == zlibs.IsWearingDevice(target, deviceRendered, kword) 
            name = name + " (remove)"
            wearing = device
        endif 
        listMenu.AddEntryItem(name)
        button += 1
    endwhile 
    listMenu.AddEntryItem("Cancel")

    listMenu.OpenMenu() 
    button = listMenu.GetResultInt()
    if button < 0 || button >= cancel
        return wearing
    endif

    int chastity_keys = AddKeys(target, zlibs.chastityKey, 1)
    int restraints_keys = AddKeys(target, zlibs.restraintsKey, 2)
    int piercing_keys = AddKeys(target, zlibs.piercingKey, 1)

    int selected = Jarray.getObj(devices, button) 
    Armor inventory = JMap.GetForm(selected, "formInventory") as Armor 
    Armor rendered = JMap.getForm(selected, "formRendered") as Armor 
    Keyword kword = JMap.GetForm(selected,"keyword") as Keyword
    if selected == wearing 
        Bool success = zlibs.UnLockDevice(target, inventory, rendered, destroyDevice = true)
        if success 
            wearing = -1
        endif 
    elseif wearing == -1 
        Bool success = zlibs.LockDevice(target, inventory, force = true)
        if success 
            wearing = selected 
        endif 
    else 
        Bool success = zlibs.SwapDevices(target, inventory, kword, destroyDevice=True)
        if success 
            wearing = selected 
        endif 
    endif 

    RemoveKeys(target, zlibs.chastityKey, chastity_keys)
    RemoveKeys(target, zlibs.restraintsKey, restraints_keys)
    RemoveKeys(target, zlibs.piercingKey, piercing_keys)
    return wearing
EndFunction

Function RemoveKeys(Actor target, Key z_key, int num)
    if num <= 0
        return
    endif
    target.RemoveItem(z_key, num, abSilent=True)
EndFunction

; Returns the number of keys added
int Function AddKeys(Actor target, Key z_key, int num) 
    int need = num - target.GetItemCount(z_key) 
    if need <= 0 
        return 0
    endif 
    target.AddItem(z_key, need, abSilent=True) 
    return need
EndFunction 

Function Trace(String msg, bool notification=false) 
    if notification 
        Debug.Notification(msg) 
    endif 
    Debug.Trace("[skyrimnet_UDNG_Groups] "+msg) 
EndFunction 