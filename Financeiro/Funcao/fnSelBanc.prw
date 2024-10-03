#Include "PROTHEUS.ch"
#Include "FWMVCDef.ch"
#Include "TopConn.CH"

// ---------------------------------------------------------------------------
/*/ Rotina fnSelBanc
  
  Função responsável por selecionar banco para geração do borderô automatico.

  Retorno
  @historia
  21/03/2024 - Desenvolvimento da Rotina.
/*/
// ---------------------------------------------------------------------------
User Function fnSelBanc()

  Local aCampos := {}

  Private aButtons := {{.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.T.,"Confirmar"},;
                       {.T.,"Fechar"},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil},;
                       {.F.,Nil}}

 // -- Criar tabela temporária
 // -- Cabeçalho
 // --------------------------
  aAdd(aCampos,{"T1_CODCLI" ,FWTamSX3("A1_COD" )[3],FWTamSX3("A1_COD" )[1],FWTamSX3("A1_COD")[2] })
  aAdd(aCampos,{"T1_LOJACLI",FWTamSX3("A1_LOJA")[3],FWTamSX3("A1_LOJA")[1],FWTamSX3("A1_LOJA")[2]})
  aAdd(aCampos,{"T1_NOMECLI",FWTamSX3("A1_NOME")[3],FWTamSX3("A1_NOME")[1],FWTamSX3("A1_NOME")[2]})
  aAdd(aCampos,{"T1_NOTAS"  ,"L",1,0})

  oTempTRB1 := FWTemporaryTable():New("TRB1")
  oTempTRB1:SetFields(aCampos)
  oTempTRB1:AddIndex("01",{"T1_CODCLI","T1_LOJACLI","T1_NOTAS"})
  oTempTRB1:Create()

  aCampos := {}

  aAdd(aCampos,{"T2_CODBCO" ,FWTamSX3("A6_COD"    )[3],FWTamSX3("A6_COD"    )[1],FWTamSX3("A6_COD")[2]    })
  aAdd(aCampos,{"T2_NOMBCO" ,FWTamSX3("A6_NOME"   )[3],FWTamSX3("A6_NOME"   )[1],FWTamSX3("A6_NOME")[2]   })
  aAdd(aCampos,{"T2_AGENCIA",FWTamSX3("A6_AGENCIA")[3],FWTamSX3("A6_AGENCIA")[1],FWTamSX3("A6_AGENCIA")[2]})
  aAdd(aCampos,{"T2_DVAGE"  ,FWTamSX3("A6_DVAGE"  )[3],FWTamSX3("A6_DVAGE"  )[1],FWTamSX3("A6_DVAGE")[2]  })
  aAdd(aCampos,{"T2_NUMCON" ,FWTamSX3("A6_NUMCON" )[3],FWTamSX3("A6_NUMCON" )[1],FWTamSX3("A6_NUMCON")[2] })
  aAdd(aCampos,{"T2_DVCTA"  ,FWTamSX3("A6_DVCTA"  )[3],FWTamSX3("A6_DVCTA"  )[1],FWTamSX3("A6_DVCTA")[2]  })
  aAdd(aCampos,{"T2_SUBCTA" ,FWTamSX3("EA_SUBCTA" )[3],FWTamSX3("EA_SUBCTA" )[1],FWTamSX3("EA_SUBCTA")[2] })

  oTempTRB2 := FWTemporaryTable():New("TRB2")
  oTempTRB2:SetFields(aCampos)
  oTempTRB2:AddIndex("01",{"T2_CODBCO","T2_AGENCIA","T2_NUMCON"})
  oTempTRB2:Create()

  FWExecView("Selecionar Banco","FNSELBANC",MODEL_OPERATION_INSERT,,{|| .T.},,20,aButtons)

  oTempTRB1:Delete() 
  oTempTRB2:Delete() 
Return

