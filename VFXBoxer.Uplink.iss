objectdef vfxboxer
{
    variable weakref GlobalSettings

    method Initialize()
    {
        if ${distributedscope.Get[vfxboxer](exists)}
        {
            GlobalSettings:SetReference["distributedscope.Get[vfxboxer]"]
        }
        else
        {
            GlobalSettings:SetReference["distributedscope.New[\"$$>{
                "name":"vfxboxer",
                "distribution":"all local"
            }<$$\"]"]

            echo "Scope added: ${GlobalSettings.AsJSON~}"
        }

        LGUI2:LoadPackageFile["VFXBoxer.Uplink.lgui2Package.json"]
        This:InstallISMenu

        if ${This:LoadSettings(exists)}
            This:StoreSettings

        LGUI2.Element[vfxboxer.mainwindow]:SetVisibility[Visible]
    }

    method Shutdown()
    {
        This:UninstallISMenu
        LGUI2:UnloadPackageFile["VFXBoxer.Uplink.lgui2Package.json"]
    }

    method LoadSettings()
    {
        variable bool ret=TRUE
        variable filepath settingsFolder="${Script.CurrentDirectory~}"
        variable jsonvalue Settings
        if ${settingsFolder.FileExists[VFXBoxer.Settings.json]}
        {
            ret:Set[FALSE]
            Settings:ParseFile["${settingsFolder~}/VFXBoxer.Settings.json"]
            if ${Settings.Type.Equal[object]}
                ret:Set[TRUE]
        }
        

        if !${Settings.Type.Equal[object]}
        {
;            echo VFXBoxer using default settings
            Settings:SetValue["${LGUI2.Skin[VFXBoxer].Template[vfxboxer.DefaultSettings]~}"]
        }

        if ${Settings.Type.Equal[object]}
        {
;            echo "Applying to GlobalSettings: GlobalSettings:SetValues[${Settings~}]"
            GlobalSettings:SetValues["${Settings~}"]
        }
        return ${ret}
    }

    method StoreSettings()
    {
        if !${GlobalSettings.Used}
            return FALSE

        if  !${GlobalSettings.AsJSON.Get[values]:WriteFile["${Script.CurrentDirectory~}/VFXBoxer.Settings.json",multiline](exists)}
            return FALSE

        return TRUE        
    }

    method InstallISMenu()
    {
        This:UninstallISMenu

		variable int menuid
		menuid:Set["${ISMenu.AddSubMenu["VFXBoxer"]}"]

        ISMenu["${menuid}"]:AddCommand["Launch Control Window","VFXBoxer:LaunchControlWindow"]
    }

    method UninstallISMenu()
    {
        ISMenu.FindChild["VFXBoxer"]:Remove
    }
    
    method CaptureForegroundWindow(string forSession)
    {
        This:CaptureWindow["${Display.ForegroundWindow~}",${forSession~}]
    }

    method CaptureWindow(string hwnd, string forSession)
    {
        echo "CaptureWindow ${hwnd~}"        
        echo RegisterSource=${This:RegisterSource["window.${hwnd~}","${hwnd~}"](exists)}

        if ${forSession.NotNULLOrEmpty}
        {
            InnerSpace:Relay["${forSession~}",VFXBoxer,AddView,"window.${hwnd~}","${hwnd~}"]
        }
;        
    }

    method RegisterSource(string name, string hwnd)
    {
        echo RegisterSource ${name~} ${hwnd~}
        return ${VideoFeed:RegisterSource["${name~}","${hwnd~}"](exists)}
    }

    member GetBackgroundColor()
    {
        variable string BackgroundColor="${GlobalSettings.Get[backgroundColor]~}"

        ; blank/missing/default
        if !${BackgroundColor.NotNULLOrEmpty}
            return ""

        ; #rrggbb
        if ${BackgroundColor.StartsWith["#"]}
            return "${BackgroundColor.Right[-1]~}"

        ; rrggbb
        return "${BackgroundColor~}"
    }

    method SetBackgroundColor(string newValue)
    {
        if ${newValue.NotNULLOrEmpty}
            GlobalSettings:SetString[backgroundColor,"${newValue~}"]
        else
            GlobalSettings:Erase[backgroundColor]
    }

    method LaunchControlWindow()
    {
        variable string BackgorundColor="${This.GetBackgroundColor~}"

        if ${BackgorundColor.NotNULLOrEmpty}
        {
            Open "DxNothing" "DxNothing Client DirectX 11 64-bit" -startup "VFXBoxer:EnableControlWindow" -addparam "-color ${BackgorundColor~}"
        }
        else
        {
            Open "DxNothing" "DxNothing Client DirectX 11 64-bit" -startup "VFXBoxer:EnableControlWindow"
        }
    }

    member GetWindowSize()
    {
        if ${GlobalSettings.Has[windowSize]}
            return "${GlobalSettings.Get[windowSize].Get[1]}x${GlobalSettings.Get[windowSize].Get[2]}"
        
        return "1920x1040"
    }

    method SetWindowSize(string newValue)
    {
        variable int w=1920
        variable int h=1040

        w:Set["${newValue.Token[1,x]~}"]
        h:Set["${newValue.Token[2,x]~}"]

        if ${w}<=0
            w:Set[1920]
        if ${h}<=0
            h:Set[1920]
        
        GlobalSettings:Set[windowSize,"[${w},${h}]"]
    }

}

variable(global) vfxboxer VFXBoxer

function main()
{
    while 1
        waitframe    
}
