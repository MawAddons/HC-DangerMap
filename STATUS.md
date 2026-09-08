# Status 0.1.0

## Implementeret

- Aggregerede doeds-, near-miss-, beacon-, manuelle og community-markeringer.
- Zone/valgfri koordinater, type, levelinterval, note, observationstal, senest set, kilder og confidence.
- 5 %-aggregering, 30/90-dages aldersregler og maks. 400 SavedVariables-markeringer.
- Eget aktuelt-zone-plot med op til 20 positionerede pins samt zone-only listefallback.
- `HCS1|MAP` med 240-byte loft, escaping, type-/versions-/modulvalidering, rate-limit og deduplikering.
- Community-sync OFF som standard; ingen navne i almindelige danger events og ingen løbende position.
- Valgfrie Journal-/Beacon-API'er, klassisk UI, Escape/X/slash, minimap og gemt position.

## Mangler / kendte begraensninger

- Blizzard World Map modificeres ikke, fordi 1.12 ikke har en stabil pin-provider-kontrakt.
- Globale doedsannoncer giver zone, men ingen paalidelig position; de gemmes zone-only.
- Maks. 20 koordinatpins tegnes samtidig; resten er fortsat i den sorterede liste.
- Community-kanalen kan vaere faction-opdelt/deaktiveret, og konkret flerklienttest udestaar.