// -----------------------------------------
/*/ Função ModelDef

   Define as regras de negocio.

  @author Totvs Nordeste
  Return
/*/
// -----------------------------------------
Static Function ModelDef() 
  Local oModel
  Local oStrTRB1 := fnM01TB1()
  Local oStrTRB2 := fnM01TB2()
  
  oModel := MPFormModel():New("Selecionar Banco",,,{|oModel| u_fnGerBor(oModel)})  

  oModel:SetDescription("Selecionar Banco")    
  oModel:AddFields("MSTCAB",,oStrTRB1)
  
  oModel:AddGrid("DETBCO","MSTCAB",oStrTRB2)

  oModel:SetPrimaryKey({""})
  
Return oModel

// -----------------------------------------
/*/ Função fnGerBor

   Gerar Bordero.

  @author Totvs Nordeste
  Return
/*/
// -----------------------------------------
User Function fnGerBor(oModel,cBanco,cAgenc,cConta,cSubCC,lTela)
  Local lRet    := .T.
  Local oGrdCab := IIF(ValType(oModel) == "O",oModel:GetModel("MSTCAB"),Nil)
  Local oGrdBco := IIF(ValType(oModel) == "O",oModel:GetModel("DETBCO"),Nil)
  Local cTmp    := GetNextAlias()
  Local cFiltro := ""
  Local cNumBor := ""
  Local cEspec  := ""  
  Local aRegTit := {}
  Local aRegBor := {}

  Private lMsErroAuto    := .F.
  Private lMsHelpAuto    := .T.
  Private lAutoErrNoFile := .T.

  Default cBanco    := PadR("",FWTamSX3("A6_COD")[1])
  Default cAgenc    := PadR("",FWTamSX3("A6_AGENCIA")[1])
  Default cConta    := PadR("",FWTamSX3("A6_NUMCON")[1])
  Default cSubCC    := PadR("",FWTamSX3("EA_SUBCTA")[1])
  Default lTela     := .F.
  Default aTitM460  := {}

  If Len(aTitM460) > 0
    aRegTit := aClone(aTitM460)
  Else
    // -- Filtro SQL para para adicionar os titulos no borderô
    // -------------------------------------------------------
      cFiltro := "%" + "SE1.E1_FILIAL = '" + FWxFilial("SE1") + "'"
      cFiltro += " and SE1.E1_PREFIXO = '" + SF2->F2_SERIE + "'"
      cFiltro += " and SE1.E1_NUM = '" + SF2->F2_DOC + "'%"
    // --------------------------------------------------------

      If Select(cTmp) > 0
        (cTmp)->(dbCloseArea())
      EndIf

      BeginSQL Alias cTmp
        Select SE1.E1_FILIAL, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO
          from %table:SE1% SE1
          where %exp:cFiltro%
            and SE1.E1_SALDO > 0
            and SE1.%NotDel%
      EndSQL

      While ! (cTmp)->(Eof())
        aAdd(aRegTit,{{"E1_FILIAL" , (cTmp)->E1_FILIAL},;
                      {"E1_PREFIXO", (cTmp)->E1_PREFIXO},;
                      {"E1_NUM"    , (cTmp)->E1_NUM},;
                      {"E1_PARCELA", (cTmp)->E1_PARCELA},;
                      {"E1_TIPO"   , (cTmp)->E1_TIPO}})

        (cTmp)->(dbSkip())
      EndDo

      (cTmp)->(dbCloseArea())

      If Empty(aRegTit)
        Return lRet
      EndIf
  EndIF 

 // -- Informações bancárias para o borderô
 // ---------------------------------------
  
  If Valtype(oGrdCab) == "O" .AND. Valtype(oGrdBco) == "O"

    lTela  := oGrdCab:GetValue("T1_NOTAS")
    cBanco := PadR(oGrdBco:GetValue("T2_CODBCO"),FWTamSX3("A6_COD")[1])
    cAgenc := PadR(oGrdBco:GetValue("T2_AGENCIA"),FWTamSX3("A6_AGENCIA")[1])
    cConta := PadR(oGrdBco:GetValue("T2_NUMCON"),FWTamSX3("A6_NUMCON")[1])
    cSubCC := PadR(oGrdBco:GetValue("T2_SUBCTA"),FWTamSX3("EA_SUBCTA")[1])

  EndIF 

  DBSelectArea("F77")
  IF F77->(MsSeek(FWxFilial("F77")+cBanco))
    While ! F77->(Eof()) .AND. F77->F77_BANCO == cBanco
      If F77->F77_SIGLA == PadR('DM',FWTamSX3("F77_SIGLA")[1]) 
        cEspec := F77->F77_ESPECI
        Exit
      EndIF 
      F77->(DBSkip())
    End 
  EndIf 

  aAdd(aRegBor, {"AUTBANCO"   , cBanco})
  aAdd(aRegBor, {"AUTAGENCIA" , cAgenc})
  aAdd(aRegBor, {"AUTCONTA"   , cConta})
  aAdd(aRegBor, {"AUTSITUACA" , PadR("1",FWTamSX3("E1_SITUACA")[1])})
  aAdd(aRegBor, {"AUTNUMBOR"  , PadR(cNumBor,FWTamSX3("E1_NUMBOR")[1])}) // Caso não seja passado o número será obtido o próximo pelo padrão do sistema
  aAdd(aRegBor, {"AUTSUBCONTA", cSubCC})
  aAdd(aRegBor, {"AUTESPECIE" , cEspec})
  aAdd(aRegBor, {"AUTBOLAPI"  , .T.})

  MsExecAuto({|a,b| FINA060(a,b)},3,{aRegBor, aRegTit})

  If lMsErroAuto
    MostraErro()
  Else
    //F713Transf()
  EndIf

