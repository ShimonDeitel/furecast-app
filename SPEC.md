# Furecast — Pet Cost Predictor

Part of the "Animated Ten" batch (see `pulse/ANIMATED_TEN_QUEUE.md`).

## Concept

A pre-adoption, breed-specific true-cost-of-ownership predictor that converts into an ongoing
expense tracker once the pet comes home, contrasting the original prediction against real
logged spending over time.

## Problem / evidence

Two independent Quora askers wanted breed-specific cost prediction before adopting a pet. The
App Store has only after-the-fact expense loggers (Pawly, PetCost, 0 ratings each) with no
predictive or breed-risk layer — nothing helps a prospective owner see the specific,
breed-linked costs coming before they commit.

## Free vs Pro

- **Free**: manual expense logging for one pet, no breed prediction.
- **Pro ($3.99/mo)**: pre-adoption breed cost prediction, AI surprise-risk coaching,
  predict-vs-actual reports, and unlimited pets.

## Quirky feature — the surprise jar

A "surprise jar" separately tracks ONLY the costs the app specifically flagged as
breed-specific risks at prediction time (never routine costs like food or litter). Owners tag
a logged expense against one of the pet's specific predicted risk flags; the jar sums only
those. This makes the prediction falsifiable in real time — if a flagged risk never gets
tagged against a real expense, that specific warning didn't come true for this pet.

## Animation hook

A pet-silhouette "piggy bank" (`PetSilhouetteShape`, a rounded head + two ear bumps) starts
the year as a thin outline. As real expenses log, a warm coral fill clipped to the silhouette
rises (`PiggyBankView`, animated with `withAnimation`/`.spring`), while a thin sage
predicted-line marker shows where the app expected the fill to be by now (elapsed-time
fraction of the predicted annual total). The visual gap between the fill's top edge and the
marker is the prediction made obvious at a glance.

## AI feature

`POST /text` to the shared no-key Cloudflare Worker proxy
(`https://apps-ai-proxy.s0533495227.workers.dev/text`) with the pet's species, breed, age, and
a summary of logged expenses so far. The model returns 2-3 specific breed-linked "surprise
cost" risks with rough dollar ranges plus one practical money-saving tip tailored to the
logged spending pattern, parsed from a JSON-in-a-string reply (`AICoach.parse`).

## Design direction

Sage green + warm coral/salmon. Every card, button, and container uses `PawBlobShape` — a
custom asymmetric rounded-corner blob (each corner independently radiused) rather than a
uniform rounded rectangle — plus a literal hand-drawn `PawPrintShape` for decorative marks.
Organic and playful, deliberately distinct from this batch's grids and rings (Vantage's
graphite linework, Handoff's constellation layout, etc).

## Breed reference dataset

18 hand-written `BreedProfile` entries (12 dog, 6 cat) in `BreedCatalog.swift`, each with a
baseline routine-cost estimate plus 1-3 specific `BreedRiskFlag`s (title, explanation, low/high
first-year dollar range) — brachycephalic breeds and airway surgery risk, large/giant breeds
and joint/bloat risk, long-spine breeds and IVDD risk, long-coat breeds and grooming load,
breed-linked cardiac/kidney screening, and more.

## Monetization

Auto-renewable monthly subscription, StoreKit 2, product ID
`com.shimondeitel.furecast.pro.monthly`, $3.99/month.
