# HC Danger Map 0.1.1

Lokalt og valgfrit community-synkroniseret farekort til WoW 1.12.1. Det samler doedsannoncer, Danger Journal-events, aktive Rescue Beacons og manuelle markeringer. Identiske observationer afrundes til 5 %-celler og aggregeres; confidence falder med alder. Community-observationer udloeber efter cirka 30 dage, lokale efter cirka 90, og hoejst 400 markeringer gemmes.

Installation: kopier `HC-DangerMap` til `World of Warcraft\Interface\AddOns\HC-DangerMap`. SavedVariables: `HCDangerMapDB`.

Et flytbart kortikon ved minimappet åbner/lukker Danger Map. Træk ikonet for at flytte det; `/hcdm minimap` skjuler eller viser det.

Kommandoer:

- `/hcdm` eller `/hcdangermap`: vindue.
- `/hcdm sync on|off`: community-kanal (OFF som standard).
- `/hcdm minimap`.

Brug Type, note og Add local. Add + share er stadig lokal, hvis sync er OFF. Delte almindelige danger events indeholder ikke spillernavn. Aktive Rescue Beacons viser af natur afsendernavn og vises kun via Beacon-addonets API.

1.12 har ingen stabil provider-API til pins paa Blizzard World Map. Derfor viser addon'et et eget normaliseret plot for den aktuelle zone og lader Blizzard-kortet vaere urørt. Zone-only events opfindes ikke som koordinater og staar i listen.
