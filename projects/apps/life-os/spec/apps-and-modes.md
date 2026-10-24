# Apps, sources, Me and modes — Life OS

Every box ([box-contract.md](box-contract.md)) has one **kind**: an **app**
(a life area), a **source** (a connector that feeds the Knowledge Core), or
**Me** (identity and profile). Navigation, Home and installation follow the
kind. Layers and invariants: [architecture.md](architecture.md). Terms:
[glossary.md](glossary.md).

## Kinds

| Kind | Is | Members |
| --- | --- | --- |
| `app` | A life area: own experience over the Knowledge Core | `finance` Finance · `health` Health · `career` Career & Learning · `family` Family · `notes` Notes & reminders · `reflection` Reflection (Journal) |
| `source` | A connector: sync status, review queue, drafts into the core | `documents` Folders / Documents · `conversations` Chats · Email inbox · bank and investment statements · prices · SMS alerts |
| `me` | Identity and profile, one area | About me · household profile · [identity vault](identity-vault.md) (My IDs) |

Sources that belong to one box's import (email inbox, statements, prices, SMS
alerts in [Finance](boxes/finance.md)) are listed under Sources while their
drafts still go to that box's review queue.

## Rules

| # | Rule |
| --- | --- |
| K1 | Home shows apps as life-area tiles, sources in a separate *Sources* area, and *Me* as its own entry. A source or Me is never shown as a life-area tile. |
| K2 | Each source shows: last sync, status (`ok`, `error` with the reason, `never run`), and the number of drafts waiting in its review queue, linking to that queue. |
| K3 | Document search is global: available from every app and the coordinator, results filtered by the searching app's [context policy](context-policy.md). |
| K4 | People, dates and commitments found in chats appear where they belong: people and relationship nudges with the household's people in Family, dates and commitments as draft reminders in Notes & reminders. Chats is where they came from, not where they live. |
| K5 | The identity vault, about me and the household profile are reached from *Me*, never from a source. |
| K6 | Each app has its own entry point (its own path), its own installable manifest (name, icon, scope, start page), its own screens, workflows and preferences, and a scoped Ask using its policy, with a way to ask the coordinator instead. |
| K7 | Apps link to each other's pages (e.g. a Finance goal → the child in Family); a link opens the other app. |
| K8 | All apps share one sign-in session and one origin; installing one app as its own icon does not sign the owner in again. The offline cache holds application files only, never data ([privacy-security.md](privacy-security.md)). |

## Modes

| Mode | When | The owner sees | Data |
| --- | --- | --- | --- |
| Standalone | Exactly one app enabled | That app's full workflows, plus Me and the sources it uses | The one Knowledge Core and identity |
| Connected | Two or more apps enabled | Cross-app links, cross-domain context through policies, the coordinator's *Today* | The same Knowledge Core and identity |

| Rule |
| --- |
| Standalone never means a separate database. |
| Enabling an app needs no migration: it reads the facts already in the core. |
| Disabling an app hides it, stops its context requests and keeps all its data. |

## Configuration

| Layer | Holds | Changed by |
| --- | --- | --- |
| Platform | The catalogue of apps, sources and Me with their manifests and kinds; the box contract; the core API version; *sample* rules and [default grants](context-policy.md#default-grants) | Releases |
| Personal | Enabled apps (`apps.enabled`), the owner's sources (each source's own keys), goals (core facts), per-app preferences, context policies (`context.policies.<appId>`) | The owner |

Keys and defaults: [configuration.md § Apps, sources and context](configuration.md#apps-sources-and-context).
There is no marketplace: the catalogue is what the platform ships.