Return lRet
 
//-------------------------------------
/*/ Função fnM01TB1()

  Estrutura do detalhe do cabeçalho.					  

/*/
//--------------------------------------
Static Function fnM01TB1()
  Local oStruct := FWFormModelStruct():New()
 
  oStruct:AddTable("TRB1",{"T1_NOTAS"},"Todas as Notas ?")
  oStruct:AddField("Todas as Notas ?","Todas as Notas ?","T1_NOTAS","L",1,0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Cliente","Cliente","T1_CODCLI",FWTamSX3("A1_COD")[3],FWTamSX3("A1_COD")[1],FWTamSX3("A1_COD")[2],Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Loja","Loja","T1_LOJACLI",FWTamSX3("A1_LOJA")[3],FWTamSX3("A1_LOJA")[1],FWTamSX3("A1_LOJA")[2],Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Nome","Nome","T1_NOMECLI",FWTamSX3("A1_NOME")[3],FWTamSX3("A1_NOME")[1],FWTamSX3("A1_NOME")[2],Nil,Nil,{},.F.,,.F.,.F.,.F.)

Return oStruct

//-------------------------------------
/*/ Função fnM01TB2()

  Estrutura do detalhe dos campos.							  

/*/
//--------------------------------------
Static Function fnM01TB2()
  Local oStruct := FWFormModelStruct():New()
 
  oStruct:AddTable("TRB2",{"T2_CODBCO","T2_AGENCIA","T2_NUMCON"},"Bancos")
  oStruct:AddField("Banco"    ,"Banco"    ,"T2_CODBCO" ,"C",FWTamSX3("A6_COD")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Nome"     ,"Nome"     ,"T2_NOMBCO" ,"C",FWTamSX3("A6_NOME")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Agência"  ,"Agência"  ,"T2_AGENCIA","C",FWTamSX3("A6_AGENCIA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Dig. Ag." ,"Dig. Ag." ,"T2_DVAGE"  ,"C",FWTamSX3("A6_DVAGE")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Conta"    ,"Conta"    ,"T2_NUMCON" ,"C",FWTamSX3("A6_NUMCON")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("Dig. Cta" ,"Dig. Cta" ,"T2_DVCTA"  ,"C",FWTamSX3("A6_DVCTA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
  oStruct:AddField("SubConta" ,"SubConta" ,"T2_SUBCTA" ,"C",FWTamSX3("EE_SUBCTA")[1],0,Nil,Nil,{},.F.,,.F.,.F.,.F.)
Return oStruct

//-------------------------------------------------------------------
/*/ Função ViewDef()
  
  Definição da View

/*/
//-------------------------------------------------------------------
Static Function ViewDef() 
  Local oModel   := ModelDef() 
  Local oStrTRB1 := fnV01TB1()
  Local oStrTRB2 := fnV01TB2()
  Local oView

  oView := FWFormView():New() 
   
  oView:SetModel(oModel)    
  oView:AddField("FCAB",oStrTRB1,"MSTCAB") 
  oView:AddGrid("FDET",oStrTRB2,"DETBCO") 

 // --- Definição da Tela
 // ---------------------
  oView:CreateHorizontalBox("BXCAB",20)
  oView:CreateHorizontalBox("BXDET",80)  

 // --- Definição dos campos
 // ------------------------    
  oView:SetOwnerView("FCAB","BXCAB")
  oView:SetOwnerView("FDET","BXDET")

  oView:SetViewAction("ASKONCANCELSHOW",{|| .F.})           // Tirar a mensagem do final "Há Alterações não..."
  oView:SetAfterViewActivate({|oView| fnLerBco(oView)})    // Carregar dados antes de montar a tela
  oView:ShowInsertMsg(.F.)
Return oView

//-------------------------------------------
/*/ Função fnV01TB1

  Estrutura do detalhe do Cabeçalho (View)
  						  
/*/
//-------------------------------------------
Static Function fnV01TB1()
  Local oViewTB1 := FWFormViewStruct():New() 

 // -- Montagem Estrutura
 //      01 = Nome do Campo
 //      02 = Ordem
 //      03 = Título do campo
 //      04 = Descrição do campo
 //      05 = Array com Help
 //      06 = Tipo do campo
 //      07 = Picture
 //      08 = Bloco de PictTre Var
 //      09 = Consulta F3
 //      10 = Indica se o campo é alterável
 //      11 = Pasta do Campo
 //      12 = Agrupamnento do campo
 //      13 = Lista de valores permitido do campo (Combo)
 //      14 = Tamanho máximo da opção do combo
 //      15 = Inicializador de Browse
 //      16 = Indica se o campo é virtual (.T. ou .F.)
 //      17 = Picture Variavel
 //      18 = Indica pulo de linha após o campo (.T. ou .F.)
 // --------------------------------------------------------
  oViewTB1:AddField("T1_NOTAS"  ,"01","Todas as Notas ?","Todas as Notas ?",Nil,"L","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB1:AddField("T1_CODCLI" ,"02","Cliente","Cliente",Nil,"C","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB1:AddField("T1_LOJACLI","03","Loja","Loja",Nil,"C","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB1:AddField("T1_NOMECLI","04","Nome","Nome",Nil,"C","@!",Nil,"",.T.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB1

//-------------------------------------------
/*/ Função fnV01TB2

  Estrutura do detalhe do Grid (View)
  						  
/*/
//-------------------------------------------
Static Function fnV01TB2()
  Local oViewTB2 := FWFormViewStruct():New() 

  oViewTB2:AddField("T2_CODBCO" ,"01","Banco"    ,"Banco"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_NOMBCO" ,"02","Nome"     ,"Nome"     ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_AGENCIA","03","Agência"  ,"Agência"  ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_DVAGE"  ,"04","Dig. Age.","Dig. Age.",Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_NUMCON" ,"05","Conta"    ,"Conta"    ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_DVCTA"  ,"06","Dig. Cta" ,"Dig. Cta" ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
  oViewTB2:AddField("T2_SUBCTA" ,"07","SubConta" ,"SubConta" ,Nil,"C","@!",Nil,"",.F.,Nil,Nil,Nil,Nil,Nil,.F.,Nil,Nil)
Return oViewTB2

//-------------------------------------------------
/*/ Função fnLerBco

  Carregar os possíveis bancos para envie Boleto.

  @Parâmetro: oView = Objecto View

/*/
//--------------------------------------------------
Static Function fnLerBco(oView)
  Local oModel  := FwModelActive()
  Local oCabTB1 := oModel:GetModel("MSTCAB")
  Local oGrdTB2 := oModel:GetModel("DETBCO")
  Local cQuery  := ""

  oCabTB1:SetValue("T1_CODCLI" , SF2->F2_CLIENTE)
  oCabTB1:SetValue("T1_LOJACLI", SF2->F2_LOJA)
  oCabTB1:SetValue("T1_NOMECLI", Posicione("SA1",1,FWxFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME"))
  oCabTB1:SetValue("T1_NOTAS"  , .T.)

  cQuery := "Select SA6.A6_COD, SA6.A6_NOME, SA6.A6_AGENCIA, SA6.A6_DVAGE, SA6.A6_NUMCON, SA6.A6_DVCTA,"
  cQuery += "       SEE.EE_SUBCTA"
  cQuery += "  from " + RetSqlName("SA6") + " SA6, " + RetSqlName("SEE") + " SEE"
  cQuery += "   where SA6.D_E_L_E_T_ <> '*'"
  cQuery += "     and SA6.A6_FILIAL  = '" + FWxFilial("SA6") + "'"
  cQuery += "     and SA6.A6_CFGAPI IN ('1','3')"
  cQuery += "     and SA6.A6_BCOOFI  <> ''" 
  cQuery += "     and SEE.D_E_L_E_T_ <> '*'"
  cQuery += "     and SEE.EE_FILIAL  = '" + FWxFilial("SEE") + "'"
  cQuery += "     and SEE.EE_CODIGO  = SA6.A6_COD"
  cQuery += "     and SEE.EE_AGENCIA = SA6.A6_AGENCIA"
  cQuery += "     and SEE.EE_DVAGE   = SA6.A6_DVAGE"
  cQuery += "     and SEE.EE_CONTA   = SA6.A6_NUMCON"
  cQuery += "     and SEE.EE_DVCTA   = SA6.A6_DVCTA"
  cQuery += "  Order by SA6.A6_COD"
  cQuery := ChangeQuery(cQuery)
  dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"QSA6",.F.,.T.)      
  
  If QSA6->(Eof())
     Help(,,"HELP",,"Não existe banco configurado para emissão de boletos.",1,0)

     QSA6->(dbCloseArea())

     Return
  EndIf

  oGrdTB2:SetNoInsertLine(.F.)
  oGrdTB2:SetNoDeleteLine(.F.)
  oGrdTB2:SetNoUpdateLine(.F.)

  While ! QSA6->(Eof())
     oGrdTB2:AddLine()

     oGrdTB2:SetValue("T2_CODBCO" , QSA6->A6_COD)
     oGrdTB2:SetValue("T2_NOMBCO" , QSA6->A6_NOME)
     oGrdTB2:SetValue("T2_AGENCIA", QSA6->A6_AGENCIA)
     oGrdTB2:SetValue("T2_DVAGE"  , QSA6->A6_DVAGE)
     oGrdTB2:SetValue("T2_NUMCON" , QSA6->A6_NUMCON)
     oGrdTB2:SetValue("T2_DVCTA"  , QSA6->A6_DVCTA)
     oGrdTB2:SetValue("T2_SUBCTA" , QSA6->EE_SUBCTA)

     QSA6->(dbSkip())
  EndDo

  QSA6->(dbCloseArea())

  oGrdTB2:SetNoInsertLine(.T.)
  oGrdTB2:SetNoDeleteLine(.T.)
  oGrdTB2:SetNoUpdateLine(.T.)
  oGrdTB2:GoLine(1)
  oView:Refresh()
Return
