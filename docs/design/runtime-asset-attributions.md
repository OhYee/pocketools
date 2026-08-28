# Runtime visual asset attributions

## Scope

This record covers the local runtime visuals used by the v0.1.1 candidate. The machine-readable source of truth is [`assets/runtime/asset-manifest.json`](../../assets/runtime/asset-manifest.json); it records every runtime path, dimensions, processing policy, source hash and runtime hash.

The candidate is intentionally not a public-release license approval. Every entry currently has `licenseStatus=candidate`. A public build must promote the relevant entries only after the service terms or third-party source and target-jurisdiction review is complete.

## Generated physical-object artwork

The following assets were generated for Pocketools through the platform image-generation capability on 2026-08-23 or 2026-08-24 and then converted to transparent runtime derivatives:

- `assets/runtime/coin_heads.png`
- `assets/runtime/coin_tails.png`
- `assets/runtime/coin_edge.png`
- `assets/runtime/d20_blank.png`
- `assets/runtime/tarot_back.png`
- `assets/runtime/playing_card_back.png`

The prompts explicitly excluded currency denomination, portraits, seals, flags, logos and third-party game branding. The coin face source was cropped into two runtime faces; the D20 source contains no fixed numerals so the frozen result can be rendered truthfully; the playing-card source was cropped with a rounded alpha mask into a `416 × 624` card silhouette. Chroma-key removal, trimming and aspect-preserving resizing are recorded in the manifest. The generated images are not the design-board mockups under `docs/design/mockups/` and are not represented as third-party public-domain works.

## Rider–Waite–Smith candidate deck

The 78 card face derivatives under `assets/runtime/tarot/rider_waite/` are a local 360×600 JPEG derivative of the source files listed in the manifest. The mapping is:

- Pamela Colman Smith, Rider & Company, 1909 attribution context.
- Source repository and exact file paths: [`mixvlad/TarotCards`](https://github.com/mixvlad/TarotCards), with the source notes in [`SOURCES.md`](https://github.com/mixvlad/TarotCards/blob/main/SOURCES.md).
- The source notes describe the original card artwork as public-domain material, but the project does not treat that statement as an automatic worldwide redistribution approval. The exact source version, scan derivative, color treatment, target jurisdiction and any repository-level terms must be reviewed before a public release.

No AI restoration, recoloring, commercial deck screenshot, mirror, redraw or semantic text overlay is used in the card image files. Reversed cards reuse the same original image and apply a runtime 180° rotation plus a separate text label; they are not separately re-randomized or edited image files.

## Review boundary

This record is suitable for local development, QA and offline artifact inspection. It is not a legal opinion and does not grant permission to redistribute any candidate asset. When a reviewer approves an entry, update `licenseStatus`, `reviewedBy`, `reviewedAt` and the release report together; do not edit only the prose record.
