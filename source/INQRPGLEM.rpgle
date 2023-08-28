     H DFTACTGRP(*NO) ACTGRP(*NEW)
     H OPTION(*SRCSTMT : *NOUNREF : *NODEBUGIO)
     H DATEDIT(*YMD)
      * ファイル定義
     FPERSONL1  IF   E           K DISK
     FPERSON    IF   E           K DISK    RENAME(PERSONR : PERSONR2)
     FINQDSPFM  CF   E             WORKSTN INFDS(dspfds) INDDS(ws)
     F                                     SFILE(MEISFL:@SRRN)
     F                                     SFILE(LISTSFL:@IRRN) 
      * サブプロシージャー定義
     DdrawDspGrid      PR
     D                                1    CONST
     D                                3P 0 CONST
     D                                3P 0 CONST
     D                                3P 0 CONST
      * ファイル情報データ構造
     Ddspfds           DS
     D  dsprow               152    153B 0
      * プログラム名の取得
     D                SDS
     D PGMNAM            *PROC
      * 名前付き標識
     Dws               DS                  QUALIFIED
     D  exit_03                        N   OVERLAY(ws : 3)
     D  list_04                        N   OVERLAY(ws : 4) 
     D  prev_07                        N   OVERLAY(ws : 7)
     D  next_08                        N   OVERLAY(ws : 8)
     D  cncl_12                        N   OVERLAY(ws : 12)
     D  sflDspCtlClr_31_32...
     D                                2    OVERLAY(ws : 31)
     D  dspDS3_40                      N   OVERLAY(ws : 40)
     D  errorMsg_50                    N   OVERLAY(ws : 50)
     D  dspDetail_60                   N   OVERLAY(ws : 60)
     D  lstDspCtlClr_90...
     D                                 N   OVERLAY(ws : 90)
      * その他変数
     D@SRRN            S              5P 0
     DoptCount         S                   LIKE(@SRRN)
     DworkRRN          S                   LIKE(@SRRN)
     DI                S                   LIKE(@SRRN)
     DJ                S                   LIKE(@SRRN)
      *********************
      * メインルーチン
      *********************

        EXSR #INIT; // 初期設定

        DOW (1 = 1);

          WRITE FOOTER; // フッター（機能キーガイド）
          EXFMT MIDASI; // 見出し（検索キー入力）レコード

          IF ws.exit_03; // F3= 終了
            LEAVE;
          ENDIF;
          ws.errorMsg_50 = *OFF;

          IF ws.list_04; // F4= リスト
            EXSR #LIST;
            IF ws.exit_03;
              ITER;
            ENDIF;
          ENDIF;

          IF KEY = *BLANKS; // 検索キー未入力
            ws.errorMsg_50 = *ON;
            MSGDTA = ' 検索条件（カナ）が未入力。 ';
            ITER;
          ENDIF;

          // サブファイル・レコードのセット
          EXSR #SETSF;

          // キーが合致するレコードが無い。
          IF RCDNUM = 0;
            ws.errorMsg_50 = *ON;
            MSGDTA = ' 一致するキーが見つからない。 ';
            ITER;
          ENDIF;

          // サブファイル表示
          ws.sflDspCtlClr_31_32 = '10'; // 31:SFLDSP/SFLDSPCTL, 32:SFLCLR
          @SPLOC = 1;                   // SFLRCDNBR
          ws.dspDetail_60 = *ON;        // 見出し表示切替
          ws.exit_03 = *OFF;
          ws.cncl_12 = *OFF;

          DOW (1 = 1);

            WRITE FOOTER; // フッター（機能キーガイド）
            WRITE MIDASI; // 見出し（検索キー入力）レコード
            // サブファイル・ヘッダー・レコード
            IF ws.dspDS3_40;
              WRITE HEADDS3; // 80X24 画面 (*DS3)
            ELSE;
              WRITE HEADDS4; // 132X27 画面 (*DS4)
            ENDIF;
            EXSR #DGRID;  // 画面罫線描画
            EXFMT MEICTL; // サブファイル制御レコード
            WRITE CLRGRD; // 画面罫線消去

            IF ws.exit_03 OR ws.cncl_12; // F3/12= 戻る
              LEAVE;
            ENDIF;
            ws.errorMsg_50 = *OFF;

            // サブファイル対話処理
            EXSR #SFLP;

            IF ws.exit_03 OR ws.cncl_12; // F3/12= 戻る
              LEAVE;
            ENDIF;

          ENDDO;
          ws.dspDetail_60 = *OFF;

        ENDDO;

        *INLR = *ON;
        RETURN;

        // サブルーチン

        // 初期設定  ///////////////////////////////////////
        BEGSR #INIT;

          // 表示装置の画面サイズの取得
          IF dsprow = 24 OR *INU8;
            @SSIZE = 9;  // 80X24 画面 (*DS3) の SFLSIZ  SFLPAG(8)
            ws.dspDS3_40 = *ON;
          ELSE;
            @SSIZE = 19; // 132X27 画面 (*DS4) の SFLSIZ SFLPAG(18)
            ws.dspDS3_40 = *OFF;
          ENDIF;

          // 検索リストサブファイルの作成
          ws.lstDspCtlClr_90 = *ON; // 90:SFLCLR
          WRITE LISTCTL;
          ws.lstDspCtlClr_90 = *OFF; // N90:SFLDSP SFLDSPCTL
          FOR @IRRN = 1 TO 45;
            ITEM = %SUBST(' ア  イ  ウ  エ  オ  カ  キ  ク  ケ  コ ' +
                          ' サ  シ  ス  セ  ソ  タ  チ  ツ  テ  ト ' +
                          ' ナ  ニ  ヌ  ネ  ノ  ハ  ヒ  フ  ヘ  ホ ' +
                          ' マ  ミ  ム  メ  モ  ヤ  ユ  ヨ ' +
                          ' ラ  リ  ル  レ  ロ  ワ  ヲ ' :
                          (@IRRN - 1) * 4 + 1 : 4);
            WRITE LISTSFL;
          ENDFOR;
        ENDSR;

        // 検索リストの表示（サブファイル・ウインドゥ） ////
        BEGSR #LIST;

          @CROW = 1; // カーソル位置の設定（行）
          @CCOL = 1; // 　　　　　　　　　（桁）
          // リストウインドゥの表示
          WRITE  LISTCTL; // 検索キーワードリスト
          WRITE  LISTF;   // 検索キーワードリストのフッター
          READ(E) LISTCTL;

          // サブファイル内で F3 （取消ボタン）の場合は何もしない
          IF ws.exit_03;
          // F3 以外 (ENTER) の場合、サブファイル行に対応した文字をセット
          ELSE;
            IF (1 <= @IRRN) AND (@IRRN <= 45); 
              KEY = %SUBST('ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜｦ' :
                           @IRRN : 1);
            // サブファイルレコード外で ENTER を押した場合は取消扱
            ELSE;
              ws.exit_03 = *ON;
            ENDIF;
          ENDIF;

        ENDSR;

        // サブファイルのセット ////////////////////////////
        BEGSR #SETSF;

          ws.sflDspCtlClr_31_32 = '01'; // 31:SFLDSP/SFLDSPCTL, 32:SFLCLR
          WRITE MEICTL; // サブファイルのクリア
          ws.sflDspCtlClr_31_32 = '10';

          // 変数の初期化
          @SRRN = 0;
          RCDNUM = 0;
          OPTION = ' ';

          // レコードの検索とサブファイルへの書出し
          SETLL KEY PERSONR;
          DOW (1 = 1);
            READ(E) PERSONR;
            // ファイルの終わり
            IF %EOF();
              LEAVE;
            ENDIF;
            // キー値と一致しない場合は終了
            IF %SUBST(KNNAME : 1 : %LEN(%TRIMR(KEY))) <> KEY;
              LEAVE;
            ENDIF;

            RCDNUM += 1;
            @SRRN += 1;
            EXSR #ATR;
            WRITE MEISFL;

            // 最大 100 件まで表示
            IF RCDNUM >= 100;
              LEAVE;
            ENDIF;
          ENDDO;

        ENDSR;

        // サブファイル対話処理 ////////////////////////////
        BEGSR #SFLP;

          // 変数の初期化
          ws.errorMsg_50 = *OFF;
          optCount = 0;
          workRRN = @SRRN;

          // サブファイルでの操作チェック
          FOR I = 1 TO RCDNUM;

            CHAIN(E) I MEISFL;
            IF %ERROR();
              LEAVE;
            ENDIF;

            SELECT;
              // オプションに 5 が指定→商品詳細表示（色を変更）
              WHEN OPTION = '5';
                optCount += 1;
                OPTION = ' '; // オプションのクリア
                UPDATE MEISFL;
                workRRN = @SRRN;
                EXSR #DSPDT; // レコード詳細ウインドゥ表示
                IF ws.exit_03; // F3 で詳細を抜けても最初の画面に戻さない
                  LEAVE;
                ENDIF;
              // オプションがブランク→そのまま更新
              WHEN OPTION = ' ';
                UPDATE MEISFL;
              // オプションに 5 とブランク以外→エラー
              OTHER;
                optCount += 1;
                ws.errorMsg_50 = *ON;
                MSGDTA = ' 詳細表示は ''5'' を指定。 ';
                OPTION = ' '; // オプションのクリア
                UPDATE MEISFL;
                workRRN = @SRRN;
                LEAVE;
            ENDSL;

          ENDFOR;

          // オプション未指定＆サブファイル上で ENTER →詳細表示
          // 　　　　　　　　　　　　　　　外で ENTER →前画面
          IF optCount = 0; // オプションがブランクのみ
            // カーソル行のデータを表示
            IF (0 < workRRN) AND (workRRN <= RCDNUM);
              CHAIN(E) workRRN MEISFL; 
              IF %FOUND();
                EXSR #DSPDT; // レコード詳細ウインドゥ表示
                @SPLOC = @SRRN;
              ENDIF;
            ELSE; // カーソルがサブファイル外
              ws.cncl_12 = *ON; // キャンセル（前画面）扱い
            ENDIF;

          ELSE; // オプションがブランク以外
            @SPLOC = workRRN;

          ENDIF;

          // F3 で詳細を抜けても最初の画面に戻さない
          IF ws.exit_03;
            ws.exit_03 = *OFF;
          ENDIF;

        ENDSR;

        // 詳細表示（ウインドゥ） //////////////////////////
        BEGSR #DSPDT;

          EXSR #ATR; // 表示色の設定

          // 再度データを読み込んで全詳細情報を取得
          CHAIN(E) REGNO PERSONR2;
          IF %FOUND();
            // 画像 URI の設定
            URIIMG = 'FILE://IBMI/IMG/' + %CHAR(REGNO) + '.JPG';
            // 地図 URL の設定
            URIWEB = 'https://www.google.co.jp/maps/place/' +
                     '%E9%83%B5%E4%BE%BF%E7%95%AA%E5%8F%B7%20' +
                     POST;
            EXFMT SYOSAI; // 詳細画面の表示
          // REGNO での CHAIN でエラー
          ELSE;
            CHAIN(E) workRRN MEISFL; // 再度サブファイルに CHAIN
            ws.errorMsg_50 = *ON;
            MSGDTA = ' レコードの読取でエラー。 ';
            OPTION = ' '; // オプションのクリア
            IF NOT %ERROR();
              UPDATE MEISFL;
            ENDIF;
            ws.exit_03 = *ON;
            workRRN = @SRRN;
          ENDIF;

        ENDSR;

        // 表示属性（プログラム－システム間フィールド）のセット
        BEGSR #ATR;

          SELECT;
            WHEN GENDER = 'M';
              @SATR1 = X'3A'; // 青
              @SATR2 = X'3E'; // 青下線
            WHEN GENDER = 'F';
              @SATR1 = X'22'; // 白
              @SATR2 = X'26'; // 白下線
            OTHER;
              @SATR1 = X'20'; // 緑
              @SATR2 = X'24'; // 緑下線
          ENDSL;

        ENDSR;

        // 画面罫線描画 ////////////////////////////////////
        BEGSR #DGRID;

          IF ws.dspDS3_40; // 80X24 画面 (*DS3)
            drawDspGrid('H' : 6 : 4 : 73);  // 水平線
            drawDspGrid('H' : 7 : 4 : 73);
            drawDspGrid('H' : 23 : 4 : 73);
            drawDspGrid('V' : 6 : 4 : 17);  // 縦線
            drawDspGrid('V' : 6 : 10 : 17);
            drawDspGrid('V' : 6 : 32 : 17);
            drawDspGrid('V' : 6 : 54 : 17);
            drawDspGrid('V' : 6 : 55 : 17);
            drawDspGrid('V' : 6 : 67 : 17);
            drawDspGrid('V' : 6 : 77 : 17);
          ELSE;            // 132X27 画面 (*DS4)
            drawDspGrid('H' : 6 : 4 : 122); // 水平線
            drawDspGrid('H' : 7 : 4 : 122);
            drawDspGrid('H' : 25 : 4 : 122);
            drawDspGrid('V' : 6 : 4 : 19);  // 縦線
            drawDspGrid('V' : 6 : 10 : 19);
            drawDspGrid('V' : 6 : 32 : 19);
            drawDspGrid('V' : 6 : 54 : 19);
            drawDspGrid('V' : 6 : 55 : 19);
            drawDspGrid('V' : 6 : 67 : 19);
            drawDspGrid('V' : 6 : 80 : 19);
            drawDspGrid('V' : 6 : 94 : 19);
            drawDspGrid('V' : 6 : 126 : 19);
          ENDIF;

        ENDSR;

      /END-FREE
      *
      *****************************************************************
      * 画面罫線描画サブプロシージャー /////////////////////
     PdrawDspGrid      B
     DdrawDspGrid      PI
     D  HorV                          1    CONST
     D  strLin                        3P 0 CONST
     D  strCol                             CONST LIKE(strLin)
     D  gridLen                            CONST LIKE(strLin)
      *
      /FREE
        IF HorV = 'H';
          @HGSL  = strLin;
          @HGSC  = strCol;
          @HGLEN = gridLen;
          WRITE HGRDR;
        ELSE;
          @VGSL  = strLin;
          @VGSC  = strCol;
          @VGLEN = gridLen;
          WRITE VGRDR;
        ENDIF;
      /END-FREE
      *
     PdrawDspGrid      E
