#Include "Protheus.ch"
#Include "TBICONN.CH"
#Include "TopConn.ch"

/*------------------------------------------------------------------------------------------------------*
 | P.E.:  M460FIM                                                                                       |
 | Desc:  Gravação dos dados após gerar NF de Saída                                                     |
 | Links: http://tdn.totvs.com/pages/releaseview.action?pageId=6784180                                  |
 *------------------------------------------------------------------------------------------------------*/

User Function M460FIM()
	Local aAreaSF2   := SF2->(FWGetArea())
	Local aAreaSA1   := SA1->(FWGetArea())
	Local aAreaSE1   := SE1->(FWGetArea())
	Local aAreaSC5   := SC5->(FWGetArea())
	Local _cAlias    := GetNextAlias()
	Local cQry       := ""
	Local aBancBOR 	 := Separa(SuperGetMV("MV_XBANCBO",.F.,""),";",.F.)
	Local lGeraBol	 := SuperGetMV("MV_XBOLETO",.F.,.F.)

	Default cBank   := IIF(Len(aBancBOR) == 4, PadR(aBancBOR[1],FWTamSX3("A6_COD")[1])     , PadR("",FWTamSX3("A6_COD")[1]))
    Default cAgenc  := IIF(Len(aBancBOR) == 4, PadR(aBancBOR[2],FWTamSX3("A6_AGENCIA")[1]) , PadR("",FWTamSX3("A6_AGENCIA")[1]))
    Default cContCC := IIF(Len(aBancBOR) == 4, PadR(aBancBOR[3],FWTamSX3("A6_NUMCON")[1] ) , PadR("",FWTamSX3("A6_NUMCON")[1]))
    Default cSubCC  := IIF(Len(aBancBOR) == 4, PadR(aBancBOR[4],FWTamSX3("EA_SUBCTA")[1])  , PadR("",FWTamSX3("EA_SUBCTA")[1]))
    Default lTela   := Nil 

    lTela := IIF(Empty(lTela),IIF(Len(aBancBOR) == 4 ,.T.,.F.),lTela) //Controla se o usuario deseja selecionar o banco para gerar o borderô

	DBSelectArea("SC5")

	cQry := " Select E1_CLIENTE, E1_LOJA, E1_PREFIXO, E1_NUM, E1_PARCELA, E1_TIPO, E1_VALOR from " + RetSqlName("SE1")
	cQry += "  where D_E_L_E_T_ <> '*'"
	cQry += "    and E1_FILIAL  = '" + xFilial("SE1") + "'"
	cQry += "    and E1_CLIENTE  = '" + SF2->F2_CLIENTE + "'"
	cQry += "    and E1_LOJA  = '" + SF2->F2_LOJA + "'"
	cQry += "    and E1_PREFIXO  = '" + SF2->F2_SERIE + "'"
	cQry += "    and E1_NUM  = '" + SF2->F2_DOC + "'"
	cQry := ChangeQuery(cQry)
	IF Select(_cAlias) <> 0
		(_cAlias)->(DBCloseArea())
	EndIf
	dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQry),_cAlias,.F.,.T.)
	
	While !(_cAlias)->(EOF())
		DBSelectArea("SE1")
		SE1->(DBSetOrder(1)) //E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
		SE1->(DBGoTop())
		If SE1->(MsSeek(xFilial("SE1")+(_cAlias)->E1_PREFIXO+(_cAlias)->E1_NUM+(_cAlias)->E1_PARCELA+(_cAlias)->E1_TIPO))
			cPedido := SE1->E1_PEDIDO
			IF SC5->(MsSeek(xFilial("SC5") + cPedido ))
				RecLock("SE1",.F.)
					SE1->E1_XFORMPG  := SC5->C5_XFORMPG
				SE1->(MsUnlock())
				IF lGeraBol
					lGeraBol := IIF(AllTrim(SC5->C5_XFORMPG) == 'BOL', .T., .F.)
				EndIF 
			EndIF 
		EndIf
		(_cAlias)->(DbSkip())
	EndDo

	IF Select(_cAlias) <> 0
		(_cAlias)->(DBCloseArea())
	EndIf

	
	//-----------------------------------------------------------------------------------------------------------
	//Monta borderô automaticamente
	If lGeraBol
		IF !lTela
			If FWAlertYesNo("Deseja informar o banco para geração do borderô?","Banco Borderô")
			u_fnSelBanc()
			EndIF
		EndIF 

		IF !Empty(cBank) .and. !Empty(cAgenc) .and. !Empty(cContCC) .and. !Empty(cSubCC)
			u_fnGerBor(Nil,cBank,cAgenc,cContCC,cSubCC,lTela) //Gera o borderô
		EndIF
	EndIF
	//-----------------------------------------------------------------------------------------------------------

	FWRestArea(aAreaSF2)
	FWRestArea(aAreaSA1)
	FWRestArea(aAreaSE1)
	FWRestArea(aAreaSC5)

Return
