# krak

Robô refeito para setas reais via Windows SendInput, com tempos/direções convertidos das gravações físicas e checks de chegada em tempo real.

**Requer backend local no mesmo Windows do Adobe_10.exe, com o jogo em foco.** O iniciador agora abre o endereço local. Publicar só o SWF em uma VPS não envia teclas ao PC do jogador.

- [Como usar](DisneyClient-Completo/TECLAS-REAIS-LEIA-ME.txt)
- [Cálculo e validação](DisneyClient-Completo/PRECISAO-TECLADO-LEIA-ME.txt)
- [2.205 planos convertidos](DisneyClient-Completo/rotas_teclado_convertidas.json)
- [ZIP atualizado](releases/DisneyClient-Follow-Teclado-Precisao.zip)

32 verificações do SWF e 26 testes Python passaram, incluindo handshake HTTP, confirmação/soltura, controlador nativo simulado e conversão da base completa. Os mapas originais foram preservados. SendInput no Windows real e a física do servidor ainda precisam ser validados no PC do usuário.
