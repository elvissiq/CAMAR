#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} BuscaCep
  Função para buscar endereço no site dos correios a partir do CEP
  @type  User Function
  @author TOTVS Nordeste (Elvis Siqueira)
  @since 23/08/2024
  @version 1.0
/*/

User Function BuscaCep()

  Private cCep  := IIF(!Empty(M->A1_CEP),M->A1_CEP,IIF(!Empty(M->A2_CEP),M->A2_CEP,""))
  Private cTab  := IIF(!Empty(M->A1_CEP),"A1",IIF(!Empty(M->A2_CEP),"A2",""))
  Private lRet  := .T. 

	If Empty(cCep)
      APMsgAlert("Para preenchimento do endereço, por favor preencher o campo CEP com um CEP válido.",+;
                 "Campo CEP em branco!",)
	EndIf

  If !Empty(cCep) .And. !Empty(cTab)
      Busca() //Realiza busca no site dos correios
  EndIf 

Return lRet

/*/{Protheus.doc} BuscaCep
  Função para buscar endereço no site dos correios a partir do CEP
  @type  Static Function
  @author TOTVS Nordeste (Elvis Siqueira)
  @version 1.0
/*/
Static Function Busca()
Local oObjJson   := Nil
Local oModel     := Nil
Local oModelDet  := Nil
Local aHeadStr   := {"Content-Type: application/json"}
Local cUrl	     := "http://viacep.com.br/ws/" + cCep + "/json/"
Local nTimeOut   := 200
Local lEndEntCob := SuperGetMV("MV_XENTCOB", .F., .F.)
Local cGetParams := ""
Local cHeaderGet := ""
Local cRetorno   := ""
Local cEndereco  := ""
Local cBairro    := ""
Local cEstado    := ""
Local cCodMun    := ""
Local cDescMun   := ""

  If cTab == "A1"
    
    oModel := FWModelActive()
    oModelDet := oModel:GetModel('SA1MASTER')

  ElseIf cTab == "A2"
    
    oModel := FWModelActive()
    oModelDet := oModel:GetModel('SA2MASTER')
  
  EndIf 


  cRetorno := HttpGet(cUrl, cGetParams, nTimeOut, aHeadStr, @cHeaderGet)
  
  If !FWJsonDeserialize(cRetorno, @oObjJson)
	  If !ApMsgYesNo("O CEP informado não foi encontrado na base de dados dos correios. Deseja continuar ?")
      lRet := .F.
    EndIf 
  ElseIf INCLUI
      If At('"erro"',cRetorno) > 0
        If !ApMsgYesNo("O CEP informado não foi encontrado na base de dados dos correios. Deseja continuar ?")
          lRet := .F.
        EndIf 
      Else  

        cEndereco  := Upper(Alltrim(IIF(Len(DecodeUTF8(oObjJson:logradouro))>0,Padr(DecodeUTF8(oObjJson:logradouro),TamSX3(cTab+"_END")[1]),M->&(cTab+"_END"))))
        cBairro    := Upper(Alltrim(IIF(Len(DecodeUTF8(oObjJson:bairro))>0,DecodeUTF8(oObjJson:bairro),M->&(cTab+"_BAIRRO"))))
        cEstado    := Upper(Alltrim(IIF(Len(DecodeUTF8(oObjJson:uf))>0,DecodeUTF8(oObjJson:uf),M->&(cTab+"_EST"))))
        cCodMun    := Upper(Alltrim(IIF(Len(SubStr(oObjJson:ibge,3,5))>0,SubStr(oObjJson:ibge,3,5),M->&(cTab+"_COD_MUN"))))
        cDescMun   := Upper(Alltrim(IIF(Len(DecodeUTF8(oObjJson:localidade))>0,DecodeUTF8(oObjJson:localidade),M->&(cTab+"_MUN"))))

        IIF(Empty(oModelDet:GetValue(cTab+"_END"))     , oModelDet:SetValue(cTab+"_END",cEndereco)   ,"")
        IIF(Empty(oModelDet:GetValue(cTab+"_BAIRRO"))  , oModelDet:SetValue(cTab+"_BAIRRO",cBairro)  ,"")
        IIF(Empty(oModelDet:GetValue(cTab+"_EST"))     , oModelDet:SetValue(cTab+"_EST",cEstado)     ,"")
        IIF(Empty(oModelDet:GetValue(cTab+"_COD_MUN")) , oModelDet:SetValue(cTab+"_COD_MUN",cCodMun) ,"")
        IIF(Empty(oModelDet:GetValue(cTab+"_MUN"))     , oModelDet:SetValue(cTab+"_MUN",cDescMun)    ,"")

        If lEndEntCob
          //Endereço de Cobrança
          oModelDet:SetValue(cTab+"_ENDCOB",cEndereco)
          oModelDet:SetValue(cTab+"_MUNC",cCodMun)
          oModelDet:SetValue(cTab+"_CEPC",cCep)
          oModelDet:SetValue(cTab+"_ESTC",cEstado)

          //Endereço de Entrega
          oModelDet:SetValue(cTab+"_ENDENT",cEndereco)
          oModelDet:SetValue(cTab+"_BAIRROE",cBairro)
          oModelDet:SetValue(cTab+"_ESTE",cEstado)
          oModelDet:SetValue(cTab+"_MUNE",cDescMun)
        EndIf 

      Endif
  EndIf
Return
