#include "Protheus.CH"
#include "rwmake.ch"
#include "tbiconn.ch"

#Define ENTER Chr(10)

//--------------------------------------------------------------------------------------------------------------------
/*/{PROTHEUS.DOC} MS520VLD
Esse ponto de entrada é chamado para validar ou não a exclusão da nota na rotina MATA521
@VERSION PROTHEUS 12
@SINCE 03/10/2024
@Historico
	03/10/2024 - Desenvolvimento (Elvis Siqueira)
/*/

User Function MS520VLD()
	Local aArea    := FWGetArea()
	Local aAreaSD2 := SD2->(GetArea())
	Local cCodCli  := SF2->F2_CLIENTE
	Local cLoja    := SF2->F2_LOJA
	Local cDoc     := SF2->F2_DOC
	Local cSerie   := SF2->F2_SERIE
	Local aMvPar   := {}
	Local nX
	
	Private lRet   := .T.
	
	For nX := 1 To 60
		aAdd( aMvPar, &( "MV_PAR" + StrZero( nX, 2, 0 ) ) )
	Next nX
	
	RptStatus({|| ExcBordero(cDoc, cSerie, cCodCli, cLoja)}, "Aguarde...", "Executando cancelamento do borderô...")
	
	For nX := 1 To Len( aMvPar )
		&( "MV_PAR" + StrZero( nX, 2, 0 ) ) := aMvPar[ nX ]
	Next nX
	
	RestArea(aAreaSD2)
	FWRestArea(aArea)

Return lRet

//--------------------------------------------------------------------------------------------------------------------
/*/{PROTHEUS.DOC} ExcBordero
Funcao para excluir o borderô gerado automaticamente na emissão da Nota Fiscal de Saída
@OWNER PanCristal
@VERSION PROTHEUS 12
@SINCE 28/05/2024
@Borderô automatico
/*/
Static Function ExcBordero(cDoc, cSerie, cCodCli, cLoja)
	Local aAreaSEA := SEA->(FWGetArea())
	Local cTmp     := "TMP"+FWTimeStamp(1)
	Local cFiltro  := ""
	Local aRegBor  := {}
	Local nCount   := 0
	Local cNumBor  := CriaVar("E1_NUMBOR", .F.)
	Local lRetFI2  := .F.

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	// -- Filtro SQL para para adicionar os titulos no borderô
	// -------------------------------------------------------
	cFiltro := "%" + "SE1.E1_FILIAL = '" + FWxFilial("SE1") + "'"
	cFiltro += " and SE1.E1_PREFIXO = '" + cSerie + "'"
	cFiltro += " and SE1.E1_NUM     = '" + cDoc + "'"
	cFiltro += " and SE1.E1_CLIENTE = '" + cCodCli + "'"
	cFiltro += " and SE1.E1_LOJA    = '" + cLoja + "'%"
	// --------------------------------------------------------

	If Select(cTmp) > 0
		(cTmp)->(dbCloseArea())
	EndIf

	BeginSQL Alias cTmp
		Select SE1.E1_PARCELA, SE1.E1_NUMBOR
		from %table:SE1% SE1
		where %exp:cFiltro%
			and SE1.E1_SALDO > 0
			and SE1.%NotDel%
	EndSQL

	If (cTmp)->(!Eof())
		cNumBor := (cTmp)->E1_NUMBOR
	End

	(cTmp)->(dbCloseArea())

	IF !Empty(cNumBor)
		aAdd(aRegBor, {"AUTNUMBOR"  , cNumBor })
		aAdd(aRegBor, {"AUTCANLIQ"  , .T.     })
	Else
		Return
	EndIF

	MsExecAuto({|a,b| FINA060(a,b)},4,aRegBor)

	If lMsErroAuto
		MostraErro()
	/*
	Else
		SetRegua(10)
		While nCount < 11 .And. !(lRetFI2)
			Sleep(5000)
			IncRegua()
			//F713Transf()
			lRetFI2 := CountFI2(cNumBor)
			nCount++
		End

		If nCount == 11 .And. !(lRetFI2)
			If FWAlertNoYes("Não foi possível cancelar o boleto automaticamente no banco, você deseja excluir manualmente através do portal do banco ?","Cancelamento Online")
				DBSelectArea("FI2")
				cFiltro := "%" + "FI2.FI2_FILIAL = '" + FWxFilial("FI2") + "'"
				cFiltro += " and FI2.FI2_CARTEI = '1' "
				cFiltro += " and FI2.FI2_BORAPI = 'S' "
				cFiltro += " and FI2.FI2_OPEAPI = 'C' "
				cFiltro += " and FI2.FI2_TRANSF IN ('F',' ') "
				cFiltro += " and FI2.FI2_NUMBOR = '" + cNumBor + "'%"
				If Select(cTmp) > 0
					(cTmp)->(dbCloseArea())
				EndIf

				BeginSQL Alias cTmp
					Select FI2.R_E_C_N_O_
					from %table:FI2% FI2
					where %exp:cFiltro%
						and FI2.%NotDel%
				EndSQL

				While (cTmp)->(!Eof())
					FI2->(DbGoTo((cTmp)->R_E_C_N_O_))
					RecLock("FI2",.F.)
					DbDelete()
					FI2->(MsUnLock())
					(cTmp)->(DbSkip())
				End
			EndIF
		EndIF
	*/
	EndIf

	FWRestArea(aAreaSEA)

Return
//------------------------------------------
/*/ Função CountFI2()
	Valida se o título foi cancelado no banco
/*/
//------------------------------------------
Static Function CountFI2(cNumBor)
	Local cTmp    := "TMP"+FWTimeStamp(1)
	Local lRetFI2 := .T.

	cFiltro := "%" + "FI2.FI2_FILIAL = '" + FWxFilial("FI2") + "'"
	cFiltro += " and FI2.FI2_CARTEI = '1' "
	cFiltro += " and FI2.FI2_BORAPI = 'S' "
	cFiltro += " and FI2.FI2_TRANSF IN ('F',' ') "
	cFiltro += " and FI2.FI2_NUMBOR = '" + cNumBor + "'%"
	If Select(cTmp) > 0
		(cTmp)->(dbCloseArea())
	EndIf

	BeginSQL Alias cTmp
		Select FI2.FI2_TRANSF
		from %table:FI2% FI2
		where %exp:cFiltro%
			and FI2.%NotDel%
	EndSQL

	While (cTmp)->(!Eof())
		lRetFI2 := .F.
		(cTmp)->(DbSkip())
	End

Return lRetFI2
