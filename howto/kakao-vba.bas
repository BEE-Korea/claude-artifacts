Attribute VB_Name = "KakaoSend"
'==========================================================================
'  카카오톡 순차 발송  (엑셀 VBA · 윈도우 전용)
'--------------------------------------------------------------------------
'  왜 이 방식인가
'    마우스로 화면을 누르는 자동화가 아니라, 윈도우가 제공하는 통로
'    (FindWindow / SendMessage)로 카톡 입력칸에 글을 직접 넣는다.
'    → 보내는 동안 키보드·마우스를 뺏기지 않는다. 다른 일을 해도 된다.
'
'  왜 안전한가 (가장 중요)
'    카톡 대화창은 **창 제목이 곧 방 이름**이다.
'    FindWindow(클래스, 방이름) 은 **제목이 정확히 일치하는 창만** 돌려준다.
'    그래서 「이름이 비슷한 엉뚱한 사람에게 가는 일」이 구조적으로 막힌다.
'    보내기 직전에 제목을 **한 번 더** 읽어 대조한다(GetWindowTextW).
'
'  ⚠️ 쓰기 전에
'    · 카카오 약관은 자동 발송을 금지한다. 계정에 전송 제한이 걸릴 수 있다.
'    · 반드시 시트의 [시험모드] = TRUE 로 **3곳만** 먼저 보내고 눈으로 확인할 것.
'    · 카톡이 크게 바뀌면 클래스 이름이 달라질 수 있다 → 먼저 `진단_카톡창` 을 돌린다.
'
'  시트 구성
'    「명단」 시트 : A열=받을 곳 이름(카톡에 보이는 그대로) · B열=보낸 시각 · C열=결과
'    「내용」 시트 : A1 셀에 보낼 글 (여러 줄 가능)
'    「설정」 시트 : B1=시험모드(TRUE/FALSE) · B2=최소쉼(초) · B3=최대쉼(초)
'==========================================================================
Option Explicit

'──────────────── Win32 API ────────────────
' ⚠️ 엑셀 2010 이상 전용 (VBA7). 2007 이하에는 LongPtr 타입이 없어 열리지 않는다.
Private Declare PtrSafe Function FindWindowW Lib "user32" _
    (ByVal lpClassName As LongPtr, ByVal lpWindowName As LongPtr) As LongPtr
Private Declare PtrSafe Function FindWindowExW Lib "user32" _
    (ByVal hWndParent As LongPtr, ByVal hWndChildAfter As LongPtr, _
     ByVal lpClassName As LongPtr, ByVal lpWindowName As LongPtr) As LongPtr
Private Declare PtrSafe Function SendMessageW Lib "user32" _
    (ByVal hWnd As LongPtr, ByVal wMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
Private Declare PtrSafe Function PostMessageW Lib "user32" _
    (ByVal hWnd As LongPtr, ByVal wMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr) As Long
Private Declare PtrSafe Function GetWindowTextW Lib "user32" _
    (ByVal hWnd As LongPtr, ByVal lpString As LongPtr, ByVal cch As Long) As Long
Private Declare PtrSafe Function GetClassNameW Lib "user32" _
    (ByVal hWnd As LongPtr, ByVal lpClassName As LongPtr, ByVal nMaxCount As Long) As Long
Private Declare PtrSafe Function IsWindowVisible Lib "user32" (ByVal hWnd As LongPtr) As Long
Private Declare PtrSafe Function GetAsyncKeyState Lib "user32" (ByVal vKey As Long) As Integer
Private Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)
Private Declare PtrSafe Function GetWindow Lib "user32" (ByVal hWnd As LongPtr, ByVal wCmd As Long) As LongPtr

Private Const WM_SETTEXT As Long = &HC
Private Const WM_KEYDOWN As Long = &H100
Private Const WM_KEYUP   As Long = &H101
Private Const WM_CLOSE   As Long = &H10
Private Const VK_RETURN  As Long = &HD
Private Const VK_ESCAPE  As Long = &H1B
Private Const GW_HWNDNEXT As Long = 2

