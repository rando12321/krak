# Teclas temporizadas sem check de chegada

Base: releases/DisneyClient-Follow-Chegada-Confirmada.zip, derivada do anexo
DisneyClient-Follow (1) (1).zip. Entrega: releases/DisneyClient-Follow-Teclas-Sem-Check.zip.

O check de chegada e suas classes foram removidos. Os teleportes automaticos
continuam desativados. O plano de teclas usa uma epoca absoluta e os tempos
acumulados da gravacao, sem rebase por quadro nem minimo de 33ms. Um unico timer
cancelavel tenta cumprir as transicoes entre quadros. A compilacao do plano
acontece antes de iniciar o relogio automatico.

Direcoes ml/mr prevalecem sobre o sinal de VX. VY gravado permite inferir decolagens
atrasadas e novos impulsos de UP. Nao ha leitura da posicao/velocidade atual,
atribuicao de X/Y/VX/VY, espera por ponto ou envio manual de pacote de movimento.
Estados simultaneos sao coalescidos; todos os indices de origem sao retidos.
Os marcadores nao comprovam coleta/vitoria: esses eventos continuam sendo nativos.

Pesquisa, contas e fontes: PESQUISA-FISICA.md e ANALISE-FISICA-GRAVACOES.json.
Rotas e backend foram preservados. Nao houve partida autenticada ou deploy.

O patch de fontes aplica-se na pasta DisneyClient-Completo da base:
git apply linha-do-tempo.patch
Recompilar: python fontes-robot/build.py --ffdec /caminho/ffdec.
O ZIP de entrega ja inclui o SWF compilado e a documentacao atualizada.

4878 verificacoes Robot, 2359 rotas / 179813 passos compilados, 281 impulsos
repetidos e 339 decolagens reconstruidas; 17 Follow, 37 AutoBest, 37 interface,
18 visual e 32 Fly. Testes de X/Y e velocidade utilizam getters que geram erro.
Verificador estatico exige ausencia de RouteFeedback/RouteInputPacer e proibe
acessos a posicao/velocidade nos metodos de execucao do Robot.
