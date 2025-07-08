#Requires AutoHotkey v2.0

global running := false
global attackSpeed := 0.8
global qianyaoRatio := 0.35
global moveDelayBase := 40
global isAttacking := false

global qianyaoRatioInput, moveDelayInput
global statusText, attackSpeedText

CreateGui()
SetTimer(UpdateAttackSpeed, 200)
SetTimer(AutoWalkA_Timer, 10)

AutoWalkA_Timer() {
    static nextAttackTime := 0
    global running, attackSpeed, qianyaoRatio, isAttacking, moveDelayBase

    if !running || isAttacking
        return

    now := A_TickCount
    totalCycleMs := 1000 / attackSpeed
    qianyaoMs := totalCycleMs * qianyaoRatio
    moveDelay := Max(5, moveDelayBase - attackSpeed * 10)

    if (now < nextAttackTime)
        return

    isAttacking := true
    nextAttackTime := now + Round(totalCycleMs)

    ; Log(Format("→ 发起攻击 tick: {} | 下一次: {} | 攻速: {:.2f} | 前摇: {:.2f} | 走位延迟: {}", now, nextAttackTime, attackSpeed, qianyaoRatio, moveDelay))

    Send("a")
    SetTimer(RunMoveAfterAttack, -Round(qianyaoMs + moveDelay))
}

RunMoveAfterAttack() {
    global isAttacking
    Click("Right")
    isAttacking := false
}

UpdateAttackSpeed() {
    global attackSpeed, attackSpeedText
    speed := GetAttackSpeed()
    if (speed > 0)
        attackSpeed := speed

    attackSpeedText.Text := Format("当前攻速: {:.2f}", attackSpeed)
}

GetAttackSpeed() {
    static url := "https://127.0.0.1:2999/liveclientdata/activeplayer"
    try {
        req := ComObject("WinHttp.WinHttpRequest.5.1")
        req.Open("GET", url, false)
        req.Option[4] := 256
        req.Send()
        if (req.Status != 200)
            return 0

        response := req.ResponseText
        pattern := '"attackSpeed":\s*([\d\.]+)'
        m := RegExMatch(response, pattern, &match)
        if m
            return Number(match[1])
        else
            return 0
    } catch {
        return 0
    }
}

CreateGui() {
    global mainGui, attackSpeedText, statusText, qianyaoRatioInput, moveDelayInput, qianyaoRatio, moveDelayBase

    mainGui := Gui()
    mainGui.Text := "LOL 自动走A 设置"

    statusText := mainGui.AddText("x10 y10 w300 h20", "状态: 已停止")
	
	realSpeed := GetAttackSpeed()
    attackSpeed := realSpeed > 0 ? realSpeed : attackSpeed  ; 若获取失败，使用默认
    attackSpeedText := mainGui.AddText("x120 y40 w100 h20", Format("{:.2f}", attackSpeed))

    mainGui.AddText("x10 y70 w120 h20", "前摇比例:")
    qianyaoRatioInput := mainGui.AddEdit("x140 y70 w80 h20", Format("{:.2f}", qianyaoRatio))
    qianyaoRatioInput.OnEvent("Change", OnQianyaoRatioChange)

    mainGui.AddText("x10 y100 w120 h20", "走位基准延迟:")
    moveDelayInput := mainGui.AddEdit("x140 y100 w80 h20", Format("{:d}", moveDelayBase))
    moveDelayInput.OnEvent("Change", OnMoveDelayChange)

    saveBtn := mainGui.AddButton("x100 y130 w100 h30", "保存修改")
    saveBtn.OnEvent("Click", SaveSettings)

    mainGui.Show("x100 y100 w300 h180")
}

SaveSettings(*) {
    global qianyaoRatioInput, moveDelayInput, qianyaoRatio, moveDelayBase

    qVal := qianyaoRatioInput.Value
    mVal := moveDelayInput.Value

    if (qVal > 0 && qVal < 1)
        qianyaoRatio := qVal
    else {
        MsgBox("前摇比例必须是0到1之间的小数。")
        return
    }

    if (mVal >= 0)
        moveDelayBase := mVal
    else {
        MsgBox("走位基准延迟必须是非负数。")
        return
    }

    MsgBox("设置已保存！`n前摇比例: " qianyaoRatio "`n走位延迟: " moveDelayBase)
}

CapsLock:: {
    global running, statusText
    running := !running
    statusText.Text := running ? "✅ 自动走A已启动" : "⛔ 自动走A已停止"
}

OnQianyaoRatioChange(*) {
    global qianyaoRatioInput
    val := qianyaoRatioInput.Value
    if (!IsNumber(val) || val <= 0 || val >= 1) {
        ToolTip("⚠️ 请输入 0 到 1 之间的小数", , , 1)
        SetTimer () => ToolTip("", , , 1), -1500
    }
}

OnMoveDelayChange(*) {
    global moveDelayInput
    val := moveDelayInput.Value
    if !(val >= 0)
        moveDelayInput.Value := ""
}

Log(msg) {
    timeStr := Format("{:yyyy-MM-dd HH:mm:ss}", A_Now)
    FileAppend(timeStr " - " msg "`n", A_ScriptDir "\autoWalkA.log")
}
