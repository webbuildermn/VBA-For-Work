Attribute VB_Name = "RandomSelector"
Option Explicit
Sub RandomSample()
'Application.ScreenUpdating = False
Application.EnableEvents = False
MakeArray
'Application.ScreenUpdating = True
Application.EnableEvents = True
End Sub

Sub MakeArray()
Application.EnableEvents = False
    Dim MyArray As Variant
    Dim i As Integer
    Dim TryRand As Integer
    Dim RowCount As Integer
    Dim rngCurrentRegion As range
    Dim NewWs As Worksheet
    Dim CurrentWSName As String
    Dim PasteCell As String
    PasteCell = "b3"
    CurrentWSName = Application.ActiveSheet.name
    Dim DeleteExtraneous As Integer
    Dim InitLastCel As range
    Dim InitLastCeladds As String
    Dim InitLastCol As range
    Dim form As New SelectionParams
    Dim rng As range
    Dim ChosenRegion As range
    Dim chosenregiontxt As String
    Dim Quantity As Integer
    Dim bHeader As Boolean
    
    ' get user input
RequestInput:
    form.Show vbModal
    If form.range.text <> "" Then
    Set rng = range(form.range.text)
    End If

    If form.CurrentRegionGetter.text <> "" Then
        Set ChosenRegion = range(form.CurrentRegionGetter.text).CurrentRegion
    End If
    Quantity = form.SampleSize
    bHeader = form.bHeader
    
    ' process user input
    If form.CurrentRegionGetter.text <> "" Then
        RowCount = ChosenRegion.rows.count
    ElseIf form.range.text <> "" Then
        RowCount = rng.rows.count
    Else
        MsgBox ("Select either custom range or cell in table")
        GoTo RequestInput
    End If
    If bHeader = True Then
        RowCount = RowCount - 1
    End If
    
    If Quantity >= RowCount Then
        MsgBox ("Choose selection size that's smaller than row count")
        GoTo RequestInput
    End If

    ReDim MyArray(Quantity - 1)
    
    For i = 0 To Quantity - 1
retry:
        ' get random int values loaded into array
        TryRand = RndBetween(1, RowCount)
        If IsInArray(TryRand, MyArray) Then GoTo retry
        MyArray(i) = TryRand
    Next
    
    
    
    '' TMP Debug XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    MsgBox ("the row count is " & RowCount & " and the sample size is " & Quantity)
    '' TMP Debug XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    
    
    
    '' Paste current region of range to new worksheet

    If form.CurrentRegionGetter.text <> "" Then
        RowCount = ChosenRegion.rows.count
        Set rngCurrentRegion = ChosenRegion.CurrentRegion
    Else
        RowCount = rng.rows.count
        Set rngCurrentRegion = rng.CurrentRegion
    End If


    Set NewWs = Application.ActiveWorkbook.Worksheets.add(after:=Application.ActiveWorkbook.ActiveSheet)
    If Not WorksheetExists("sample") Then
        NewWs.name = "Sample"
    End If
    
    rngCurrentRegion.Copy NewWs.range(PasteCell)

    '' Mark those selected
    Set InitLastCel = range(PasteCell).Offset(4, 2).End(xlToRight).Offset(-4, 0) 'guard against partial row
    InitLastCeladds = InitLastCel.Address
    
    If bHeader = True Then
        With InitLastCel.Offset(0, 1) 'need to determine proper top row or could cause error
            .Value = "Selection"
            .Font.Bold = True
        End With
    Else
        With InitLastCel.Offset(-1, 1) 'need to determine proper top row or could cause error
            .Value = "Selection"
            .Font.Bold = True
        End With
    End If
    
    Dim instance As Variant
    If bHeader = True Then
        For Each instance In MyArray
            With InitLastCel.Offset(instance, 1)
                .Value = "x"
                .Interior.ColorIndex = 35
            End With
        Next
    Else
        For Each instance In MyArray
            With InitLastCel.Offset(instance - 1, 1)
                .Value = "x"
                .Interior.ColorIndex = 35
            End With
        Next
    End If
    
    ' 6 = yes, 7 = no
    DeleteExtraneous = MsgBox("Sample table created succesfully. Delete all extraneous rows?", vbYesNo)
    If DeleteExtraneous = 6 Then
        'get used column to iterate through
        Dim cell As range
        
        If bHeader = True Then
            Set InitLastCol = range(InitLastCel.Offset(1, 0).Address & ":" & InitLastCel.End(xlDown).Address)
        Else
            Set InitLastCol = range(InitLastCel.Address & ":" & InitLastCel.End(xlDown).Address)
        End If
            
restart:
        'InitLastCol = range(InitLastCel.Address & ":" & InitLastCel.End(xlDown).Address)
        For Each cell In InitLastCol
            If cell.Offset(0, 1).Value <> "x" Then
                cell.EntireRow.Delete
                ' to manage changed range problems
                GoTo restart
            End If
        Next
    End If
    
    range(InitLastCeladds).Offset(1, 3).Value = "Random Numbers Generated"
For i = 0 To Quantity - 1
    range(InitLastCeladds).Offset(2 + i, 3).Value = MyArray(i)
Next

MsgBox ("             Tada")
End Sub
' Gets random integer between low and high values
Function RndBetween(Low, High) As Integer
   Randomize
   RndBetween = Int((High - Low + 1) * Rnd + Low)
End Function

Private Function IsInArray(valToBeFound As Variant, arr As Variant) As Boolean
'DEVELOPER: Ryan Wells (wellsr.com)
'DESCRIPTION: Function to check if a value is in an array of values
'INPUT: Pass the function a value to search for and an array of values of any data type.
'OUTPUT: True if is in array, false otherwise
Dim element As Variant
On Error GoTo IsInArrayError: 'array is empty
    For Each element In arr
        If element = valToBeFound Then
            IsInArray = True
            Exit Function
        End If
    Next element
Exit Function
IsInArrayError:
On Error GoTo 0
IsInArray = False
End Function

Function WorksheetExists(sName As String) As Boolean
On Error Resume Next ''shouldn't need but just in case
    WorksheetExists = Evaluate("ISREF('" & sName & "'!A1)")
End Function
