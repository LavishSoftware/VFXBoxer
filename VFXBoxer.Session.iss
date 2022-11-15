objectdef vfxboxer
{
    variable jsonvalue Views="{}"

    variable jsonvalue ShowViews="[]"
    variable jsonvalueref ActiveView

    variable jsonvalue Settings="{}"
    variable weakref GlobalSettings

    variable uint LineupSize=200
    variable string LineupEdge="bottom"
    variable string CaptureHotkey=""

    variable bool ShowLineupSizeControl=TRUE

    variable taskmanager TaskManager=${LMAC.NewTaskManager["vfxboxer"]}

    method Initialize()
    {
    }

    method Shutdown()
    {
        This:UninstallHotkeys
        This:DisableGlobalBind
        This:ClearViews        
        LGUI2:UnloadPackageFile["VFXBoxer.Session.lgui2Package.json"]
        TaskManager:Destroy
    }

    member GetWindowSize()
    {
        if ${GlobalSettings.Has[windowSize]}
            return "${GlobalSettings.Get[windowSize].Get[1]}x${GlobalSettings.Get[windowSize].Get[2]}"
        
        return
    }

    member GetCaptureHotkey()
    {
        return "${CaptureHotkey~}"
    }

    method OnSettingChanged(string param1)
    {
        echo "OnSettingChanged param1=${param1~} Context(type)=${Context(type)} Context=${Context~}"

        switch ${param1}
        {
            case cloneHotkey
            case allCloneHotkey
            case nextViewHotkey
            case previousViewHotkey
            case viewHotkeys
                This:UninstallHotkeys
                This:InstallHotkeys
                break
        }
    }

    method EnableControlWindow()
    {
        uplink relaygroup -join vfxboxer

        LGUI2:LoadPackageFile["VFXBoxer.Session.lgui2Package.json"]

        Settings:SetValue["${LGUI2.Skin[VFXBoxer].Template[vfxboxer.DefaultSettings]}"]

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
        }

;        distributedscope.OnScopeAdded:AttachAtom[This:OnScopeAdded]
        GlobalSettings.OnValueChanged:AttachAtom[This:OnSettingChanged]

        Event[On Activate]:AttachAtom[This:OnWindowActivate]
        Event[On Deactivate]:AttachAtom[This:OnWindowDeactivate]

        variable string windowSize
        windowSize:Set["${This.GetWindowSize~}"]

        if ${windowSize.NotNULLOrEmpty}
            WindowCharacteristics -size ${windowSize~} -pos ${Display.Monitor.Left},${Display.Monitor.Top} -frame none
        else
            WindowCharacteristics -size fullscreen -pos ${Display.Monitor.Left},${Display.Monitor.Top} -frame none
        
        CaptureHotkey:Set["${GlobalSettings.Get[captureHotkey]~}"]
        This:SetLineupEdge["${GlobalSettings.Get[lineupEdge]~}"]
        This:SetLineupSize["${GlobalSettings.GetInteger[lineupSize]}"]

        This:EnableGlobalBind
        This:InstallHotkeys
    }

    method OnScopeAdded(string name)
    {
        echo "OnScopeAdded: ${name~} Context=${Context~}"
        echo "Current GlobalSettings: ${GlobalSettings.AsJSON~}"
    }

    method InstallHotkey(string name, string keyCombo, string onPress="", string onRelease="")
    {
        if !${keyCombo.NotNULLOrEmpty}
            return

        variable jsonvalue joBinding
        joBinding:SetValue["$$>
        {
            "name":${name.AsJSON~},
            "combo":${keyCombo.AsJSON~},
            "eventHandler":{
                "type":"task",
                "taskManager":"vfxboxer",
                "task":{
                    "type":"ls1.code",
                    "start":${onPress.AsJSON~},
                    "stop":${onRelease.AsJSON~}
                }
            }
        }
        <$$"]

        ; now add the binding to LGUI2!
;        echo "AddBinding ${joBinding~}"
        LGUI2:AddBinding["${joBinding~}"]
    }

    method InstallHotkeys()
    {
        
        This:InstallHotkey["vfxboxer.PreviousView","${GlobalSettings.Get[previousViewHotkey]~}","VFXBoxer:PreviousView"]
        This:InstallHotkey["vfxboxer.NextView","${GlobalSettings.Get[nextViewHotkey]~}","VFXBoxer:NextView"]
        This:InstallHotkey["vfxboxer.ToggleClone","${GlobalSettings.Get[cloneHotkey]~}","VFXBoxer:ToggleCloneMode"]
        This:InstallHotkey["vfxboxer.AllToggleClone","${GlobalSettings.Get[allCloneHotkey]~}","VFXBoxer:AllToggleCloneMode"]

        variable int i
        variable jsonvalueref jaViewHotkeys
        jaViewHotkeys:SetReference["GlobalSettings.Get[viewHotkeys]"]

        if ${jaViewHotkeys.Type.Equal[array]}
        {
            for (i:Set[1] ; ${i}<=${jaViewHotkeys.Used} ; i:Inc)
            {
                This:InstallHotkey["vfxboxer.View${i}","${jaViewHotkeys.Get[${i}]~}","VFXBoxer:ActivateByNum[${i}]"]
            }
        }
    }

    method UninstallHotkeys()
    {
        LGUI2:RemoveBinding["vfxboxer.PreviousView"]
        LGUI2:RemoveBinding["vfxboxer.NextView"]
        LGUI2:RemoveBinding["vfxboxer.ToggleClone"]
        LGUI2:RemoveBinding["vfxboxer.AllToggleClone"]

        if ${jaViewHotkeys.Type.Equal[array]}
        {
            for (i:Set[1] ; ${i}<=${jaViewHotkeys.Used} ; i:Inc)
            {
                LGUI2:RemoveBinding["vfxboxer.View${i}"]                
            }
        }
    }

    method PreviousView()
    {
        This:ActivateByNum[${ShowViews.Used}]
    }

    method NextView()
    {
        This:ActivateByNum[1]
    }

    method OnWindowActivate()
    {
        This:DisableGlobalBind
    }

    method DisableGlobalBind()
    {
        squelch GlobalBind -delete "VFXBoxer.Capture"
    }

    method EnableGlobalBind()
    {
        if ${CaptureHotkey.NotNULLOrEmpty}
            squelch GlobalBind "VFXBoxer.Capture" "${CaptureHotkey~}" "VFXBoxer:CaptureForegroundWindow"
    }

    method SetCaptureHotkey(string newValue)
    {
        CaptureHotkey:Set["${newValue~}"]
        This:DisableGlobalBind

        if ${Display.Foreground}
            This:EnableGlobalBind        
    }

    method OnWindowDeactivate()
    {
        This:EnableGlobalBind
    }

    method CaptureForegroundWindow()
    {
        InnerSpace:Relay[uplink,VFXBoxer,CaptureForegroundWindow,"${Session~}"]
    }

    method OnLayoutAreaChanged()
    {
        This:UpdateVerticalSliderRange
        This:UpdateHorizontalSliderRange
    }

    method SetShowLineupSizeControl(bool newValue)
    {
        ShowLineupSizeControl:Set[${newValue}]        

        if !${ShowLineupSizeControl}
        {
            LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Collapsed]
            LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Collapsed]
            return
        }

        switch ${LineupEdge}
        {
            case top
            case bottom
                LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Visible]
                LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Collapsed]
                break
            case left
            case right
                LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Collapsed]
                LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Visible]
                break
        }
    }

    method SetLineupSize(uint newValue)
    {
        LineupSize:Set["${newValue}"]

        switch ${LineupEdge}
        {
            case bottom
            case top
            default
                LGUI2.Element[vfxlist].Content:SetSize[-1,${newValue}]
                break
            case left
            case right
                LGUI2.Element[vfxlist].Content:SetSize[${newValue},-1]
                break
        }
    }

    method SetLineupEdge(string newValue)
    {
        switch ${newValue}
        {
            default
                LineupEdge:Set[bottom]

                LGUI2.Element[vfxboxer.VerticalSlider]:SetSlideFromEdge[bottom]
                if ${ShowLineupSizeControl}
                    LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Visible]
                LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Collapsed]
                break
            case bottom
            case top
                LineupEdge:Set["${newValue~}"]

                LGUI2.Element[vfxboxer.VerticalSlider]:SetSlideFromEdge["${newValue~}"]
                if ${ShowLineupSizeControl}
                    LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Visible]
                LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Collapsed]
                break
            case right
            case left
                LineupEdge:Set["${newValue~}"]

                LGUI2.Element[vfxboxer.HorizontalSlider]:SetSlideFromEdge["${newValue~}"]
                if ${ShowLineupSizeControl}
                    LGUI2.Element[vfxboxer.HorizontalSlider]:SetVisibility[Visible]
                LGUI2.Element[vfxboxer.VerticalSlider]:SetVisibility[Collapsed]
                break
        }
    }

    member:uint HorizontalSliderMax()
    {
        return ${LGUI2.Element[vfxboxer.LayoutArea].ActualWidth}
    }

    method UpdateHorizontalSliderRange()
    {
        LGUI2.Element[vfxboxer.HorizontalSlider]:SetRange[0,${This.HorizontalSliderMax}]
    }

    member:uint VerticalSliderMax()
    {
        return ${LGUI2.Element[vfxboxer.LayoutArea].ActualHeight}
    }

    method UpdateVerticalSliderRange()
    {
        LGUI2.Element[vfxboxer.VerticalSlider]:SetRange[0,${This.VerticalSliderMax}]
    }

    member:uint HorizontalSliderPosition()
    {
        return ${LineupSize}
    }

    method OnHorizontalSliderPosition(uint newValue)
    {
        This:SetLineupSize[${newValue}]
    }

    member:uint VerticalSliderPosition()
    {
        return ${LineupSize}
    }

    method OnVerticalSliderPosition(uint newValue)
    {
        This:SetLineupSize[${newValue}]
    }

    
    method AddView(string name, gdiwindow hwnd)
    {
;        echo AddView ${name~}
        variable jsonvalue jo="{}"
        jo:SetString[name,"${name~}"]
        jo:SetString[hwnd,"${hwnd~}"]
        jo:SetInteger[processId,"${hwnd.ProcessID}"]
        jo:SetString[processName,"${hwnd.ProcessName~}"]
        jo:SetString[windowText,"${hwnd.Text~}"]
        jo:SetBool[clone,0]

        echo "New View \"${name~}\"=${jo~}"
        Views:SetByRef["${name~}",jo]

        This:Activate["${name~}"]
        LGUI2.Element[vfxlist]:PullItemsBinding
    }

    method RefreshView(jsonvalueref joView)
    {
        variable gdiwindow hwnd="${joView.Get[hwnd]}"

        joView:SetString[windowText,"${hwnd.Text~}"]
    }

    method OnActivateButton()
    {
;        echo "OnActivateButton ${Context(type)} Args=${Context.Args~} Source.Context=${Context.Source.Context~}"
        variable jsonvalueref joData="Context.Source.Context"

        if !${joData.Type.Equal[object]}
            return

        if ${ActiveView.Get[name].Equal["${joData.Get[name]~}"]}
            This:DeactivateView
        else
            This:ActivateByRef[joData]
    }

    method OnCloseButton()
    {
;        echo "OnCloseButton ${Context(type)} Args=${Context.Args~} Source.Context=${Context.Source.Context~}"
        variable jsonvalueref joData="Context.Source.Context"
        if !${joData.Type.Equal[object]}
        {
            return
        }

        if !${Context.Args.GetBool[position]} || !${Context.Args.Get[controlName]~.Equal[Mouse1]}
            return


        if ${ActiveView.Get[name].Equal["${joData.Get[name]~}"]}
        {
            ActiveView:SetReference[0]
        }
        else
            This:RemoveViewByRef[joData]
    }

    method SetClone(string name, bool newValue)
    {
        variable jsonvalueref joView="Views.Get[\"${name~}\"]"
;        echo "SetClone ${name~} ${newValue}"
        This:SetCloneByRef[joView,${newValue}]
    }

    method ToggleCloneMode()
    {
        ActiveView:SetBool[clone,"${ActiveView.GetBool[clone].Not}"]

        This:RefreshClones
    }

    method AllToggleCloneMode()
    {
        variable bool newValue
        newValue:Set["${ActiveView.GetBool[clone].Not}"]
        ActiveView:SetBool[clone,"${newValue}"]
       
        ShowViews:ForEach["ForEach.Value:SetBool[clone,${newValue}]"]

        This:RefreshClones
    }

    method SetCloneByRef(jsonvalueref joView, bool newValue)
    {
;        echo "SetCloneByRef[${newValue}] ${joView~}"
        joView:SetBool[clone,${newValue}]

        This:RefreshClones
    }

    member:lgui2elementref GetActiveVideoFeed()
    {
        return ${LGUI2.Element[vfxboxer.ActiveView].Locate["","videofeed","descendant"].ID}
    }

    method DeactivateView()
    {
        if !${ActiveView.Type.Equal[object]}
            return

        ShowViews:AddByRef[ActiveView]
        ActiveView:SetReference[0]
        LGUI2.Element[vfxlist]:PullItemsBinding        
    }

    member:bool ArrayContainsView(jsonvalueref joArray, jsonvalueref joView)
    {
        variable int i
        variable string name="${joView.Get[name]~}"
        for (i:Set[1] ; ${i}<=${joArray.Used} ; i:Inc )
        {
            if ${joArray.Get[${i},name].Equal["${name~}"]}
                return TRUE
        }
        return FALSE
    }

    method ShowView(jsonvalueref joView)
    {
        if ${ArrayContainsView[ShowViews,joView]}
            return FALSE
        
        This:RefreshView[joView]
        ShowViews:AddByRef[joView]
        LGUI2.Element[vfxlist]:PullItemsBinding
        return TRUE
    }

    method UnshowView(jsonvalueref joView)
    {
        variable int i
        variable string name="${joView.Get[name]~}"
;        echo UnshowView name=${name~}
        for (i:Set[1] ; ${i}<=${ShowViews.Used} ; i:Inc )
        {
            if ${ShowViews.Get[${i},name].Equal["${name~}"]}
            {
;                echo removing view ${i}
                ShowViews:Erase[${i}]                
                LGUI2.Element[vfxlist]:PullItemsBinding
                return TRUE
            }
        }
        return FALSE        
    }

    method Activate(string name)
    {
        This:ActivateByRef["Views.Get[\"${name~}\"]"]
    }    

    method ActivateByNum(uint numView)
    {
;        echo ActivateByNum[${numView}]
        This:ActivateByRef["ShowViews.Get[${numView}]"]
    }

    method ActivateByRef(jsonvalueref jo)
    {
;        echo "ActivateByRef ${jo~}"
        This:RefreshView[jo]

        This:DeactivateView
        This:UnshowView[jo]
        ActiveView:SetReference[jo]

        ; apply clones
        This:RefreshClones

        This.GetActiveVideoFeed:KeyboardFocus
        ; InnerSpace:Relay[uplink,VFXBoxer,RegisterSource,"${ActiveFeedName~}","${jo.Get[hwnd]~}"]
    }

    method RefreshClones()
    {
        variable lgui2elementref activeFeed=${This.GetActiveVideoFeed.ID}
        if !${activeFeed.ID}
        {
            ; echo "RefreshClones: No Active Feed"
            return
        }

        activeFeed:ClearClones
           
        if !${ActiveView.Type.Equal[object]}
        {
            ; echo "RefreshClones: Active View not an object...?"
            return
        }

        if !${ActiveView.GetBool[clone]}
        {
            ; echo "RefreshClones: Ignoring Active View without clone option"
            return
        }

        ShowViews:ForEach["This:ViewToClone[${activeFeed.ID},ForEach.Value]"]
    }

    method ViewToClone(lgui2elementref activeFeed, jsonvalueref joView)
    {
        if !${joView.GetBool[clone]}
        {
            ; echo "ViewToClone: Ignoring feed without clone option"
            return
        }

        activeFeed:AddClone["${joView.Get[name]~}"]

        ; echo "ViewToClone: Added ${joView.Get[name]~}"
    }

    method RemoveView(string name)
    {
        This:RemoveViewByRef["${jo.Get["${name~}"]}"]
    }

    method RemoveViewByRef(jsonvalueref jo)
    {
        Views:Erase["${jo.Get[name]~}"]
        This:UnshowView[jo]
    }

    method ClearViews()
    {
        Views:ForEach["This:RemoveViewByRef[ForEach.Value]"]
        ShowViews:Clear
    }
}

variable(global) vfxboxer VFXBoxer

function main()
{
    while 1
        waitframe
}