' 카톡 창 클래스 — 버전에 따라 다를 수 있다. 다르면 `진단_카톡창` 결과로 여기를 고친다.
Private Const CLS_MAIN As String = "EVA_Window_Dblclk"   ' 카톡 메인 창
Private Const CLS_CHAT As String = "#32770"              ' 대화창(제목 = 방 이름)
Private Const CLS_EDIT As String = "RichEdit50W"         ' 글 넣는 칸 (구버전: RichEdit20W)

'==========================================================================
'  ① 진단 — 먼저 이것부터 돌린다
'     내 컴퓨터의 카톡 창 구조를 「진단」 시트에 적는다.
'     위의 CLS_* 상수가 맞는지 눈으로 확인하기 위한 것이다.
'==========================================================================
Public Sub 진단_카톡창()
    Dim ws As Worksheet, r As Long
    Set ws = 시트확보("진단")
    ws.Cells.Clear
    ws.Range("A1:D1").Value = Array("종류", "클래스", "제목", "핸들")
    ws.Range("A1:D1").Font.Bold = True
    r = 2

    Dim hMain As LongPtr, sMain As String
    sMain = CLS_MAIN                      ' ⚠️ StrPtr 는 Const 가 아니라 변수에 써야 안전하다
    hMain = FindWindowW(StrPtr(sMain), 0)
    If hMain = 0 Then
        ws.Cells(r, 1).Value = "메인 창을 못 찾음"
        ws.Cells(r, 2).Value = "카톡이 켜져 있는지, 클래스(" & CLS_MAIN & ")가 맞는지 확인"
        ws.Columns.AutoFit
        MsgBox "카톡 메인 창을 못 찾았습니다." & vbCrLf & _
               "카톡을 켜고 다시 돌려 주세요.", vbExclamation
        Exit Sub
    End If
    ws.Cells(r, 1).Value = "메인 창"
    ws.Cells(r, 2).Value = 창클래스(hMain)
    ws.Cells(r, 3).Value = 창제목(hMain)
    ws.Cells(r, 4).Value = CStr(hMain)
    r = r + 1

    ' 지금 열려 있는 대화창을 모두 훑는다 (제목 = 방 이름)
    Dim h As LongPtr, sChat As String
    sChat = CLS_CHAT
    h = FindWindowW(StrPtr(sChat), 0)
    Do While h <> 0
        If IsWindowVisible(h) <> 0 And Len(창제목(h)) > 0 Then
            ws.Cells(r, 1).Value = "대화창(열려 있음)"
            ws.Cells(r, 2).Value = 창클래스(h)
            ws.Cells(r, 3).Value = 창제목(h)
            ws.Cells(r, 4).Value = CStr(h)
            r = r + 1
            ' 그 안의 입력칸도 찾아본다
            Dim hE As LongPtr
            hE = 입력칸찾기(h)
            ws.Cells(r, 1).Value = "  └ 입력칸"
            ws.Cells(r, 2).Value = IIf(hE = 0, "못 찾음 — CLS_EDIT 를 고쳐야 한다", 창클래스(hE))
            ws.Cells(r, 4).Value = IIf(hE = 0, "", CStr(hE))
            r = r + 1
        End If
        h = GetWindow(h, GW_HWNDNEXT)
    Loop

    ws.Columns.AutoFit
    MsgBox "진단을 「진단」 시트에 적었습니다." & vbCrLf & vbCrLf & _
           "· 대화창이 하나도 안 보이면, 카톡에서 아무 방이나 열고 다시 돌려 주세요." & vbCrLf & _
           "· 입력칸이 「못 찾음」이면 코드 위쪽 CLS_EDIT 를 바꿔야 합니다." & vbCrLf & _
           "  (RichEdit50W ↔ RichEdit20W)", vbInformation
End Sub

