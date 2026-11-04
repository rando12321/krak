# Remocao dos teleportes na base original com 33ms

Entrada: releases/DisneyClient-Follow-Original-33ms.zip.
Entrega: releases/DisneyClient-Follow-Original-33ms-Sem-Correcao.zip.

A revisao anterior preservou o reposicionamento da base. Agora place e
synchronizeCurrent sao no-ops, followSample usa somente teclas e a sincronizacao
inicial do Follow foi removida. Exatamente quatro corpos de metodos mudaram na
SWF; os demais foram preservados byte a byte. Uma string de status foi atualizada.
O executor e o intervalo de 33ms permanecem iguais ao ZIP anterior.

O teste verifica que os registros sao processados em ordem, sem forcar posicao.
O executor ainda usa os tempos gravados e nao confirma chegada fisica a cada
ponto. Nao houve partida autenticada. Correcao do servidor e teleporte manual
nao sao interceptados.

Aplicar fontes na pasta DisneyClient-Completo da base: git apply sem-correcao.patch.
Recompilar: python fontes-robot/build.py --ffdec /caminho/ffdec.
Alternativamente, RemoveRouteTeleports.java aplica os quatro patches de bytecode
na SWF da base 33ms. Nao executar novamente sobre a SWF ja corrigida.

Testes: 23 Robot, 17 Follow, 37 AutoBest, 37 interface e verificador estatico.
Evidencia e hashes: PROVA-SEM-CORRECAO.json dentro do ZIP.
