                    MEMBER()
!----------------------------------------------------------------------------
! BigBangSystemString - View SystemStringClass Lines Queue and Optionally Split lines by Delimeter
! (c)2020 by Carl T. Barnes - Released under the MIT License
!----------------------------------------------------------------------------
    INCLUDE('KEYCODES.CLW')
    INCLUDE('BigBangSystemString.INC'),ONCE
  MAP
  END
!----------------------------------------------------------------------
BigBangSystemString.LinesViewInList PROCEDURE(SystemStringClass LnzST) 
VlbLines CLASS
FEQ    LONG
RowCnt LONG 
ClmCnt USHORT
Init   PROCEDURE(SIGNED xFEQ, LONG xRowCnt, USHORT xClmCnt)!  ,VIRTUAL !<-- cannot because Address(Self) in Init is always VlbCls. Maybe if this was TYPE
VLBprc PROCEDURE(LONG xRow, USHORT xCol),STRING
      END 
Window WINDOW('VLB'),AT(,,450,200),GRAY,SYSTEM,MAX,FONT('Segoe UI',9),RESIZE
        LIST,AT(1,2),FULL,USE(?List:LinesQ),FLAT,HVSCROLL,VCR,FORMAT('24R(2)|M~Row~C(0)@n_6@999L(2)~Lines Q~')
    END
X USHORT,AUTO
P USHORT,AUTO
LnzRecords LONG,AUTO
    CODE
  LnzRecords = LnzST.CountLines()
  IF ~LnzRecords THEN Message('No Lines in Loaded file','LinesViewInList') ; RETURN .
  OPEN(Window)
  ?List:LinesQ{PROP:LineHeight}=1+?List:LinesQ{PROP:LineHeight}
  ?List:LinesQ{7A58h}=1  !C11 PROP:PropVScroll
  0{PROP:Text}='SystemString Lines View - '& LnzRecords & ' Records  -  Right-Click for Options' ! - ' & LoadFile
  X=LOG10(LnzRecords)+1 ; IF X<4 THEN X=4.
  ?List:LinesQ{PROPLIST:Picture,1}='n' & X
  ?List:LinesQ{PROPLIST:Width,1}  =2 + 4*X
  VlbLines.Init(?List:LinesQ, LnzRecords, 2)
  ACCEPT
    IF EVENT()=EVENT:NewSelection AND FIELD()=?List:LinesQ AND KEYCODE()=MouseRight THEN
       SETKEYCODE(0)
       X=CHOICE(?List:LinesQ)
       CASE POPUP('Copy Row to Clipboard|View Row Text|-|Copy All Rows Text')
       OF 1 ; SetClipboard(LnzST.GetLineValue(X))
       OF 2 ; MESSAGE(LnzST.GetLineValue(X),'Row ' & X,,,,MSGMODE:CANCOPY) 
       OF 3 ; SetClipboard(LnzST.Str())
       END
    END
    CASE ACCEPTED()
    END
  END
  CLOSE(Window)
  RETURN 
!----------------------  
VlbLines.Init PROCEDURE(SIGNED xFEQ, LONG xRowCnt, USHORT xClmCnt)
  CODE
  SELF.FEQ=xFEQ 
  SELF.RowCnt=xRowCnt
  SELF.ClmCnt=xClmCnt
  xFEQ{PROP:VLBval} =ADDRESS(SELF) 
  xFEQ{PROP:VLBproc}=ADDRESS(SELF.VLBprc)
  RETURN
VlbLines.VLBprc PROCEDURE(LONG xRow, USHORT xCol)
Chg LONG,AUTO
  CODE
  CASE xRow
  OF -1 ; RETURN SELF.RowCnt !Rows
  OF -2 ; RETURN SELF.ClmCnt !Columns
  OF -3 ; RETURN False
  END
  IF xCol=1 THEN RETURN xRow.
  RETURN LnzST.GetLineValue(xRow)
!================================================================================= 
BigBangSystemString.LinesViewSplitCSV   PROCEDURE(SystemStringClass STLined, BYTE pRemoveQuotes)  
    CODE 
    SELF.LinesViewSplit(STLined,',','"','"',pRemoveQuotes)
