# Microcorrecao de trajetoria interpolada

Base: commit b3f280614ef78b5d59902a05efd25d94d65d079a,
releases/DisneyClient-Follow-33ms-Sem-Teleporte-Passo-FPS.zip.
Entrega: releases/DisneyClient-Follow-Trajetoria-Suave-FPS.zip.

Corrige a deriva do relogio e substitui as microparadas/offsets aleatorios por
prazos acumulados. Novos impulsos de VY podem retriggerar UP. Um timer cancelavel
atende teclas; ENTER_FRAME atende a correcao de posicao.

O interpolador usa Hermite com tangentes gravadas. Busca a projecao local na
curva em +/-80ms, mistura 80% projecao / 20% referencia temporal e limita a escrita
a 0,5px por aplicacao e 24px/s. Ignora erro acima de 18px, segmentos inconsistentes
e eixos praticamente parados. Um bloqueio de fisica nao muda o relogio.
Nao ha espera por chegada nem alteracao de indice pelo interpolador. Os passos
continuam chamando apenas movement. Pequenos ajustes ainda usam reposicionamento
fisico; nao se afirma interpolacao somente visual nem aceitacao pelo servidor.

FPS Unlock, NativeMotion e Follow mantidos byte a byte nas fontes. Rotas e backend
preservados. Sincronizacao inicial da base mantida. Sem partida autenticada.

Aplicar na pasta DisneyClient-Completo da base: git apply trajetoria-suave.patch.
Recompilar: python fontes-robot/build.py --ffdec /caminho/ffdec.
1132 verificacoes de interpolacao, 192 tempo/teclas, 34 desempenho, 27 Follow,
37 AutoBest, 37 interface, 18 visual, 32 Fly e verificador estatico aprovados.
Limites e prova: TRAJETORIA-SUAVE-LEIA-ME.txt e VALIDACAO-TRAJETORIA-SUAVE.json.
