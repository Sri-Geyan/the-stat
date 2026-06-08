---
name: The Stat
colors:
  surface: '#121414'
  surface-dim: '#121414'
  surface-bright: '#37393a'
  surface-container-lowest: '#0c0f0f'
  surface-container-low: '#1a1c1c'
  surface-container: '#1e2020'
  surface-container-high: '#282a2b'
  surface-container-highest: '#333535'
  on-surface: '#e2e2e2'
  on-surface-variant: '#c0cab7'
  inverse-surface: '#e2e2e2'
  inverse-on-surface: '#2f3131'
  outline: '#8a9482'
  outline-variant: '#40493b'
  surface-tint: '#87db6a'
  primary: '#87db6a'
  on-primary: '#0a3900'
  primary-container: '#1a6b00'
  on-primary-container: '#95ea77'
  inverse-primary: '#1d6d03'
  secondary: '#ffe7a0'
  on-secondary: '#3c2f00'
  secondary-container: '#f4c700'
  on-secondary-container: '#685400'
  tertiary: '#c9c6c5'
  on-tertiary: '#313030'
  tertiary-container: '#5d5c5c'
  on-tertiary-container: '#d8d5d4'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#a2f883'
  primary-fixed-dim: '#87db6a'
  on-primary-fixed: '#042100'
  on-primary-fixed-variant: '#125200'
  secondary-fixed: '#ffe081'
  secondary-fixed-dim: '#eec200'
  on-secondary-fixed: '#231b00'
  on-secondary-fixed-variant: '#564500'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c9c6c5'
  on-tertiary-fixed: '#1c1b1b'
  on-tertiary-fixed-variant: '#474646'
  background: '#121414'
  on-background: '#e2e2e2'
  surface-variant: '#333535'
typography:
  display-score:
    fontFamily: Rajdhani
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: 0.02em
  headline-lg:
    fontFamily: Rajdhani
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Rajdhani
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Rajdhani
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: DM Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: DM Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: DM Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: DM Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin: 20px
---

## Brand & Style
The design system is engineered for high-intensity sports data consumption. It prioritizes immediate legibility and impact, drawing inspiration from stadium scoreboards and traditional newsprint. The personality is aggressive, authoritative, and fast-paced, catering to sports enthusiasts who demand real-time clarity without visual clutter.

The aesthetic follows a **High-Contrast / Bold** movement with a strict **Flat UI** implementation. There are no gradients, blurs, or drop shadows. Depth is created through solid color blocking and heavy borders rather than traditional lighting effects. Every pixel serves a functional purpose, mimicking the raw, functional beauty of a digital Jumbotron.

## Colors
The palette is built on a high-contrast foundation to ensure maximum readability in outdoor or high-glare environments. 

- **Primary Background (#1A6B00):** A deep, saturated pitch green that provides the field of play for all content.
- **Primary Action & Headings (#F5C800):** A bold, energetic yellow used for scores, primary headlines, and calls to action.
- **Typography & Details (#FFFFFF):** Pure white is reserved for body copy and secondary information to maintain a clean hierarchy against the green.
- **Accents & Structure (#0D0D0D):** A deep black used for borders, icons, and the Floating Action Button (FAB) to provide heavy visual weight and grounding.
- **Alert & Danger (#FF4C4C):** A vibrant red used exclusively for wickets, penalties, and critical errors.

Status bar icons must remain white to contrast against the green header.

## Typography
This design system utilizes a dual-font strategy. **Rajdhani** is used for all headlines and numerical data (scores/stats) to evoke a technical, scoreboard feel. **DM Sans** provides a neutral, highly legible contrast for long-form text and secondary labels.

- **Headlines:** Always Bold (700). Larger display sizes should utilize uppercase to maximize the "stadium" aesthetic.
- **Scores:** Use the `display-score` token for primary match results.
- **Body:** Use `body-md` for standard descriptions and news snippets.
- **Interactive Labels:** Use `label-lg` in uppercase for buttons and navigation items to ensure they feel like distinct UI triggers.

## Layout & Spacing
The layout follows a strict **Fixed Grid** model for mobile devices, moving to a multi-column fluid grid for larger screens. 

- **Grid:** 12-column system on desktop, 4-column system on mobile.
- **Rhythm:** An 8px base unit governs all spacing.
- **Safe Areas:** All interactive elements (buttons, inputs, list items) must maintain a minimum hit target of **48dp** to ensure usability during high-intensity movement.
- **Margins:** A consistent 20px screen margin is required for all views.

## Elevation & Depth
Depth in this design system is purely structural. It avoids all shadows and blurs.

- **Stacking:** Use **Bold Borders** (2px solid black) to separate content sections.
- **Tonal Tiers:** Surfaces sit directly on the Primary Background. Cards and containers use the same background color but are defined by a 2px black stroke.
- **Hierarchy:** High-priority items are denoted by a Bold Yellow (#F5C800) background with Black text, making them appear "closer" to the user through color vibration rather than shadows.

## Shapes
The shape language is predominantly **Sharp (0px)** to reinforce the brutalist, scoreboard aesthetic. 

- **Containers/Cards:** 0px radius with 2px black border.
- **Exceptions:** The "Sign in with Google" button uses a 10px radius per specific brand requirement.
- **FAB:** A perfect circle (radius 50%).
- **Interactive States:** Use a hard color shift (e.g., from Yellow to White) to indicate hover or press, rather than a shape change.

## Components
Consistent implementation of components is vital to maintaining the high-contrast aesthetic.

- **Buttons (Primary):** Solid Yellow (#F5C800) background, Black (#0D0D0D) text, 0px radius. Height: 48dp.
- **Buttons (Outline):** Green background, 2px White stroke, White text.
- **FAB:** 56dp Black circle sitting at the center of the bottom navigation. Icons inside are Bold Yellow.
- **Bottom Navigation:** Solid Black (#0D0D0D) bar containing 5 items. The center slot is reserved for the FAB. Icons are white when inactive, yellow when active.
- **Cards/List Items:** Green background with a 2px solid Black border. 0px corner radius. Minimum height 64dp for lists.
- **Input Fields:** Black background, 2px Yellow border when focused, White text. 0px radius.
- **Chips:** Solid White background with Black text. 0px radius. Used for player tags or categories.
- **Chips (Wicket/Danger):** Solid Red (#FF4C4C) background with White text.