BigBangSystemString.LinesViewSplitTAB   PROCEDURE(SystemStringClass STLined) 
    CODE 
    SELF.LinesViewSplit(STLined,CHR(9),'','',False)
BigBangSystemString.LinesViewSplit   PROCEDURE(SystemStringClass STLined, string CsvDelim)
    CODE
    SELF.LinesViewSplit(STLined,CsvDelim,'','')
BigBangSystemString.LinesViewSplit PROCEDURE(SystemStringClass CsvST, string CsvDelim,string CsvQuoteStart,string CsvQuoteEnd, BYTE pRemoveQuotes) 
    MAP
LinSTfromCsvST PROCEDURE(LONG xRow2Load)   !Has lines specs eg. delimeter may not be Comma 
ViewColumns    PROCEDURE()
    END 
VlbCls CLASS !From Mark Goldberg, but I hacked it to death
FEQ    LONG
RowCnt LONG 
ClmCnt USHORT
Chgs   LONG
Init   PROCEDURE(SIGNED xFEQ, LONG xRowCnt, USHORT xClmCnt)!  ,VIRTUAL !<-- cannot because Address(Self) in Init is always VlbCls. Maybe if this was TYPE
VLBprc PROCEDURE(LONG xRow, USHORT xCol),STRING
Contrt PROCEDURE(USHORT ColWd=24)
Expand PROCEDURE()
      END
X USHORT,AUTO
P USHORT,AUTO
Fmt ANY
PColumn USHORT
Picture STRING(32)
Window WINDOW('VLB'),AT(,,450,200),GRAY,SYSTEM,MAX,FONT('Segoe UI',9),RESIZE
        BUTTON('&Menu'),AT(2,2,25,12),USE(?MenuBtn),SKIP
        BUTTON('View Lines'),AT(40,2,,12),USE(?LinesBtn),SKIP,TIP('Display raw lines') 
        STRING('Picture Column:'),AT(173,3,55),USE(?Pict:Pmt),RIGHT
        COMBO(@s32),AT(233,3,59,10),USE(Picture),DISABLE,VSCROLL,TIP('Change Picture for Column'), |
                DROP(16),FROM('@D1|@D2|@D3|@D17|@N11.2|@S255|@T1|@T3|@T4|@T8')
        LIST,AT(1,17),FULL,USE(?List:VLB),HVSCROLL,COLUMN,VCR,FORMAT('40L(2)|M~Col1~Q''NAME'''),FLAT
    END                 