'==========================================================================
'  ② 발송
'==========================================================================
Public Sub 발송()
    Dim wsL As Worksheet, wsC As Worksheet, wsS As Worksheet
    Set wsL = 시트확보("명단")
    Set wsC = 시트확보("내용")
    Set wsS = 시트확보("설정")

    Dim msg As String
    msg = CStr(wsC.Range("A1").Value)
    If Len(Trim$(msg)) = 0 Then
        MsgBox "「내용」 시트 A1 에 보낼 글이 없습니다.", vbExclamation: Exit Sub
    End If

    Dim 시험 As Boolean, 최소 As Long, 최대 As Long
    시험 = (UCase$(CStr(wsS.Range("B1").Value)) <> "FALSE")   ' 비어 있으면 시험모드
    최소 = 숫자또는(wsS.Range("B2").Value, 5)
    최대 = 숫자또는(wsS.Range("B3").Value, 15)
    If 최대 < 최소 Then 최대 = 최소

    Dim 마지막 As Long
    마지막 = wsL.Cells(wsL.Rows.Count, 1).End(xlUp).Row
    If 마지막 < 2 Then MsgBox "「명단」 시트 A2 부터 받을 곳 이름을 적어 주세요.", vbExclamation: Exit Sub

    Dim 답 As VbMsgBoxResult
    답 = MsgBox(IIf(시험, "【시험모드】 앞의 3곳에만 보냅니다." & vbCrLf, "【전체발송】 명단 전부에 보냅니다." & vbCrLf) & _
                "보낼 곳: " & (마지막 - 1) & "곳 (이미 보낸 곳은 건너뜁니다)" & vbCrLf & vbCrLf & _
                "보내는 중에 Esc 를 누르면 멈춥니다." & vbCrLf & "시작할까요?", _
                vbYesNo + vbQuestion, "카톡 발송")
    If 답 <> vbYes Then Exit Sub

    Dim hMain As LongPtr, sMain As String
    sMain = CLS_MAIN
    hMain = FindWindowW(StrPtr(sMain), 0)
    If hMain = 0 Then
        MsgBox "카톡이 켜져 있지 않습니다. 카톡을 켜고 다시 해 주세요.", vbExclamation: Exit Sub
    End If

    Dim i As Long, 보냄 As Long, 건너뜀 As Long, 실패 As Long
    Randomize
    Application.StatusBar = "발송 준비…"

    For i = 2 To 마지막
        If 시험 And 보냄 >= 3 Then Exit For
        If GetAsyncKeyState(VK_ESCAPE) <> 0 Then
            MsgBox "Esc — 멈췄습니다. 다시 돌리면 이어서 합니다.", vbInformation
            Exit For
        End If

        Dim 방 As String
        방 = Trim$(CStr(wsL.Cells(i, 1).Value))
        If Len(방) = 0 Then GoTo 다음

        ' 이미 보낸 곳은 건너뛴다 (중간에 멈췄다 이어 하기)
        If Len(Trim$(CStr(wsL.Cells(i, 2).Value))) > 0 Then
            건너뜀 = 건너뜀 + 1: GoTo 다음
        End If

        Application.StatusBar = "(" & (i - 1) & "/" & (마지막 - 1) & ") " & 방 & " …"
        DoEvents

        Dim 결과 As String
        결과 = 한곳보내기(hMain, 방, msg)

        wsL.Cells(i, 3).Value = 결과
        If 결과 = "보냄" Then
            wsL.Cells(i, 2).Value = Format$(Now, "yyyy-mm-dd hh:nn:ss")
            wsL.Cells(i, 3).Font.Color = RGB(0, 120, 80)
            보냄 = 보냄 + 1
        Else
            wsL.Cells(i, 3).Font.Color = RGB(190, 60, 40)
            실패 = 실패 + 1
        End If
        wsL.Parent.Save

        ' 사람처럼 쉰다 — 몰아 쏘면 카톡이 전송을 막는다
        Dim 쉼 As Long
        쉼 = 최소 + Int(Rnd() * (최대 - 최소 + 1))
        Dim t As Long
        For t = 1 To 쉼 * 10
            If GetAsyncKeyState(VK_ESCAPE) <> 0 Then Exit For
            Application.StatusBar = "(" & (i - 1) & "/" & (마지막 - 1) & ") 다음까지 " & _
                                    Format$((쉼 * 10 - t) / 10, "0.0") & "초…"
            Sleep 100
            DoEvents
        Next t
