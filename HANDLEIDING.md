# RecraVas dashboard — handleiding & functie-overzicht

Naslagdocument: wat je in het dashboard ziet, hoe het werkt, en welke functies eronder zitten.
Live op **dashboard.recraparcs.nl**. Eén bestand: `index.html` (HTML+CSS+JS). Data uit **Supabase**
(project `ooqkpazyvohsrdvxfnug`).

---

## 1. Hoe het werkt (in het kort)

```
Pipedrive (CRM)   ─┐
                   ├─► Supabase Edge Functions (elk uur) ─► Postgres-tabellen ─► RPC-functies ─► dashboard (index.html)
Meta Ads          ─┘
```

- **`sync-pipedrive`** haalt elk uur alle deals op (leads, afspraken, verkopen, makelaar, advertentie).
- **`sync-meta`** haalt uitgaven, clicks, thumbnails en advertentiestatus uit Meta (Frankrijk-account).
- Het dashboard leest **nooit** rechtstreeks tabellen, maar altijd via **RPC-functies** die per rol
  bepalen wat je mag zien.

**Datumlogica.** In de meeste weergaven telt elk cijfer op zijn eigen datum (lead = aanmaakdatum,
afspraak = afspraakdatum, verkoop = verkoopdatum). In het **advertentiedashboard** is alles
*lead-geankerd*: afspraken en sales tellen bij de maand dat de **lead** binnenkwam, zodat het
advertentiebudget van een periode naast het uiteindelijke resultaat van diezelfde leads staat.

---

## 2. Rollen & toegang

Kies rechtsboven bij **"Bekijk als"** de rol (in de huidige preview-modus zonder inloggen).

| Rol | Wat je ziet | Tabbladen |
|-----|-------------|-----------|
| **Eigenaar** | Alles: totalen, per makelaar, financiën (incl. marge), prognose, advertenties, resale | Resultaten · Advertenties · Financiën · Prognose · Resale |
| **Makelaar** | Eigen cijfers + teamgemiddelde (zonder namen van collega's), eigen commissie | Resultaten · Financiën · Resale |
| **Ontwikkelaar (park)** | Alleen parkgemiddelden van het eigen park | Resultaten |

**AVG-harde regel:** een makelaar of ontwikkelaar ziet **nooit** de marge van RecraVas
(`recraparcs_marge`). Alleen de eigenaar ziet marge.

---

## 3. De tabbladen

### Resultaten
De hoofdfunnel. **Eigenaar** ziet totalen (Uitgaven, Leads, Afspraken, Sales, Omzet, Omzet per
afspraak, CPL, Closing %, Afval %, No-show %) + een tabel **per makelaar** + omzet per park + de
verloren-redenen + per maand. **Makelaar** ziet de eigen cijfers naast het teamgemiddelde.
**Ontwikkelaar** ziet parkgemiddelden.

### Advertenties
Per park (Frankrijk / Wielsche Dreef). KPI's (uitgaven, leads, CPL, afspraken, CPA, sales,
kost per sale, omzet, ROAS), een dagverloop-grafiek, een **maandoverzicht** (budget vs. resultaat),
een **per-advertentie-tabel** en de **best presterende advertenties** (kaarten met thumbnail).
Advertenties met dezelfde naam-code (bv. `NH-AD2`) worden als **één** advertentie getoond, ook al
heeft Meta ze door kopiëren een ander id gegeven.

### Financiën
Alles vanaf mondeling akkoord tot notaris. Courtage = percentage per park (Wielsche Dreef 1,5 %,
Frankrijk 5,5 %). **Eigenaar** ziet omzet én marge; **makelaar** ziet de eigen commissie
(1,5 %, max €3.500 per verkoop) met een **staaf-/lijn-grafiek** (staaf = commissie, lijn = verkoopsom).

### Prognose
Verwachting op basis van echte Meta-spend en Pipedrive-verkopen.

### Resale
Aan- en verkoop van bestaande woningen (Pipedrive-pijplijn Resale). Zuivere funnel (geen
advertenties/park). **Fee = 2,5 % van de woningwaarde, minimaal €2.500.** Eigenaar ziet totalen +
per makelaar + per maand; makelaar ziet eigen cijfers + teamgemiddelde.

---

## 4. Wat je kunt aanklikken

- **Elk deal-aantal is klikbaar** (leads, afspraken, sales/verkopen) — op de totaalkaarten, in de
  per-makelaar-tabellen, op de makelaar-kaarten, in resale en per advertentie. Je krijgt de
  onderliggende deals in een lijst met **een Pipedrive-link per deal**.
- **Verloren-redenen** zijn klikbaar → de verloren deals.
- Klik op een **advertentierij** voor het dagverloop; op een **aantal** in die rij voor de deals.
- **↓ PDF** (rechtsboven): drukt het actieve tabblad in één klik af — kies in de printdialoog
  "Opslaan als PDF". Werkt voor elke rol.
- **Filters** (bovenaan): periode, park, makelaar.

---

## 5. Begrippen & definities

