# beta.20 : Kestrel A sans sa clé (kestrel_key), scénarios pour WINDOWS-TESTS

Nouveautés à vérifier : étiquette NO KEY dans la liste du hangar, START assombri et refusé, bandeau
« NO KEY: THIS RUN DOES NOT COUNT » pendant une run refusée. Nouvelle DLL (fonction HangarShip, lecture seule) :
refaire aussi le passage complet habituel de la beta.19 (journal, TLS, vraie room archipelago.gg).

## Seeds

Base (`FTL: Faster Than Light`), YAML :

```yaml
name: Tester
game: "FTL: Faster Than Light"
"FTL: Faster Than Light":
  start_ship: rock
  kestrel_key: true
  layout_count: 28
  excluded_layouts: ["Engi Cruiser", "Federation Cruiser", "Zoltan Cruiser", "Mantis Cruiser"]
  start_inventory:
    Crystal Cruiser Key: 1
```

Multiverse (`FTL Multiverse`) : la même chose avec `game: "FTL Multiverse"`. Sous MV, le départ est toujours le
Kestrel MV et kestrel_key ne verrouille rien : aucun NO KEY ne doit apparaître.

## Base

1. Clé absente, hangar : New Game. Le hangar s'ouvre sur The Kestrel. Attendu : START assombri avec « NO KEY »
   dessus. Capture.
2. Clé absente, START : cliquer START. Attendu : la partie ne démarre pas, une fenêtre courte
   « Kestrel A: no key yet. Pick another ship. » pendant environ 5 s. Log : `START refused`. Capture.
3. Liste : LIST (fermer les deux bulles d'aide la première fois, puis rouvrir la liste). Attendu : « NO KEY »
   sur la case du Kestrel, « NOT IN SEED » sur Engi, Federation, Zoltan, Mantis ; Rock et Crystal sans
   étiquette. Capture.
4. Random Ship : cliquer RANDOM SHIP plusieurs fois, puis START à chaque fois. Attendu : START refusé quand
   c'est le Kestrel, accepté pour Rock ou Crystal.
5. Autre vaisseau : choisir le Rock dans la liste, START. Attendu : la run démarre normalement, pas de bandeau.
6. Clé reçue : depuis le serveur, `/send Tester Kestrel Cruiser Key`. Revenir au hangar (Échap > Hangar > Yes),
   choisir le Kestrel. Attendu : plus de NO KEY, START normal, la run démarre sans bandeau.
7. Continue : avec une run refusée sauvegardée, Save+Quit puis Continue. Attendu : le bandeau
   « NO KEY: THIS RUN DOES NOT COUNT » en haut au centre dès la reprise, et il reste tant que la run dure.
   Pour obtenir une telle run sans vieille version : en run sur le Rock, console Hyperspace
   `lua Hyperspace.playerVariables.ap_run_ship_refused = 1`, puis Save+Quit, Continue.
8. Langues : refaire 1 à 3 en français et en allemand (textes : PAS DE CLÉ, KEIN SCHLÜSSEL). Rien ne doit
   déborder des cadres.

## Multiverse

9. New Game : le hangar s'ouvre sur le Kestrel MV (Superluminal). Attendu : pas de NO KEY, START démarre la run.
10. Liste MV : aucune étiquette NO KEY nulle part.

## À rendre

Captures 1, 2, 3, 7, 9 ; extraits de `FTL_HS.log` (`START refused`, `this run's ship`) ; OK/KO par scénario.
