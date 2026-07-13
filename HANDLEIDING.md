# RecraVas dashboard — handleiding & functie-overzicht

Naslagdocument: wat je in het dashboard ziet, hoe het werkt, en welke functies eronder zitten.
Live op **dashboard.recraparcs.nl**. Eén bestand: `index.html` (HTML+CSS+JS). Data uit **Supabase**.

---

## 1. Hoe het werkt (in het kort)

```
Pipedrive (CRM)   ─┐
                   ├─► Supabase Edge Functions (elk uur) ─► Postgres-tabellen ─► RPC-functies ─► dashboard
Meta Ads          ─┘
```

- **`sync-pipedrive`** haalt elk uur alle deals op (leads, afspraken, verkopen, makelaar, advertentie,
  notities, e-mails en het eerstvolgende agendapunt).
- **`sync-meta`** haalt uitgaven, clicks, thumbnails en advertentiestatus uit Meta.
- Het dashboard leest **nooit** rechtstreeks tabellen, maar altijd via **RPC-functies** die bepalen
  wat je mag zien.

**Datumlogica.** In de meeste weergaven telt elk cijfer op zijn eigen datum (lead = aanmaakdatum,
afspraak = afspraakdatum, verkoop = verkoopdatum). In het **advertentiedashboard** is alles
*lead-geankerd*: afspraken en sales tellen bij de maand dat de **lead** binnenkwam.

---

## 2. De tabbladen

### Resultaten
De hoofdfunnel: leads → afspraken → verkopen, met closing %, afval % en no-show %, plus de
**uitverkoop** van het park (verkocht / gereserveerd / beschikbaar, % verkocht en een prognose tot
uitverkocht). De **opvolglijst** toont open leads in de stage "In contact" die nog opvolging nodig
hebben — gesorteerd op wanneer er voor het laatst contact was (notitie of e-mail). Leads met een
toekomstig agendapunt vallen eruit (die staan al gepland).

### Advertenties
Per park. Uitgaven, clicks, leads, kosten per lead (CPL), kosten per afspraak (CPA) en de
conversie lead → afspraak (Conv. %) per advertentie, een dagverloop-grafiek, een cohort-overzicht
per lead-maand, automatische inzichten (beste conversie, goedkoopste leads, budgetlekken,
CPL-trend) en de best presterende advertenties (met thumbnail). Advertenties met dezelfde
naam-code worden als één advertentie getoond.
Elke advertentie heeft een instelbare **Fase** (awareness, Schwartz): Onb = Onbewust,
Prob = Probleembewust, Opl = Oplossingsbewust, Prod = Productbewust, Meest = Meest bewust.
Klik op de fase-pill om de fase en de notities te bewerken; filter met de fase-keuzelijst.

### Archief
De creative-library: alle advertenties met thumbnail en hun all-time resultaten (uitgaven, leads,
CPL, afspraken, CPA, sales), filterbaar op fase en status. Klik op een advertentie om de notities
in te vullen: werkte wel/niet, waarom (waarschijnlijk), en bij een gestopte advertentie de
kill-reden. Die notities zijn ook zichtbaar in het Advertenties-tabblad (✕-icoontje = kill-reden)
en zijn gekoppeld aan de advertentiecode, dus ze overleven het samenvoegen van kopieën.

### Prognose
Vooruitblik op basis van de recente cijfers.

### Resale
Aan- en verkoop van bestaande woningen (Pipedrive-pijplijn Resale). Zuivere funnel: leads → afspraken
→ verkopen, per makelaar en per maand.

---

## 3. Wat je kunt aanklikken

- **Elk deal-aantal is klikbaar** (leads, afspraken, verkopen) — je krijgt de onderliggende deals in
  een lijst met **een Pipedrive-link per deal**.
- **Verloren-redenen** zijn klikbaar → de verloren deals.
- Klik op een **advertentierij** voor het dagverloop; op een **aantal** in die rij voor de deals.
- **↓ PDF** (rechtsboven): drukt het actieve tabblad in één klik af — kies in de printdialoog
  "Opslaan als PDF". Afdrukken gebeurt altijd in het lichte thema.
- **Rapport** (rechtsboven, alleen eigenaar): genereert een deelbare tekst-samenvatting van de
  gekozen periode (funnel, kwaliteit, advertenties, team, aandachtspunten) — kopieer met één klik.
- **◐-knop** (rechtsboven): thema — automatisch (donker van 18:00 tot 09:00), licht of donker.
- Klik op een **advertentie** (Advertenties-tab): naast het dagverloop verschijnt de creative-foto;
  klik erop voor de grote versie.