| Begrip | Betekenis |
|--------|-----------|
| **Lead** | Elke Pipedrive-deal (aanmaakdatum = leaddatum). |
| **Afspraak** | Deal die (ooit) in een afspraak-stage kwam ("Afspraak gepland" e.v.). |
| **Verkoop / Sale** | Deal vanaf "Informeel akkoord ontvangen" en verder, niet verloren. |
| **Closing %** | Verkopen ÷ afspraken. |
| **Afval %** | Verloren deals ÷ leads. |
| **No-show %** | Afspraken met "Klant niet geweest" ÷ afspraken. |
| **Show %** | 100 % − no-show %. |
| **CPL** | Advertentie-uitgaven ÷ leads. |
| **CPA** | Advertentie-uitgaven ÷ afspraken. |
| **Kost per sale** | Advertentie-uitgaven ÷ verkopen. |
| **ROAS** | Omzet ÷ advertentie-uitgaven. |
| **Verkoopsom** | Huisprijs (`amount`). |
| **Omzet** | Totale courtage die RecraVas factureert (percentage per park). |
| **Courtage / commissie makelaar** | 1,5 % van de verkoopsom, max €3.500 per verkoop. |
| **Marge RecraVas** | Omzet − commissie makelaar. **Alleen zichtbaar voor de eigenaar.** |
| **Resale-fee** | 2,5 % van de woningwaarde, minimaal €2.500. |

**Uitgesloten:** Riverte en Berkenstrand (bewust ongemapt) en de Resale-pijplijn worden uit de
gewone funnel gehouden; Resale heeft een eigen tabblad.

---

## 6. Advertentie-attributie (hoe leads aan advertenties hangen)

- Pipedrive legt de advertentie vast in het veld **"AD naam"** (bv. `DB-AD3`). Dat matcht op de
  naam van de advertentie in Supabase.
- Handmatige uitzonderingen liggen vast in **`ad_name_alias`** (bv. "AD 3" → DB-AD3, alle "NH-AD2"
  → één advertentie) en **`ad_code_alias`** (AD 1/2/3 → DB-AD1/2/3).
- Gekopieerde advertenties (nieuw Meta-id, zelfde naam) worden samengevoegd op **advertentiecode**.
- **Google** bestaat als aparte bron (niet-Meta).
- **Thumbnails** en de **actuele status** (Actief/Gepauzeerd/Gestopt) komen elke sync uit Meta.
- **Spend/clicks** komen uit Meta; **leads/afspraken/sales/omzet** komen uit Pipedrive.

---

## 7. Functie-overzicht (RPC's)

**Rollen & toegang:** `is_owner`, `has_park_access`, `current_email`, `my_access`,
`grant_full_access`, `grant_park_access`, `owner_agents`, `owner_parks`.

**Resultaten (eigenaar/park):** `owner_total_funnel`, `owner_agent_performance`, `owner_park_agent`,
`client_park_funnel`, `agent_funnel`, `monthly_overview`, `appointments_detail`, `real_deals_detail`.

**Makelaar:** `agent_stats` (eigen + teamgemiddelde).

**Live leads / verloren:** `live_lead_stats`, `live_lead_months`, `lost_reasons`, `lost_deals`.

**Bellen:** `call_overview`, `call_stats`, `call_attempts_to_reach`.

**Advertenties:** `ad_kpis`, `ad_overview` (per advertentie, samengevoegd op code), `ad_daily`,
`ad_daily_detail` (dagverloop), `ad_monthly` (budget vs. resultaat), `ad_deals` (deals per
advertentie), `manual_ad_spend_overview`.

**Financiën:** `finance_deals`, `finance_deals_agent`, `finance_monthly`, `finance_monthly_agent`,
`recalc_deal_margins`.

**Resale:** `resale_funnel`, `resale_agent_performance`, `resale_agent_stats` (eigen + team),
`resale_monthly`, `resale_deals` (drilldown).

**Deals-drilldown (klikbare aantallen):** `agent_deals` (leads/afspraken/verkopen per makelaar of
totaal, met park-filter), `resale_deals`, `ad_deals`.

**Overig:** `client_park_inventory`.

> Elke drilldown-functie geeft per deal een **Pipedrive-link** terug.

---

## 8. Bekende beperkingen

- **Login/SMTP uit** → marge nu alleen in de UI verborgen, nog niet op databaseniveau.
- **Bel-activiteiten leeg** (team logt geen gesprekken) en **"Betrokken verkoper"** vaak niet
  ingevuld → per-makelaar-cijfers deels leeg.
- **Wielsche Dreef Meta-account** nog niet gekoppeld → WD-advertentiekosten €0.
- **Resale-woningwaarde** nog niet overal ingevuld → dunne fee-omzet.

---

## 9. Beheer

- **Deploy** = commit + push naar `main`; GitHub Pages herbouwt automatisch (~1 min).
- **Let op:** er wordt soms parallel aan dezelfde Supabase-functies gewerkt — altijd eerst
  `git fetch`/rebase, en niet twee sessies tegelijk aan de advertentie-backend.
