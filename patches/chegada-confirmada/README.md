# Chegada fisica antes do proximo passo

Base: releases/DisneyClient-Follow-Original-33ms-Sem-Correcao.zip.
Entrega: releases/DisneyClient-Follow-Chegada-Confirmada.zip.

Apos o prazo gravado, o ponto fica pendente ate a posicao real confirmar chegada.
So entao o indice avanca e o prazo seguinte passa a ser chegada + proximo delay.
Nao existe timeout de chegada baseado no relogio antigo nem salto de pontos
para recuperar atraso. Uma visita antiga nao confirma coordenadas repetidas.

O executor da base foi ampliado com RouteFeedback e RouteInputPacer. O controle
usa teclas internas, le a fisica e mantem 33ms entre trocas normais. Microparadas
e offsets aleatorios nao sao usados. Os teleportes automaticos continuam inertes.
Rotas e backend foram preservados. Nao houve deploy nem partida autenticada.

Aplicar na pasta DisneyClient-Completo da base: git apply chegada-confirmada.patch.
Recompilar: python fontes-robot/build.py --ffdec /caminho/ffdec.

119 verificacoes Robot, incluindo simulacao independente de aceleracao por teclas,
atrasos de chegada e prazos seguintes; 17 Follow, 37 AutoBest, 37 interface,
18 visual e 32 Fly. Verificador estatico aprovado. Evidencia e limites:
CHEGADA-CONFIRMADA-LEIA-ME.txt e PROVA-DE-CHEGADA.json dentro do ZIP.
