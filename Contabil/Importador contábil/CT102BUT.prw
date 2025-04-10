#Include "TOTVS.CH"
#Include "rwmake.ch"
#Include "TbiConn.ch"
#Include "TopConn.ch"
#Include "Protheus.ch"
#include "fileio.ch"

/*/{Protheus.doc} CT102BUT

Ponto de Entrada que permite adicionar novos botões para o array arotina, 
no menu da mbrowse em lançamentos contábeis automáticos.

@type function
@author TOTVS NORDESTE
@since 31/05/2023

@history 
/*/
User Function CT102BUT()
Local aBotao  := {}
Local aOption := {}

  aAdd(aOption, {'Lançamentos Iniciais',"U_IMPTXT",   0 , 3    })
  aAdd(aBotao,{"Importação",aOption, 0, 1,0,NIL})

Return aBotao 

/*======================================================================
== Programa  ³MARHOT01  ºAutor  ³TOTVS NE         º Data ³  23/05/23  ==
==--------------------------------------------------------------------==
== Descrição ³Integração Protheus (Contabilidade).  			      ==
==           ³                                                        ==
==--------------------------------------------------------------------==
== Uso       ³Contabilidade                                           ==
==--------------------------------------------------------------------==
========================================================================*/
User Function IMPTXT	

Local aButtons 	:= {}
Local aSays    	:= {}
Local cTitulo	:= "Integração Protheus (Contabilidade)"
Local nOpcao 	:= 0

Private nErro   := 0

    AADD(aSays,OemToAnsi("Esta rotina irá importar arquivos .csv ou .txt, com os lançamentos contabéis,"))	
	AADD(aSays,OemToAnsi("para o Protheus - Contabilidade."))	
    AADD(aSays,"")
    AADD(aSays,OemToAnsi("Obs.: Os dados devem está separados por ponto e virgula."))
    AADD(aSays,OemToAnsi("      Exemplo: 003;01/01/1999;0101010101  ;01010101  ;01010101"))
    
    AADD(aButtons, { 1,.T.,{|o| nOpcao:= 1,o:oWnd:End()} } )
    AADD(aButtons, { 2,.T.,{|o| nOpcao:= 2,o:oWnd:End()} } )
    
    //Para mostrar uma mensagem na tela e as opções disponíveis para o usuário. (https://tdn.totvs.com/pages/viewpage.action?pageId=24346908)
    FormBatch( cTitulo, aSays, aButtons,,230,530 )

    if nOpcao == 1
        Processa({|| ExecBlock("JOBMAR01",.F.,.F.,{"01","X"}) }, "Integração Contabilidade PROTHEUS")
    endif

	If nErro > 0 
		FWAlertWarning('Gravação dos saldos contábeis finalizado com "Erros".')
	Else 
		FWAlertSuccess("Gravação dos saldos contábeis finalizado com sucesso.")
	EndIf 

Return

