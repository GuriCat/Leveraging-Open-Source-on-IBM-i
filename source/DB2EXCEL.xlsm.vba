Option Explicit

Dim inbuf, tfrOpt, DBCSVPath, DBFFDPath, outXLSX, convDateTimeDec, convDateTimeChr As String
Dim params As Variant
Dim maxRow, maxCol, cellValue As Long
Dim dtFormula As String
Dim ThisBook As Workbook
Dim ThisSheet As Worksheet
Dim i, j As Long

Private Sub Workbook_Open()

    Call main
    
End Sub

Sub main()

    ' テキストファイルからパラメーターの読み込み
    With CreateObject("Scripting.FileSystemObject")
        With .GetFile(Environ("TEMP") & "\DB2EXCEL_PARAM.TXT").OpenAsTextStream
            inbuf = .ReadAll
            .Close
        End With
    End With
    Kill Environ("TEMP") & "\DB2EXCEL_PARAM.TXT"
    
    params = Split(inbuf, vbLf) ' 改行コードにLFを想定
    If UBound(params) < 6 Then
        MsgBox "IBM i からのパラメーターが少ない", vbCritical, "DB2EXCELエラー"
        Workbooks("DB2EXCEL.xlsm").Close
    End If
    
    ' パラメーターファイルの指定を取り込み
    tfrOpt = params(0) ' N:NetServer、F:FTP
    DBCSVPath = params(1)
    DBFFDPath = params(2)
    If tfrOpt = "F" Then
        DBCSVPath = Environ("TEMP") & "\" & Mid(params(1), InStrRev(params(1), "\") + 1)
        DBFFDPath = Environ("TEMP") & "\" & Mid(params(2), InStrRev(params(2), "\") + 1)
    End If
    outXLSX = params(3)
    convDateTimeDec = params(4) ' 日付・時刻フィールドの推測とフォーマット(数値フィールド)
    convDateTimeChr = params(5) ' 日付・時刻フィールドの推測とフォーマット(文字フィールド)
    If DBCSVPath = "" Or DBFFDPath = "" Then
        MsgBox "IBM i からの指定されたパスが空文字", vbCritical, "DB2EXCELエラー"
        Workbooks("DB2EXCEL.xlsm").Close
    End If
    
    ' CSVファイルの読み込みとExcelブックの作成
    genExcel
    
    ' Move new worksheets to new book
    ' Sheets(Array("DB照会結果", "フィールド記述")).Move ' なぜかとても遅い
    Sheets(Array("DB照会結果", "フィールド記述")).Copy
    
    ' キャプションの設定
    ActiveWindow.Caption = outXLSX
    ' Excelブックのクローズ
    Application.DisplayAlerts = False
    Workbooks("DB2EXCEL.xlsm").Close
    
End Sub

' Create new Excel book

