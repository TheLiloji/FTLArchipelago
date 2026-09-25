# Instalação no Windows

[English](Setup-Windows.md) · [Français](Setup-Windows.fr.md) · [Deutsch](Setup-Windows.de.md) ·
[Español](Setup-Windows.es.md) · [Italiano](Setup-Windows.it.md) · **Português**

*Esta página foi traduzida com IA e pode ter erros. Em caso de dúvida, vale a página em inglês.*

Leva uns dez minutos. Você precisa do FTL da Steam (ou GOG), com o conteúdo da Advanced Edition, que vem em todas
as cópias vendidas hoje.

## O que baixar

Coloque tudo na mesma pasta, por exemplo `Downloads`.

- Da [release do FTL Archipelago](https://github.com/TheLiloji/FTLArchipelago/releases/latest):
  `ArchipelagoFTL.ftl` e `Hyperspace.dll`.
- Da [release do ftlman](https://github.com/afishhh/ftlman/releases/latest):
  `ftlman-x86_64-pc-windows-gnu.zip`.
- Da [release do Hyperspace 1.23.1](https://github.com/FTL-Hyperspace/FTL-Hyperspace/releases/tag/v1.23.1):
  `FTL.Hyperspace.1.23.1-Windows.zip`.

Descompacte os dois zip. Você fica com uma pasta `ftlman`, com `ftlman.exe` e uma pasta `mods` vazia dentro, e
com `Hyperspace.ftl`, que vem do zip do Hyperspace.

## 1. Proteger seus saves

- Na Steam, clique com o botão direito no FTL, **Propriedades**, **Geral**, e desative a **Steam Cloud**. Senão a
  Steam pode colocar um save antigo de volta enquanto você joga.
- Copie a pasta `Documents\My Games\FasterThanLight` para um lugar seguro.

O mod usa um perfil próprio, então seu progresso normal no FTL não é tocado. A cópia é só por segurança.

## 2. Instalar o Hyperspace com o ftlman

Abra o `ftlman.exe`. Em geral ele encontra o jogo sozinho; se não, mostre a pasta do FTL (a que tem o
`FTLGame.exe`, por exemplo `C:\Program Files (x86)\Steam\steamapps\common\FTL Faster Than Light`).

Instale o **Hyperspace 1.23.1** pelo ftlman. Numa cópia da Steam, o ftlman primeiro muda o FTL para a versão
1.6.9 e guarda o original como `FTLGame_orig.exe`. É normal: a 1.6.9 é a única versão para Windows em que o
Hyperspace roda.

## 3. Adicionar o mod

Copie `Hyperspace.ftl` e `ArchipelagoFTL.ftl` para a pasta `mods`, a que fica dentro da pasta `ftlman`. No
ftlman, marque os dois, com o Hyperspace **acima** do ArchipelagoFTL, e clique em **Apply**. Feche o ftlman
quando terminar.

## 4. Colocar a biblioteca do Archipelago

Na pasta do FTL agora existe um `Hyperspace.dll`. Renomeie para `Hyperspace.dll.official` (para guardá-lo) e
depois copie no lugar dele o `Hyperspace.dll` da release do FTL Archipelago.

O FTL precisa estar fechado: o Windows bloqueia o arquivo enquanto o jogo está aberto.

Se algum dia você clicar de novo em Apply no ftlman, copie outra vez o `Hyperspace.dll` do Archipelago depois.

## 5. Iniciar o jogo

Inicie o FTL pela Steam. Você deve ver:

![Menu principal depois da instalação](../images/connect-panel.jpg)

- `HS-1.23.1` no canto superior direito,
- o logo do Archipelago no canto superior esquerdo,
- um painel **Connect to a multiworld** no canto inferior esquerdo.

Se o painel não aparecer, ou a conexão nunca funcionar, veja o [FAQ](FAQ.md) (em inglês).

## Atualizar para uma versão nova

Coloque o novo `ArchipelagoFTL.ftl` na pasta `mods` do ftlman, clique de novo em **Apply** e depois copie o novo
`Hyperspace.dll` por cima do que está na pasta do FTL.

Próximo: [Jogar](Playing.md) (em inglês).
