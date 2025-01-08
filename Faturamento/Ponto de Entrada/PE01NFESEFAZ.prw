//Bibliotecas
#Include 'totvs.ch'

#Define ENTER Chr(13)+Chr(10)

/*/{Protheus.doc} PE01NFESEFAZ
Ponto de entrada localizado na função XmlNfeSef do rdmake NFESEFAZ. 
Através deste ponto é possível realizar manipulações nos dados do produto, 
mensagens adicionais, destinatário, dados da nota, pedido de venda ou compra, antes da 
montagem do XML, no momento da transmissão da NFe.
@author TOTVS NORDESTE (Elvis Siqueira)
@since 23/10/2024
@version 1.0
    @return Nil
        PE01NFESEFAZ - Manipulação em dados do produto ( [ aParam ] ) --> aRetorno
    @example
        Nome	 	 	Tipo	 	 	    Descrição	 	 	                        	 
 	    aParam   	 	Array of Record	 	aProd     := PARAMIXB[1]
                                            cMensCli  := PARAMIXB[2]
                                            cMensFis  := PARAMIXB[3]
                                            aDest     := PARAMIXB[4]
                                            aNota     := PARAMIXB[5]
                                            aInfoItem := PARAMIXB[6]
                                            aDupl     := PARAMIXB[7]
                                            aTransp   := PARAMIXB[8]
                                            aEntrega  := PARAMIXB[9]
                                            aRetirada := PARAMIXB[10]
                                            aVeiculo  := PARAMIXB[11]
                                            aReboque  := PARAMIXB[12]
                                            aNfVincRur:= PARAMIXB[13]
                                            aEspVol   := PARAMIXB[14]
                                            aNfVinc   := PARAMIXB[15]
                                            aDetPag   := PARAMIXB[16]
                                            aObsCont  := PARAMIXB[17]
                                            aProcRef  := PARAMIXB[18]
    @obs https://tdn.totvs.com/pages/viewpage.action?pageId=274327446
/*/

User Function PE01NFESEFAZ()
    Local aProd     := PARAMIXB[1]
    Local cMensCli  := PARAMIXB[2]
    Local cMensFis  := PARAMIXB[3]
    Local aDest     := PARAMIXB[4] 
    Local aNota     := PARAMIXB[5]
    Local aInfoItem := PARAMIXB[6]
    Local aDupl     := PARAMIXB[7]
    Local aTransp   := PARAMIXB[8]
    Local aEntrega  := PARAMIXB[9]
    Local aRetirada := PARAMIXB[10]
    Local aVeiculo  := PARAMIXB[11]
    Local aReboque  := PARAMIXB[12]
    Local aNfVincRur:= PARAMIXB[13]
    Local aEspVol   := PARAMIXB[14]
    Local aNfVinc   := PARAMIXB[15]
    Local adetPag   := PARAMIXB[16]
    Local aObsCont  := PARAMIXB[17]
    Local aProcRef  := PARAMIXB[18]
    Local aRetorno  := {}

    Local nVolume   := 0
    Local _nI
    Local cCNPJ     := Alltrim(FWSM0Util():GetSM0Data( cEmpAnt , cFilAnt , { "M0_CGC" } )[1][2])
    Local aMsgNF    := {{"04458510000168", "RGP PB-R1153059-0"},;
                        {"04458510000249", "RGP R1155730-0 S.I.F 925"},;
                        {"11808952000152", "RGP R1153852-0"},;
                        {"11808952000314", "RGP RN-U1152402-0"},;
                        {"11808952000403", "RGP RN-U1156339-7"},;
                        {"04782319000258", "RGP RN-R1153373-0"},;
                        {"04782319000339", "RGP RN-R1156396-0"},;
                        {"11808952000667", "RGP RN-U1157171-1"},;
                        {"11808952000233", "Operação isenta de ICMS conforme Art. 7º do RICMS RN, anexo 1 Art. 6º, inciso I. RGP RN-R1156428"}}
    Local nPosCGC   := aScan(aMsgNF,{|x| AllTrim(x[01]) == AllTrim(cCNPJ)})

    If !Empty(nPosCGC)
        cMensCli := cMensCli + " " + aMsgNF[nPosCGC][2]
    EndIF 

    If aNota[4] == "1" // Se for Nota Fiscal de Saída 
        
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        //@ Bloco responsável por acrescenta o Número do LOTE. ///// INICIO /////
        For _nI := 1  to Len(aProd) 

            nVolume += aProd[_nI,9] //Soma a quantidade dos produtos 

        Next _nI
        //@ Bloco responsável por acrescenta o Número do LOTE. ///// FIM /////
        //--------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    EndIF 

    If !Empty(aEspVol)
        aEspVol[1,2] := nVolume
    EndIF

    aadd(aRetorno,aProd)
    aadd(aRetorno,cMensCli)
    aadd(aRetorno,cMensFis)
    aadd(aRetorno,aDest)
    aadd(aRetorno,aNota)
    aadd(aRetorno,aInfoItem)
    aadd(aRetorno,aDupl)
    aadd(aRetorno,aTransp)
    aadd(aRetorno,aEntrega)
    aadd(aRetorno,aRetirada)
    aadd(aRetorno,aVeiculo)
    aadd(aRetorno,aReboque)
    aadd(aRetorno,aNfVincRur)
    aadd(aRetorno,aEspVol)
    aadd(aRetorno,aNfVinc)
    aadd(aRetorno,AdetPag)
    aadd(aRetorno,aObsCont)
    aadd(aRetorno,aProcRef) 

Return aRetorno
