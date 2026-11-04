# Física, gravações e tempo das teclas

Análise de 04/11/2026 da base enviada `DisneyClient-Follow (1) (1).zip`.
As alterações foram feitas sobre a última revisão dessa mesma base. Nenhum mapa
foi convertido ou regravado; os arquivos de rotas foram preservados.

## Problemas encontrados no executor

1. O avanço por chegada somava tempo de espera ao prazo gravado. Foi removido:
   o executor não consulta posição ou velocidade do jogador atual.
2. A barreira de 33 ms por amostra alterava intervalos menores. Existem 19.203
   intervalos positivos abaixo de 33 ms e 6.824 amostras com delay zero.
   Esse mínimo foi removido. No cálculo teórico da restrição, a mediana do
   acréscimo era 153 ms por mapa; no percentil 95, 571 ms. Na @298424, 522 ms.
   Esses números são uma estimativa isolada do limite de consumo, sem incluir
   renderização ou rede. Não são medições de uma partida.
3. Recalcular o próximo prazo a partir do quadro atrasado acumulava atraso.
   Agora cada prazo é `início da reprodução + tempo acumulado da gravação`.
   A compilação da rota acontece antes de fixar o início do relógio automático.
4. Em 26.618 amostras uma tecla aponta contra o VX atual. Isso é compatível com
   frenagem e inércia. O novo executor respeita `ml/mr`; não transforma o sinal
   de VX numa direção obrigatória.
5. `jump` é estado amostrado. Um novo impulso pode ocorrer enquanto esse campo
   continua verdadeiro. A análise das linhas do tempo identifica 281 desses
   casos; também reconstrói 339 decolagens quando a primeira amostra de subida
   já está atrasada em relação ao início do salto.

## Unidades e equações

O decoder do próprio ZIP escreve/lê os campos como int32/int16. Portanto:

- posição em pixels: `int32(campo) × 0,3`;
- velocidade física: `int16(campo) / 100`;
- velocidade em pixels por segundo: velocidade física × 30.

Por exemplo, VX `65191` representa **−3,45**, não uma velocidade positiva;
VY `65036` representa **−5**. Os cálculos tratam as representações assinadas e
não assinadas da mesma forma. Os valores decodificados **não são escritos**
no corpo do personagem.

Em 68.080 pares aproximadamente balísticos, a estimativa mediana de gravidade
foi 10 unidades físicas/s². Em 11.283 pares com VX aproximadamente constante,
a razão `deslocamento / (VX × 30 × segundos gravados)` teve mediana 0,9903.
Isso indica que os delays já representam tempo em milissegundos; não há evidência
para converter todo delay novamente pela média das velocidades dos extremos.

A inferência conservadora de decolagem usa:

```
idade = (VY_amostra - VY_inicial) / gravidade
VY_inicial = -5
instante_decolagem = instante_amostra - idade
Y_decolagem = Y_amostra - 30 * (-5 * idade + 0,5 * gravidade * idade²)
```

O algoritmo estima a gravidade por rota quando há pares suficientes. Só antecipa
uma decolagem se a idade estiver entre 12 e 450 ms, não ultrapassar a amostra
anterior e a altura reconstruída for compatível com o apoio anterior. Nos outros
casos mantém o instante gravado. Isso compara **dados da gravação** durante a
compilação do plano, não a posição atual do jogador nem a chegada a um ponto.

## Exemplo @298424

Os seis primeiros prazos acumulados são 2006, 2006, 2243, 2458, 2535 e 3236 ms.
O teste exige UP em 2243 ms e RIGHT em 2458 ms mesmo com VX ainda negativo.

O trecho de 701 ms termina numa amostra cuja velocidade foi alterada. Usar a
média do módulo das velocidades dos extremos para converter esse trecho daria
aproximadamente **1781 ms**. Isso não representa a velocidade de todo o trecho:
uma colisão ou impulso no final muda a amostra final. O novo controle conserva
os 701 ms e não inventa um deslocamento de 1781 ms.

## Pesquisa na internet

Foram consultadas fontes públicas, sem executar os programas pesquisados:

- [Box2D: documentação oficial de simulação](https://github.com/erincatto/box2d/blob/main/docs/simulation.md).
  Explica a relação entre passo de simulação, velocidade, gravidade, amortecimento
  e contato. É documentação da versão atual do Box2D, não uma especificação do
  cliente Flash do Transformice. Não adotei seu FPS sugerido como se fosse o FPS
  desta versão do jogo.
- [Servidor comunitário Transformice](https://github.com/NoFileFound/Transformice),
  particularmente `src/main/java/org/transformice/packets/recv/newpackets/S_PlayerMovement.java`:
  direções, posição, velocidade e `isJumping` são campos distintos no protocolo.
  É uma implementação de outra versão, não código oficial do jogo. O formato
  concreto de int32/int16 utilizado aqui vem do decoder do ZIP do usuário.
- No mesmo repositório, `src/main/java/org/transformice/command/commands/player/LuaHelp.java`
  documenta gravidade do mundo e multiplicadores de gravidade/vento. Isso reforça
  que um número fixo não descreve todos os mapas. O valor padrão utilizado na
  inferência é sustentado também pelas gravações desta base.

A física nativa do jogo continua responsável por aceleração, atrito, gravidade,
colisões e animação. O Robot somente aciona as teclas internas. Não substituí
Box2D por um modelo aproximado nem sobrescrevi VX/VY para encaixar uma rota.

## Verificação e limites

Os testes reais no AVM2/Ruffle usam um jogador cujos getters de X/Y e de velocidade
geram erro. O executor conclui os testes sem tocá-los. Também são verificados
intervalos de 5–10 ms, quadros irregulares, ausência de deriva acumulada, direção
oposta ao VX, novos impulsos de UP, espelhamento, respawn e cancelamento do timer.
As 2.359 rotas são compiladas e verificadas sem modificar o JSON.

O temporizador único tenta cumprir os prazos entre quadros, com revisão em
ENTER_FRAME antes do loop normal. A resolução real ainda depende do Flash Player,
da taxa de simulação e de travamentos do processo. Não existe garantia de prazo
em tempo real durante um travamento.

Uma gravação de estados recebidos pela rede não é um registro completo de teclas.
Faltam a geometria exata de cada contato, forças externas, mudanças de gravidade,
interações com outros jogadores e a variação de atraso da rede. Esses fatores
impedem garantir uma rota perfeita em qualquer condição usando somente as amostras.
Não houve partida autenticada nem teste de todas as geometrias dos mapas.

O método analítico é reproduzível:

```
python fontes-robot/analyze_recorded_physics.py
```

Os resultados numéricos estão em `fontes-robot/ANALISE-FISICA-GRAVACOES.json`.