Sub genExcel()

    Dim colHdg, fldColHdgAry() As String
    Dim fldLengthAry(), fldDigitAry(), fldPrecAry() As Integer
    Dim colTypeAry() As Variant

    ' 現在あるワークシートの最後尾に新しいワークシートを挿入
    Application.SheetsInNewWorkbook = 3
    Workbooks("DB2EXCEL.xlsm").Activate
    Worksheets.Add after:=Worksheets(Worksheets.Count)
    ActiveSheet.Name = "DB照会結果"
    Worksheets.Add after:=Worksheets(Worksheets.Count)
    ActiveSheet.Name = "フィールド記述"
    
    ' FFDデータのCSVファイルの読み込み
    Worksheets("フィールド記述").Activate
    
    With ActiveSheet.QueryTables.Add(Connection:="TEXT;" _
        & DBFFDPath, Destination:=ActiveSheet.Range("A2"))
        
        ' .AdjustColumnWidth = True
        .TextFileCommaDelimiter = True
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .Refresh BackgroundQuery:=False
        .Delete
    
    End With
    
    ' FFDシートのフォーマット
    With ActiveSheet

        ' DSPFFD出力ファイルの不要なフィールドを除去
        .Range("BE1:CX1").EntireColumn.Delete
        .Range("AC1:BC1").EntireColumn.Delete
        .Range("A1:I1").EntireColumn.Delete
        
        maxCol = ActiveSheet.Range("A2").Value
        
        ' フィールド属性を配列にセット
        ReDim fldLengthAry(maxCol)
        ReDim fldDigitAry(maxCol)
        ReDim fldPrecAry(maxCol)
        ReDim fldColHdgAry(maxCol)
        ReDim colTypeAry(maxCol)
        
        For i = 0 To maxCol
            ' Field length
            fldLengthAry(i) = .Cells(i + 2, 7).Value ' フィールド長
            ' Digit and precision
            fldDigitAry(i) = .Cells(i + 2, 8).Value ' 数値桁数
            fldPrecAry(i) = .Cells(i + 2, 9).Value  ' 小数点桁数
            ' Column heading
            colHdg = .Cells(i + 2, 16).Value & _
                .Cells(i + 2, 17).Value & .Cells(i + 2, 18).Value
            fldColHdgAry(i) = Replace(Replace(colHdg, " ", ""), "　", "")
            ' Use field name when colhdg is blank
            If fldColHdgAry(i) = "" Then
                fldColHdgAry(i) = .Cells(i + 2, 4).Value ' 外部フィールド名
            End If
            ' QueryTable.TextFileColumnDataTypesのプロパティをセット
            If fldDigitAry(i) > 0 Then
                colTypeAry(i) = xlGeneralFormat
            Else
                colTypeAry(i) = xlTextFormat
            End If
        Next i
        
        ' 参考としてセルA1にlibrary_file名をセット
        .Range("A1").Offset(.Range("A2").Value + 2).Value = outXLSX
               
        ' 見出しの設定
        .Range("A1:T1").Value = Array( _
            "フィールド数", "レコード様式長", "内部フィールド名", _
            "外部フィールド名", "出力バッファー位置", "入力バッファー位置", _
            "フィールド長―バイト数", "桁数", "小数点の右側の桁数", _
            "フィールド・テキスト記述", "REF の和", "参照ファイル", _
            "参照ライブラリー", "参照レコード様式", "参照フィールド", _
            "カラム見出し 1", "カラム見出し 2", "カラム見出し 3", _
            "フィールドタイプ", "コード化文字セット ID")
            
        ' ワークシートをフォーマット
        .Range("A2").Select
        ActiveWindow.FreezePanes = True     ' ヘッダーの固定
        ActiveWindow.Zoom = 80              ' 拡大率の設定

    End With
    
    ' テーブルの定義 object.Add ( [ sourcetype, source, linksource, xllistobjecthasheaders, destination, tablestylename ] )
    With ActiveSheet.ListObjects.Add(, , , xllistobjecthasheaders:=xlYes)
        .Name = "ファイルフィールド記述"
        .TableStyle = "TableStyleLight14"
    End With
    ' 列幅自動調整
    ActiveSheet.ListObjects("ファイルフィールド記述").Range.Columns.AutoFit

    ' 物理ファイルのCSVファイル読み込み
    Worksheets("DB照会結果").Activate
    
    With ActiveSheet.QueryTables.Add(Connection:="TEXT;" _
        & DBCSVPath, Destination:=ActiveSheet.Range("A2"))
        
        ' .AdjustColumnWidth = True
        .TextFileCommaDelimiter = True
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFileColumnDataTypes = colTypeAry
        .Refresh BackgroundQuery:=False
        .Delete
    
    End With
        
    Application.Calculation = xlCalculationManual '手動計算
    Application.ScreenUpdating = False '画面更新停止
                     
    ' DB照会出力のワークシートをフォーマット
    With ActiveSheet
                 
        maxRow = .Range("A1").SpecialCells(xlLastCell).Row
    
        ' FFDシートを参照して欄見出しをセット
        For i = 0 To maxCol - 1
            .Range("A1").Offset(0, i).NumberFormat = "@"
            .Range("A1").Offset(0, i).Value = RTrim(fldColHdgAry(i))
            ' 数値フィールドにカンマを指定
            ' If (fldDigitAry(i) <> 6) And (fldDigitAry(i) <> 8) Then
                If fldPrecAry(i) = 0 Then
                    .Columns(i + 1).NumberFormat = "#,##0"
                Else
                    .Columns(i + 1).NumberFormat = "#,##0." _
                    & String(fldPrecAry(i), "0")
                End If
            ' End If
        Next i
         
        ' 日付・時刻フィールドの推測とフォーマット(数値フィールド)
        If UCase(convDateTimeDec) = "Y" Then
        
            ' カラムの属性をチェック
            For i = 0 To maxCol - 1
                ' ColHdgが「日」という文字を含み、かつ、桁数が8か6 → 日付
                If (fldColHdgAry(i) Like "*日*") And ((fldDigitAry(i) = 8) Or _
                   (fldDigitAry(i) = 6)) Then
                    .Columns(i + 1).NumberFormatLocal = "yyyy/mm/dd"
                    For j = 2 To maxRow
                        ' Excelは数値が6桁でも年4桁に変換
                        ' セルに入っている値を書式に無関係に取得するため .value2 を使用。(overflow エラー回避)
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(DATEVALUE(TEXT(" & cellValue & _
                            ",""00!/00!/00""))),TEXT(" & cellValue & _
                            ",""@""),DATEVALUE(TEXT(" & cellValue & ",""00!/00!/00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
                ' ColHdgが「時」という文字を含んで「日」を含まず、かつ、桁数が6 → 時刻
                If (fldColHdgAry(i) Like "*時*") And (Not fldColHdgAry(i) Like "*日*") And _
                   (fldDigitAry(i) = 6) Then
                    .Columns(i + 1).NumberFormatLocal = "hh:mm:ss"
                    For j = 2 To maxRow
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(TIMEVALUE(TEXT(" & cellValue & _
                            ",""00!:00!:00""))),TEXT(" & cellValue & _
                            ",""@""),TIMEVALUE(TEXT(" & cellValue & ",""00!:00!:00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
            Next i
            
        End If
        
        ' 日付・時刻フィールドの推測とフォーマット(文字フィールド)
        If UCase(convDateTimeChr) = "Y" Then
            ' カラムの属性をチェック
            For i = 0 To maxCol - 1
                ' 日付はymd、dmy、mdyなどが判定できないので保留
                ' ColHdgが「時」という文字を含んで「日」を含まず、かつ、桁数が6 → 時刻
                If (fldColHdgAry(i) Like "*時*") And (Not fldColHdgAry(i) Like "*日*") And _
                    (fldLengthAry(i) = 6) And (fldDigitAry(i) = 0) Then
                    .Columns(i + 1).NumberFormatLocal = "hh:mm:ss"
                    For j = 2 To maxRow
                        cellValue = .Range(Cells(j, i + 1).Address(False, False)).Value2
                        dtFormula = _
                            "=IF(ISERROR(TIMEVALUE(TEXT(" & cellValue & _
                            ",""00!:00!:00""))),TEXT(" & cellValue & _
                            ",""@""),TIMEVALUE(TEXT(" & cellValue & ",""00!:00!:00"")))"
                        .Range(Cells(j, i + 1).Address).Formula = dtFormula
                    Next j
                End If
            Next i
        End If
                    
        With .PageSetup         ' ページのセット
            .Zoom = False
            .FitToPagesTall = False
            .FitToPagesWide = 1
        End With
        ActiveWindow.View = xlPageBreakPreview
            
        ' ワークシートのフォーマット
        .Range("A2").Select
        ActiveWindow.FreezePanes = True     ' ヘッダーの固定
        ActiveWindow.Zoom = 80              ' 拡大率の設定
        
    End With
        
    ' テーブルの定義
    With ActiveSheet.ListObjects.Add(, , , xllistobjecthasheaders:=xlYes)
        .Name = "データベース検索結果"
        .TableStyle = "TableStyleMedium2"
    End With
    
    ' 行高・列幅調整
    ' ActiveSheet.ListObjects("データベース検索結果").DataBodyRange.Rows.RowHeight = 13
    ' ActiveSheet.ListObjects("データベース検索結果").DataBodyRange.Columns.AutoFit
    For i = 1 To maxCol + 1
        Columns(i).ColumnWidth = Columns(i).ColumnWidth + 2
    Next i
    Cells.EntireRow.RowHeight = 13 ' なぜか途中の行から行高が広くなるため...
    
    Application.Calculation = xlCalculationAutomatic '自動計算
    Application.ScreenUpdating = True '画面更新再開
            
End Sub