LinST SystemStringClass
CsvRecords LONG,AUTO 
ColCount LONG,AUTO 
CsvST_GotRow LONG
    CODE
  CsvRecords = CsvST.CountLines()
  IF ~CsvRecords THEN Message('No Lines in Loaded file','LinesViewSplitInListVLB') ; RETURN .
  LinSTfromCsvST(1) 
  ColCount = LinST.CountLines()  !Assume 1st line has all columns. Pass columns?
  LOOP X=1 TO ColCount           !Assume first row has labels 
    Fmt=Fmt&'40L(2)|M~' & X & '. <13,10>'& CLIP(SUB(LinST.GetLineValue(X),1,30)) &'~' 
  END
  OPEN(Window)
  ?List:VLB{PROP:Format}=Fmt ; CLEAR(Fmt) 
  ?List:VLB{PROP:LineHeight}=1+?List:VLB{PROP:LineHeight} 
  ?List:VLB{7A58h}=1  !C11 PROP:PropVScroll
  ?Pict:Pmt{PROP:Tip}='Right click on cell to change the Picture'
  0{PROP:Text}='SystemString View - '& CsvRecords & ' Records - '& ColCount &' Columns  -  Right-Click for Options' ! - ' & LoadFile
  VlbCls.Init(?List:VLB, CsvRecords, ColCount)
  ACCEPT
    IF EVENT()=EVENT:NewSelection AND FIELD()=?List:VLB AND KEYCODE()=MouseRight THEN
       SETKEYCODE(0)
       X=?List:VLB{PROPLIST:MouseDownField} 
       EXECUTE POPUP('Copy Cell to Clipboard|View Cell Text|-|Copy Row to Clipboard|View Row Line Text|View Row Split...|-|Hide Column ' & X &'|Change @ Picture' & |
                  '|Column Alignment{{Left|Center|Right}')
        SETCLIPBOARD(LinST.GetLineValue(X))    !Correct? 
        MESSAGE(LinST.GetLineValue(X),'Column  ' & X & ' in Row ' & CsvST_GotRow,,,,MSGMODE:CANCOPY) 
        SetClipboard(CsvST.GetLineValue(CsvST_GotRow)) 
        MESSAGE(CsvST.GetLineValue(CsvST_GotRow),'Row ' & CsvST_GotRow,,,,MSGMODE:CANCOPY) 
        ViewColumns()
        BEGIN ; ?List:VLB{PROPLIST:width,X}=0 ; IF X=PColumn THEN DISABLE(?Picture). ; END
        BEGIN ; Picture=?List:VLB{PROPLIST:Picture,X} ; ?Pict:Pmt{PROP:Text}='&Picture Col ' & X & ':'
                ENABLE(?Picture) ; SELECT(?Picture) ; PColumn=X ; END
        ?List:VLB{PROPLIST:Left,X}=1
        ?List:VLB{PROPLIST:Center,X}=1
        ?List:VLB{PROPLIST:Right,X}=1
       END
    END
    CASE ACCEPTED()
    OF ?MenuBtn
        EXECUTE POPUP('Copy All to Clipboard|-|Contract Column Widths|Expand Column Widths' & |
                        '|-|Copy VLB Format String') 
         SETCLIPBOARD(CsvST.Str()) 
         VlbCls.Contrt()
         VlbCls.Expand()
         SETCLIPBOARD(?List:VLB{PROP:Format})
        END 
    OF ?LinesBtn ; SELF.LinesViewInList(CsvST)
    OF ?Picture ; ?List:VLB{CHOOSE(~INSTRING(lower(picture[1:2]),'@d@t@n@e'),PROPLIST:Left,PROPLIST:Right) ,PColumn}=1
                  ?List:VLB{PROPLIST:Picture,PColumn}=Picture ; DISPLAY 
    END
  END
  CLOSE(Window)
  RETURN 
!------------------------------------------  
LinSTfromCsvST PROCEDURE(LONG xRow)    !So all Row Split in one place 
  CODE
  IF xRow <> CsvST_GotRow THEN   
    CsvST_GotRow = xRow
    LinST.FromString(CsvST.GetLineValue(xRow))
    LinST.Split(CsvDelim,True) !,CsvQuoteStart,CsvQuoteEnd,pRemoveQuotes)
  END
  RETURN
ViewColumns PROCEDURE()
ColST SystemStringClass
  CODE
  ColST.FromString(CsvST.GetLineValue(CsvST_GotRow))
  ColST.Split(CsvDelim,True) !,CsvQuoteStart,CsvQuoteEnd,pRemoveQuotes)  
  SELF.LinesViewInList(ColST)
  RETURN
VlbCls.Init PROCEDURE(SIGNED xFEQ, LONG xRowCnt, USHORT xClmCnt)
  CODE
  SELF.FEQ=xFEQ 
  SELF.RowCnt=xRowCnt
  SELF.ClmCnt=xClmCnt
  xFEQ{PROP:VLBval} =ADDRESS(SELF) 
  xFEQ{PROP:VLBproc}=ADDRESS(SELF.VLBprc)    
  RETURN
VlbCls.VLBprc PROCEDURE(LONG xRow, USHORT xCol)
Chg LONG,AUTO
  CODE
  CASE xRow
  OF -1 ; RETURN SELF.RowCnt !Rows
  OF -2 ; RETURN SELF.ClmCnt !Columns
  OF -3 ; RETURN False 
  END
  IF xRow <> CsvST_GotRow THEN
    LinSTfromCsvST(xRow) 
  END 
  RETURN LinST.GetLineValue(xCol)
VlbCls.Contrt PROCEDURE(USHORT ColWd)
  CODE 
  LOOP X=1 TO SELF.ClmCnt 
       IF SELF.FEQ{PROPLIST:Width,X}>0 THEN SELF.FEQ{PROPLIST:Width,X}=ColWd. 
  END ; DISPLAY
VlbCls.Expand PROCEDURE()
  CODE 
  SELF.Contrt(SELF.FEQ{PROP:Width}/SELF.ClmCnt)