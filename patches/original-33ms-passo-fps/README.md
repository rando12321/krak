# Base original 33ms: teleporte por passo e FPS Unlock

Base exata: commit 9918d2761a62ea75c74a9a7e0e3f0bf9d530b292,
releases/DisneyClient-Follow-Original-33ms.zip. O blob foi verificado por SHA-256.
Entrega: releases/DisneyClient-Follow-33ms-Sem-Teleporte-Passo-FPS.zip.

O executor canonico e o gerado mudam exatamente uma chamada: followSample com
X/Y passa a movement com as teclas. NativeMotion, RouteTiming e Follow estao
inalterados nas fontes. Os 33ms, calculos, sincronizacao inicial e Follow
original sao preservados. Nao foi integrado outro executor nem check de chegada.

O FPS Unlock solicita 1000 em vez de 120, aplica a taxa em toda atualizacao e
EXIT_FRAME, e restaura/libera a taxa ao desativar. O limite personalizado agora
aceita 1 a 1000. O estado inicial do toggle continua desligado. O teto da API do
Player e 1000; nao se afirma FPS infinito nem renderizacao real de 1000 FPS.

O patch se aplica na pasta DisneyClient-Completo da base. Recompilar:
python fontes-robot/build.py --ffdec /caminho/ffdec.
PatchOnlyRouteStepTeleport.java e um utilitario separado para reproduzir SOMENTE
a alteracao de um metodo na SWF original, sem as mudancas de FPS. Verifica que
todos os demais corpos de metodos permanecem byte a byte iguais nesse patch isolado.
A entrega completa foi recompilada para incluir tambem os controles de FPS.

Testes: 23 Robot, 34 desempenho, 27 Follow, 37 AutoBest, 37 interface, 18 visual,
32 Fly e verificador estatico. Rotas e backend preservados; sem partida autenticada.
Evidencia detalhada: PASSOS-E-FPS-LEIA-ME.txt e VALIDACAO-PASSOS-E-FPS.json no ZIP.