/*
========================================================================
== Programa  ³JOBPRMPT02  ºAutor  ³TOTVS NE         º Data ³ 23/05/23 ==
==--------------------------------------------------------------------==
== Descrição ³Rotina de integração RM x Protheus. (Contabilidade)     ==
==           ³                                                        ==
==--------------------------------------------------------------------==
== Uso       ³Financeiro                                              ==
==--------------------------------------------------------------------==
========================================================================*/
User Function JOBMAR01(_cEmp)
	Local aArea       := GetArea()
	Local aReg        := {}
	Local aRegAux     := {}
	Local aCab        := {}
	Local aItens      := {}
	Local nQtReg      := 0
	Local nQtLido     := 0
	Local nQtGrav     := 0
	Local nPer        := 0
	Local cMV_ATUSAL  := GetMv("MV_ATUSAL")
	Local cMV_CONTSB  := GetMv("MV_CONTSB")
	Local cMV_CONTBAT := GetMv("MV_CONTBAT")
	Local cMV_NUMLIN  := GetMv("MV_NUMLIN")
	Local cTexto	  := ""
	Local cLote       := ""
	Local dDataLanc   := STOD("")
	Local cLinha      := "000"
	Local nY 

	PutMv("MV_ATUSAL","N")
	PutMv("MV_CONTSB","S")
	PutMv("MV_CONTBAT","S")
	PutMv("MV_NUMLIN",99999)

	// --- Variaveis de Contabilização
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.

	cDiret	:= TFileDialog( "Arquivo CSV (*.csv) | Arquivos texto (*.txt)" ,,,, .F., /*GETF_MULTISELECT*/ )
	nHandle := FT_FUse(cDiret)

	If nHandle == -1
		MsgAlert("Operação Cancelada")
		Return
	EndIf

	ProcessMessages()

	nQtReg := FT_FLastRec()

	ProcRegua(nQtReg)

	While !FT_FEOF()
		nQtLido++
		nPer := (nQtLido / nQtReg) * 100
		IncProc("Lendo o Registro: " + Alltrim(Str(nQtLido)) + " de: " + Alltrim(Str(nQtReg)) + " (" + Alltrim(Str(nPer,6,2)) + "%)") //-- Incremeta Termometro

		cTexto := FT_FReadLn()

		If !Empty(cTexto)
			aRegAux := {}
			aRegAux := Separa(cTexto,";",.T.)

			aAdd(aReg,aRegAux)
			 
		EndIf 
		FT_FSKIP()
	EndDo

	ProcRegua(nQtReg)

	nPer := 0
	
	For nY := 1 To Len(aReg)
		nQtGrav++
		nPer := (nQtGrav / nQtReg) * 100
		IncProc("Gravando o Registro: " + Alltrim(Str(nQtGrav)) + " de: " + Alltrim(Str(nQtReg)) + " (" + Alltrim(Str(nPer,6,2)) + "%)") //-- Incremeta Termometro

		ProcessMessages()
			
			cLote  := aReg[nY,3]
			dDataLanc := CToD(aReg[nY,5])
			cLinha := Soma1(cLinha)

			aCab := ({{'DDATALANC'  , CToD(aReg[nY,5])  ,NIL},;
					  {'CLOTE'      , aReg[nY,3]        ,NIL},;
				      {'CSUBLOTE'   , '001'             ,NIL},;
					  {'CPADRAO'    , aReg[nY,2]        ,NIL},;
					  {'NTOTINF'    , 0                 ,NIL},;
					  {'NTOTINFLOT' , 0                 ,NIL}})
			aAdd(aItens,{;
						{'CT2_FILIAL' , IIF(Empty(aReg[nY,1]),FWxFilial("CT2"),aReg[nY,1]) , NIL},;
						{'CT2_LINHA'  , cLinha		 						               , NIL},;
						{'CT2_MOEDLC' , '01'		  						               , NIL},;
						{'CT2_DC'     , aReg[nY,4]  						               , NIL},;
						{'CT2_DEBITO' , aReg[nY,6]  						               , NIL},;
						{'CT2_CREDIT' , aReg[nY,7]  						               , NIL},;
						{'CT2_CCD'    , aReg[nY,8]  						               , NIL},;
						{'CT2_CCC'    , aReg[nY,9]  						               , NIL},;
						{'CT2_ITEMD'  , aReg[nY,10]  						               , NIL},;
						{'CT2_ITEMC'  , aReg[nY,11]  						               , NIL},;
						{'CT2_CLVLDB' , aReg[nY,12]  						               , NIL},;
						{'CT2_CLVLCR' , aReg[nY,13]  						               , NIL},;
						{'CT2_VALOR'  , Val(StrTran(aReg[nY,14], ",", "."))	               , NIL},;
						{'CT2_ORIGEM' , 'MSEXECAUT' 						               , NIL},;
						{'CT2_HP'     , aReg[nY,15]   						               , NIL},;
						{'CT2_HIST'   , aReg[nY,16] 						               , NIL}})

				IF (nY+1) < Len(aReg)
					If cLote != aReg[(nY+1),3] .OR. dDataLanc != CTOD(aReg[(nY+1),5])
						
						lMsErroAuto := .F. 
						MSExecAuto({|x, y,z| CTBA102(x,y,z)}, aCab ,aItens, 3)

						If lMsErroAuto
							lMsErroAuto := .F.
							nErro++
							MostraErro()
						EndIf

						aCab := {}
						aItens := {}
						cLinha := "000"

					EndIf 
				Else 
					
					lMsErroAuto := .F. 
					MSExecAuto({|x, y,z| CTBA102(x,y,z)}, aCab ,aItens, 3)

					If lMsErroAuto
						lMsErroAuto := .F.
						nErro++
						MostraErro()
					EndIf

					aCab := {}
					aItens := {}
					cLinha := "000"

				EndIF 

	Next nY 

	// ---- Retornar os parametros
	PutMv("MV_ATUSAL",cMV_ATUSAL)
	PutMv("MV_CONTSB",cMV_CONTSB)
	PutMv("MV_CONTBAT",cMV_CONTBAT)
	PutMv("MV_NUMLIN",cMV_NUMLIN)

	RestArea(aArea)

Return
