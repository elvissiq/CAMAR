#Include 'Protheus.ch'

User Function FINA580()

  Local _aParam:=  PARAMIXB 

  If !Valtype(_aParam)  ==  "U"  //Verifica��o necess�ria para chamada do Ponto de Entrada no final da grava��o.

    RecLock( "SE2", .F. )
      SE2->E2_XAPRHR  := TIME()
    SE2->( MsUnlock() ) 

  Endif

Return
