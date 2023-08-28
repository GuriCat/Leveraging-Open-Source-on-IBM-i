     FSPLF      UP   F  300        DISK
     ISPLF      AA  10
     I                                  1  300  SPLDATA
      *
     C     X'0E'         SCAN      SPLDATA:1     POS               3 0
     C     POS           DOWNE     0
     C                   EVAL      SPLDATA = %SUBST(SPLDATA:1:POS-1) + ' ' +
     C                                       %SUBST(SPLDATA:POS)
     C                   ADD       2             POS
     C     X'0E'         SCAN      SPLDATA:POS   POS
     C                   ENDDO
      *
     C     X'0F'         SCAN      SPLDATA:1     POS
     C     POS           DOWNE     0
     C                   EVAL      SPLDATA = %SUBST(SPLDATA:1:POS) + ' ' +
     C                                       %SUBST(SPLDATA:POS+1)
     C                   ADD       2             POS
     C     X'0F'         SCAN      SPLDATA:POS   POS
     C                   ENDDO
      *
     C                   MOVE      SPLDATA       SPLDATA2        299
      *
     OSPLF      D    10
     O                       SPLDATA2           299
