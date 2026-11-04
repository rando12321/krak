# Intervalo de 33 ms no executor original do anexo

Entrada: DisneyClient-Follow (1) (1).zip, SHA-256
`d38570bc95f2be534b8c116218755701862877684c8847c6e7bc7cebef96a8aa`.
O usuario reenviou um arquivo identico e pediu que o ajuste fosse feito nessa base.
Esta revisao conserva o executor original, com uma unica mudanca funcional:
intervalo minimo de 33 ms entre aplicacoes walk e rebase do prazo apos atraso,
sem pular passos nem recuperar atraso em rajadas. Nao altera o envio dos sockets.

Entrega: releases/DisneyClient-Follow-Original-33ms.zip. Os demais arquivos
originais sao preservados byte a byte, salvo build ID e manifesto atualizados.
O ZIP contem BASE-DO-ANEXO.json com a identificacao e a lista de alteracoes.
O reposicionamento e a sincronizacao originais desta base permanecem presentes.

O patch aplica-se na pasta DisneyClient-Completo do ZIP original com
`git apply /caminho/intervalo-original.patch`. Para recompilar:
`python fontes-robot/build.py --ffdec /caminho/ffdec`.

Testes: 44 Robot, 27 Follow, 37 AutoBest, 37 interface; formato das 2359 rotas /
179813 passos validado. Nao houve partida autenticada nem confirmacao da causa do DC.
