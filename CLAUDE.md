# Claude instructies — Advertentie Dashboard

## Vaste regels

- **Notion token staat NOOIT in HTML** — het token leeft alleen in n8n credentials; n8n fungeert als CORS-proxy.
- **NOOIT JSON-bestanden pushen naar GitHub** — lever ze alleen als bestandsdownload naar de Finder.
- **Altijd pushen naar `main`** na elke wijziging.

## Notion Ad Stats bijwerken via CSV

Wanneer een Meta Ads CSV wordt geüpload:
- Update per ad (geaggregeerd over ad sets met dezelfde naam): **Spend** en **Clicks** alleen.
- **Leads NOOIT bijwerken vanuit CSV** — leads worden altijd handmatig in Notion bijgehouden.
- **Afspraken, Sales, Omzet NOOIT bijwerken vanuit CSV** — altijd handmatig.

## Dashboard (notion-dashboard.html)

- Datumbereiken eindigen op **gisteren** (niet vandaag) om gedeeltelijke dagen te vermijden.
- CPC wordt berekend in het dashboard: `spend / clicks` — niet opgeslagen in Notion.
- Demo-modus: CPL max €22, CPA max €500, CPS max €2.600.
