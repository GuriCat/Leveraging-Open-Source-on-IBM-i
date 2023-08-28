     H dftactgrp(*no)
     FGRDDSPF   CF   E             WORKSTN
      * pthread_delay_np()--Delay Thread for Requested Interval
      * ref : https://www.ibm.com/support/knowledgecenter/en/ssw_i5_54/apis/users_15.htm
     Ddelay            PR             5I 0 EXTPROC('pthread_delay_np')
     D                                 *   VALUE
      *
     DtimeSpec         DS
     D  seconds                      10I 0
     D  nanoseconds                  10I 0
      *
     Drc                              5I 0
     DI                               3P 0
      *
      /FREE
        seconds = 0;
        nanoseconds = 333333333;

        FOR I = 1 TO 3;
          // Draw horizontal lines
          HGRDSTRCOL = 10; // 開始桁
          HGRDLEN = 60;    // 罫線長
          FOR HGRDSTRLIN = 10 TO 20 BY 2; // 開始行
            WRITE HGRDR;
            rc = delay(%ADDR(timeSpec));
          ENDFOR;
          // Clear grid
          WRITE CLRGRD;
          // Draw virtical lines
          VGRDSTRLIN = 4;  // 開始行
          VGRDLEN = 12;    // 罫線長
          FOR VGRDSTRCOL = 2 TO 78 BY 8; // 開始桁
            WRITE VGRDR;
            rc = delay(%ADDR(timeSpec));
          ENDFOR;
          // Clear grid
          WRITE CLRGRD;
        ENDFOR;
        *INLR = *ON;
      /END-FREE
