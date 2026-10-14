---
name: Remote Pi App — session status
description: Native session status tokens and scoped responsive refinement
colors:
  bg: "#14191F"
  text: "#F2F6FC"
  muted: "#AEC2E0"
  working: "#95CC5E"
typography:
  monoSmall:
    fontFamily: "FiraMono Nerd Font"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.4
rounded: {}
spacing: {}
components:
  session-working:
    textColor: "{colors.working}"
    typography: "{typography.monoSmall}"
    size: "16px"
---

## Overview

Scoped native refinement of existing Chat toolbar and session tiles, not a full App redesign. Frontmatter records the dark-theme source tokens relevant to status; the light theme remains supported. Existing pale text, cyan accent, Fira Mono, platform sans and Inter branding are retained. Impeccable's native guidance was used; its HTML/CSS detector does not support Flutter.

## Colors

`AppColors.dark.working` uses the actual Tron Legacy green. `AppColors.light.working` is the accessibility-derived darker green `#426B21`, not a literal VS Code color. Both the label and busy glyph resolve the same token. Other semantic colors are unchanged.

Measured WCAG sRGB working contrast against actual App backgrounds:

| Theme | Background | Surface/input | Selected tile (6% accent over background) |
| --- | ---: | ---: | ---: |
| Dark | 9.32:1 | 8.17:1 | 8.18:1 |
| Light | 6.26:1 | 5.69:1 surface / 5.50:1 input | 5.77:1 |

## Typography

Status and metadata use `AppTypography.monoSmall`; tile titles retain 15px medium sans, chat titles retain 13px medium mono. User text scaling remains enabled. Working color is confined to status rather than tinting all metadata. Avatar initials use a one-line height to fit their existing 40px circle at 200% text.

## Layout

Separate session metadata from the untruncated status label. Secondary model text may ellipsize; session/path/title retain existing truncation and details access. Four-pixel vertical gaps clarify hierarchy. The toolbar's device/status group wraps instead of squeezing the status at large text. Status glyphs occupy 16px; no whole-row animation or layout motion is introduced.

## Components

`SessionStatus.resolve` preserves working > reconnecting > online > offline. `SessionStatusIndicator` rotates only the working renewal glyph (1200ms). Disable-animations or accessible-navigation preferences stop rotation and retain the same green shape and visible label. Decorative glyphs are excluded from semantics; adjacent labels communicate status independently of color.

## Do's and Don'ts

- Keep observed working and relay facts; do not infer connection state from speech segments.
- Keep visible status labels and reduced-motion feedback.
- Do not add neon glows, pulse entire rows, or copy reference blue into inaccessible white-text buttons.
- Font-loaded host screenshots under `build/93-dictation-status/{before,after}/` render production widgets with inert synthetic data at 360×800, 412×915 and 768×1024, dark/light, 100%/200%. They are not paired-device, installed-route or acoustic evidence.
