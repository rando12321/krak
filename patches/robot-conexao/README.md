# Robot: intervalo nos comandos e diagnostico de DC

Base exclusiva: ZIP `DisneyClient-Follow (1) (1).zip` enviado pelo usuario.
Entrega: `releases/DisneyClient-Follow-Robot-Conexao.zip`.

O Robot deixa de reposicionar o corpo em cada amostra e de chamar sincronizacao
artificial ao iniciar. Usa teclas internas com o controle preditivo e intervalo
minimo de 33 ms entre trocas normais de comando, conservando apenas o estado
mais recente. As liberacoes de teclas sao imediatas. Nenhum pacote de socket,
heartbeat ou login e atrasado; nao e implementada uma fila de pacotes de rede.

O observador e o endpoint autenticado registram quedas com mapa e estado do Robot,
incluindo quando nao existe mensagem de erro. A ausencia de motivo informado
pelo jogo e registrada explicitamente. A causa original do DC nao foi comprovada.

O patch se aplica na pasta DisneyClient-Completo da base: `git apply /caminho/robot-conexao.patch`.
Recompilar com `python fontes-robot/build.py --ffdec /caminho/ffdec`.
O ZIP ja contem o SWF compilado e o backend atualizado; nao houve deploy na VPS.

Validacao: 455 Robot, 17 Follow, 37 AutoBest, 18 visual, 32 Fly, 37 interface,
15 observador AVM2 e 15 testes Python do endpoint. Todas as 2359 rotas / 179813
passos foram lidas, e os arquivos das rotas preservados. A simulacao de movimento
cobre seis pontos da @298424 em tres intervalos de quadro, sem partida autenticada.
Veja ROBOT-CONEXAO-LEIA-ME.txt e fontes-robot/VALIDACAO-CONEXAO.json no ZIP.
