# Controle preditivo por teclas internas

Base: `releases/DisneyClient-Follow-Sem-Teleporte.zip`, derivado do ZIP `DisneyClient-Follow (3).zip`.
Entrega: `releases/DisneyClient-Follow-Controle-Preditivo.zip`.

O Robot passa a aplicar os comandos gravados depois da chegada ao ponto correspondente,
estimar o local da decolagem pela primeira amostra de subida e antecipar a frenagem
com a velocidade real. A confirmacao de pontos considera a fase vertical do salto.
Nao escreve posicao ou VX/VY e nao altera os arquivos de rotas.

O patch inclui as fontes canonicas, a classe gerada e as regressoes. O teste de
interface foi atualizado para exigir movimento por teclas sem teleporte, conforme
solicitado na revisao anterior; o teste antigo exigia o reposicionamento removido.

Para reproduzir: extrair o ZIP base, entrar em DisneyClient-Completo e aplicar
`git apply /caminho/controle-preditivo.patch`. Recompilar com
`python fontes-robot/build.py --ffdec /caminho/ffdec` (Java 21, FFDec 26.4.0).
O ZIP de entrega ja contem o SWF compilado e todas as fontes.

Validacao e limites: ver `CONTROLE-PREDITIVO-LEIA-ME.txt` e
`fontes-robot/VALIDACAO-PREDITIVA.json` dentro do ZIP. A simulacao valida os seis
primeiros pontos da @298424 em tres intervalos de quadro; a leitura das demais
rotas valida seu formato. Nao foi realizada partida autenticada.