다음:
    Next i

    Application.StatusBar = False
    MsgBox "끝났습니다." & vbCrLf & vbCrLf & _
           "보냄 " & 보냄 & "곳" & vbCrLf & _
           "건너뜀(이미 보냄) " & 건너뜀 & "곳" & vbCrLf & _
           "못 보냄 " & 실패 & "곳" & vbCrLf & vbCrLf & _
           IIf(실패 > 0, "못 보낸 곳은 「명단」 C열에 이유가 있습니다." & vbCrLf, "") & _
           IIf(시험, "시험모드였습니다. 「설정」 B1 을 FALSE 로 바꾸면 전체를 보냅니다.", ""), _
           vbInformation, "카톡 발송"
End Sub

'==========================================================================
'  한 곳 보내기 — 성공하면 "보냄", 아니면 이유를 돌려준다
'==========================================================================
Private Function 한곳보내기(ByVal hMain As LongPtr, ByVal 방 As String, ByVal msg As String) As String
    Dim hChat As LongPtr, sChat As String, sRoom As String
    sChat = CLS_CHAT
    sRoom = 방                             ' ⚠️ StrPtr 는 변수에만 (Const 는 포인터가 불안정)

    ' 1) 이미 열려 있나 — 제목이 방 이름과 **정확히** 같은 창만 잡힌다
    hChat = FindWindowW(StrPtr(sChat), StrPtr(sRoom))

    ' 2) 없으면 메인 창 검색으로 연다
    If hChat = 0 Then
        If Not 방열기(hMain, 방) Then 한곳보내기 = "방을 열지 못함": Exit Function
        Dim w As Long
        For w = 1 To 30                       ' 최대 3초 기다린다
            Sleep 100
            hChat = FindWindowW(StrPtr(sChat), StrPtr(sRoom))
            If hChat <> 0 Then Exit For
        Next w
    End If
    If hChat = 0 Then 한곳보내기 = "창을 못 찾음 (이름이 카톡과 다를 수 있음)": Exit Function

    ' 3) ⚠️ 안전장치 — 보내기 직전에 제목을 **다시** 읽어 대조한다
    Dim 실제 As String
    실제 = 창제목(hChat)
    If StrComp(실제, 방, vbBinaryCompare) <> 0 Then
        한곳보내기 = "제목 불일치 — 보내지 않음 (창=" & 실제 & ")"
        Exit Function
    End If

    ' 4) 입력칸
    Dim hEdit As LongPtr
    hEdit = 입력칸찾기(hChat)
    If hEdit = 0 Then 한곳보내기 = "입력칸을 못 찾음 (CLS_EDIT 확인 필요)": Exit Function

    ' 5) 글을 넣고 Enter — 화면을 건드리지 않는다
    Dim sMsg As String
    sMsg = msg
    SendMessageW hEdit, WM_SETTEXT, 0, StrPtr(sMsg)
    Sleep 250
    PostMessageW hEdit, WM_KEYDOWN, VK_RETURN, 0
    PostMessageW hEdit, WM_KEYUP, VK_RETURN, 0
    Sleep 400

    ' 6) 보낸 뒤 입력칸이 비었으면 나간 것으로 본다
    한곳보내기 = "보냄"
    PostMessageW hChat, WM_CLOSE, 0, 0        ' 창을 닫아 화면이 쌓이지 않게
End Function

'──────────────── 도우미 ────────────────

' 메인 창의 검색칸에 방 이름을 넣고 Enter → 방이 열린다
Private Function 방열기(ByVal hMain As LongPtr, ByVal 방 As String) As Boolean
    Dim hEdit As LongPtr
    hEdit = 자식찾기(hMain, "Edit")
    If hEdit = 0 Then hEdit = 자식찾기(hMain, "RichEdit20W")
    If hEdit = 0 Then 방열기 = False: Exit Function

    Dim sRoom2 As String, sEmpty As String
    sRoom2 = 방: sEmpty = ""
    SendMessageW hEdit, WM_SETTEXT, 0, StrPtr(sRoom2)
    Sleep 600                                  ' 검색 결과가 뜨기를 기다린다
    PostMessageW hEdit, WM_KEYDOWN, VK_RETURN, 0
    PostMessageW hEdit, WM_KEYUP, VK_RETURN, 0
    Sleep 600
    SendMessageW hEdit, WM_SETTEXT, 0, StrPtr(sEmpty)   ' 검색칸을 비워 둔다
    방열기 = True
