# Remoção dos teleportes automáticos

Patch aplicado ao arquivo recebido `DisneyClient-Follow (3).zip`. O resultado completo e as fontes correspondentes estão em [DisneyClient-Follow-Sem-Teleporte.zip](../../releases/DisneyClient-Follow-Sem-Teleporte.zip).

O patch modifica somente quatro corpos de métodos do SWF e o texto do status Follow. Remove o setter de posição, a cópia visual de coordenadas e os pacotes de sincronização inicial do motor compartilhado. Movimento por teclas e rotas são preservados.

Validação: 17 checks específicos, 563 do Robot (2.359 rotas, 179.813 passos) e 37 do AutoBest. Nenhuma partida autenticada foi executada.

Requer Java 21 e FFDec 26.4.0 para reaplicar o patch; detalhes e fontes completas acompanham o ZIP.
