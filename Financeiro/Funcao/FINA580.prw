#Include 'Protheus.ch'

User Function FINA580()

  Local _aParam:=  PARAMIXB 

  If !Valtype(_aParam)  ==  "U"  //Verificação necessária para chamada do Ponto de Entrada no final da gravação.

    RecLock( "SE2", .F. )
      SE2->E2_XAPRHR  := TIME()
    SE2->( MsUnlock() ) 

  Endif

Return