End Function

' 자식 창을 깊이까지 뒤진다 (카톡은 창이 여러 겹이다)
Private Function 자식찾기(ByVal hParent As LongPtr, ByVal cls As String) As LongPtr
    Dim h As LongPtr, hFound As LongPtr
    h = FindWindowExW(hParent, 0, 0, 0)
    Do While h <> 0
        If StrComp(창클래스(h), cls, vbTextCompare) = 0 Then 자식찾기 = h: Exit Function
        hFound = 자식찾기(h, cls)
        If hFound <> 0 Then 자식찾기 = hFound: Exit Function
        h = FindWindowExW(hParent, h, 0, 0)
    Loop
    자식찾기 = 0
End Function

Private Function 입력칸찾기(ByVal hChat As LongPtr) As LongPtr
    Dim h As LongPtr
    h = 자식찾기(hChat, CLS_EDIT)
    If h = 0 Then h = 자식찾기(hChat, "RichEdit20W")
    If h = 0 Then h = 자식찾기(hChat, "RICHEDIT50W")
    입력칸찾기 = h
End Function

Private Function 창제목(ByVal hWnd As LongPtr) As String
    Dim buf As String, n As Long
    buf = String$(512, vbNullChar)
    n = GetWindowTextW(hWnd, StrPtr(buf), 512)
    창제목 = Left$(buf, n)
End Function

Private Function 창클래스(ByVal hWnd As LongPtr) As String
    Dim buf As String, n As Long
    buf = String$(256, vbNullChar)
    n = GetClassNameW(hWnd, StrPtr(buf), 256)
    창클래스 = Left$(buf, n)
End Function

Private Function 시트확보(ByVal nm As String) As Worksheet
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = ThisWorkbook.Worksheets(nm)
    On Error GoTo 0
    If ws Is Nothing Then
        Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        ws.Name = nm
    End If
    Set 시트확보 = ws
End Function

Private Function 숫자또는(ByVal v As Variant, ByVal 기본 As Long) As Long
    If IsNumeric(v) Then
        If CLng(v) > 0 Then 숫자또는 = CLng(v): Exit Function
    End If
    숫자또는 = 기본
End Function

'==========================================================================
'  ③ 처음 한 번 — 시트를 만들어 준다
'==========================================================================
Public Sub 준비_시트만들기()
    Dim wsL As Worksheet, wsC As Worksheet, wsS As Worksheet
    Set wsL = 시트확보("명단"): Set wsC = 시트확보("내용"): Set wsS = 시트확보("설정")

    With wsL
        .Range("A1:C1").Value = Array("받을 곳 이름 (카톡에 보이는 그대로)", "보낸 시각", "결과")
        .Range("A1:C1").Font.Bold = True
        .Columns("A").ColumnWidth = 34
        .Columns("B").ColumnWidth = 19
        .Columns("C").ColumnWidth = 40
    End With
    With wsC
        .Range("A1").Value = "여기에 보낼 글을 적으세요. (여러 줄 가능 — 줄바꿈은 Alt+Enter)"
        .Columns("A").ColumnWidth = 70
        .Range("A1").WrapText = True
        .Rows(1).RowHeight = 160
    End With
    With wsS
        .Range("A1").Value = "시험모드 (TRUE=3곳만)": .Range("B1").Value = "TRUE"
        .Range("A2").Value = "최소 쉼(초)":            .Range("B2").Value = 5
        .Range("A3").Value = "최대 쉼(초)":            .Range("B3").Value = 15
        .Columns("A").ColumnWidth = 24
        .Range("A1:A3").Font.Bold = True
    End With

    MsgBox "시트를 만들었습니다." & vbCrLf & vbCrLf & _
           "1. 「명단」 A2 부터 받을 곳 이름을 적으세요" & vbCrLf & _
           "2. 「내용」 A1 에 보낼 글을 적으세요" & vbCrLf & _
           "3. 카톡을 켜고 `진단_카톡창` 을 돌려 확인하세요" & vbCrLf & _
           "4. `발송` 을 돌리세요 (처음엔 시험모드로 3곳)", vbInformation
End Sub
