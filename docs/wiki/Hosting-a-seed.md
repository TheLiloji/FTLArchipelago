# Hosting a seed

FTL is not part of the main Archipelago release yet, so whoever generates the seed needs the world file.

## Generating

1. Install [Archipelago](https://github.com/ArchipelagoMW/Archipelago/releases/latest) 0.6.7 or newer.
2. Put `ftl.apworld` from the release in the `custom_worlds` folder of Archipelago.
3. Put every player's YAML in the `Players` folder. FTL players can start from a [preset](Options.md).
4. Run `ArchipelagoGenerate`. The seed is written to the `output` folder as a `.zip`.

The other players' games work as usual; only the FTL world needs the extra file.

## Hosting

Run `ArchipelagoServer` with the `.zip` on your own machine and give the players your address and the port
(`38281` by default). Players outside your network need that port opened on your router.

You can also try uploading the `.zip` to [archipelago.gg](https://archipelago.gg/uploads). The site may refuse
a seed with a world it does not ship; in that case, host it yourself.

## Playing alone without a server

An FTL player can also try a seed with no server at all: **Solo mode** on the main menu plays a seed that comes
with the mod. See [Playing](Playing.md#solo-mode).