- **Handleiding** (rechtsboven): opent dit document.
- **Filters** (bovenaan): periode, park, makelaar. Bij een eindige periode tonen de KPI-kaarten
  automatisch ▲/▼ t.o.v. de even lange periode ervoor, plus een mini-trendlijn per maand.

---

## 4. Begrippen & definities

| Begrip | Betekenis |
|--------|-----------|
| **Lead** | Elke Pipedrive-deal (aanmaakdatum = leaddatum). |
| **Afspraak** | Deal die (ooit) in een afspraak-stage kwam. Een afspraak die nog in de toekomst gepland staat, telt pas mee zodra hij is geweest. |
| **Shows** | Afspraken die daadwerkelijk hebben plaatsgevonden (afspraken − no-shows). |
| **Verkoop** | Deal vanaf "Informeel akkoord ontvangen" en verder, niet verloren. |
| **Closing %** | Verkopen ÷ **shows** (dus op de afspraken die geweest zijn, niet op no-shows). |
| **Afval %** | Verloren deals ÷ leads. |
| **No-show %** | Afspraken met "Klant niet geweest" ÷ afspraken. |
| **Show %** | 100 % − no-show %. |
| **Kanaal** | De bron van de advertentie (Meta, Google, LinkedIn, organisch); instelbaar per advertentie, filterbaar en per-kanaal op te tellen. |
| **CPL** | Advertentie-uitgaven ÷ leads. |
| **CPA** | Advertentie-uitgaven ÷ afspraken. |
| **Conv. %** | Afspraken ÷ leads per advertentie (kwaliteit van de leads). |
| **Fase** | Awareness-fase van het publiek (Schwartz): Onbewust → Meest bewust. |
| **Definitief** | Verkoop waarvan het koopcontract definitief is, naar de notaris is of gepasseerd. |
| **ROAS** | Rendement op de advertentie-uitgaven. |
| **Cohort** | De groep leads die in dezelfde maand binnenkwam; "rijpheid" = hoe oud die leads zijn. |

Riverte en Berkenstrand zijn bewust ongemapt en worden uit de funnel gehouden.

---

## 5. Advertentie-attributie (hoe leads aan advertenties hangen)

- Pipedrive legt de advertentie vast in het veld **"AD naam"** (bv. `DB-AD3`). Dat matcht op de
  naam van de advertentie in Supabase.
- Handmatige uitzonderingen liggen vast in **`ad_name_alias`** en **`ad_code_alias`**.
- Gekopieerde advertenties (nieuw Meta-id, zelfde naam) worden samengevoegd op **advertentiecode**.
- **Google** bestaat als aparte bron (niet-Meta).
- **Thumbnails** en de **actuele status** komen elke sync uit Meta.
- **Uitgaven/clicks** komen uit Meta; **leads/afspraken/verkopen** komen uit Pipedrive.

---

## 6. Functie-overzicht (RPC's)

**Resultaten:** `owner_total_funnel`, `owner_agent_performance`, `owner_park_agent`,
`client_park_funnel`, `agent_stats`, `monthly_overview`, `appointments_detail`.

**Opvolgen & park:** `opvolg_leads`, `park_sellthrough`, `client_park_inventory`.

**Live leads / verloren:** `live_lead_stats`, `live_lead_months`, `lost_reasons`, `lost_deals`.

**Bellen:** `call_overview`, `call_stats`, `call_attempts_to_reach`.

**Advertenties:** `ad_kpis`, `ad_overview`, `ad_daily`, `ad_daily_detail`, `ad_monthly`, `ad_deals`,
`ad_archive` (creative-library), `set_ad_annotation` (fase + notities per advertentiecode).

**Definitief:** `definitief_check`, `agent_definitief`, `monthly_definitief`.

**Resale:** `resale_funnel`, `resale_agent_performance`, `resale_agent_stats`, `resale_monthly`,
`resale_deals`.

**Deals-drilldown (klikbare aantallen):** `agent_deals`, `resale_deals`, `ad_deals` — elk geeft per
deal een Pipedrive-link.

---

## 7. Bekende beperkingen

- **Bel-activiteiten** worden nog niet altijd gelogd, en **"Betrokken verkoper"** is vaak niet
  ingevuld → per-makelaar-cijfers deels leeg.
- **Wielsche Dreef Meta-account** nog niet gekoppeld → daar staan de advertentiekosten op €0.
- De **uitverkoopprognose** is nog dun zolang er weinig recente verkopen in het systeem staan.
