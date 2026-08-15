---
name: BlazeDrop High-Performance Utility
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#3a3939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#ffb693'
  on-secondary: '#561f00'
  secondary-container: '#fe6b00'
  on-secondary-container: '#572000'
  tertiary: '#baffa2'
  on-tertiary: '#053900'
  tertiary-container: '#2cf100'
  on-tertiary-container: '#0e6800'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#ffdbcc'
  secondary-fixed-dim: '#ffb693'
  on-secondary-fixed: '#351000'
  on-secondary-fixed-variant: '#7a3000'
  tertiary-fixed: '#79ff5b'
  tertiary-fixed-dim: '#2ae500'
  on-tertiary-fixed: '#022100'
  on-tertiary-fixed-variant: '#095300'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 72px
    fontWeight: '900'
    lineHeight: 72px
    letterSpacing: -0.04em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '800'
    lineHeight: 30px
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
  code-sm:
    fontFamily: Space Grotesk
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
spacing:
  unit: 4px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 40px
  container-max: 1440px
---

## Brand & Style
This design system embodies a "Cyber-Utility" aesthetic—merging the raw, high-contrast energy of gaming interfaces with the precision of professional cybersecurity tools. The brand personality is aggressive, unapologetic, and hyper-functional. It prioritizes speed of thought and action, utilizing a Dark-Mode-First approach to reduce eye strain during high-intensity tasks while allowing vibrant accents to dictate the user's focus.

The visual style leans into **Modern Brutalism** mixed with **Neon-Glow** accents. Expect heavy strokes, sharp corners, and a total absence of traditional soft shadows. Depth is created through luminosity and layered outlines rather than physical skeuomorphism. The interface should feel like a high-end command deck: dense with information but perfectly organized for split-second navigation.

## Colors
The palette is built on a foundation of "Deep Charcoal" (#0D0D0D) to provide infinite depth. 

- **Primary (Electric Cyan):** Used for interactive states, primary navigation, and "Active" status. It represents the flow of data.
- **Secondary (Vibrant Orange):** Reserved strictly for critical calls to action (CTAs), destructive actions, and active progress tracking. It creates a high-alert visual priority.
- **Success (Neon Green):** Used for completed uploads and verified security pings.
- **Surface & Borders:** Backgrounds use a slightly lifted charcoal (#1A1A1A) for containers. Borders are high-contrast; use the primary or secondary colors at 30-50% opacity for "glowing" border effects on active elements.

## Typography
The typography is built for maximum legibility under pressure. We use **Inter** for all functional text to ensure clarity, while **Space Grotesk** is introduced for technical labels and data-heavy readouts to lean into the futuristic, geometric vibe.

Headlines should be set with tight letter-spacing and heavy weights (800+) to feel "massive" and structural. Use `label-caps` for all non-content metadata, such as file sizes, timestamps, and transfer protocols. For mobile, scale display text aggressively to maintain the "punchy" aesthetic without overflowing the viewport.

## Layout & Spacing
The layout follows a strict **4px baseline grid** to ensure mathematical precision. We utilize a **12-column fluid grid** for desktop and a **4-column grid** for mobile.

- **Gutters:** Standardized at 16px to keep information density high.
- **Margins:** 40px on desktop to provide a "framed" cockpit feel; 16px on mobile.
- **Component Density:** Padding within components should be tight (e.g., 8px or 12px) to minimize wasted space, reflecting the "Zero Clutter" requirement. Elements should be aligned to the grid with hard edges; avoid centered layouts in favor of strong left-aligned "stacks."

## Elevation & Depth
Elevation in this design system is conveyed through **Luminance and Stroke**, not shadows.

1.  **Level 0 (Base):** Deep Charcoal (#0D0D0D).
2.  **Level 1 (Surface):** Lightened Charcoal (#1A1A1A) with a 1px solid border (#333333).
3.  **Level 2 (Active/Hover):** Surface color with an inner glow or a primary-colored stroke (1px or 2px).
4.  **Level 3 (Overlay):** Floating panels use a 2px Electric Cyan border with a subtle 10px outer blur of the same color to simulate a neon hardware glow.

Avoid all "soft" drop shadows. If an element needs to feel "above" another, increase the border-contrast or use a semi-transparent Cyan/Orange tint on the background.

## Shapes
The shape language is strictly **Sharp (0px)**. All buttons, containers, input fields, and chips must have 90-degree corners. This reinforces the architectural, technical feel of the software.

- **Exceptions:** Very small icons or progress bars may use a 1px radius if rendering issues occur at small scales, but the visual intent is always a "hard edge."
- **Interactive States:** Use "clipped corner" effects (achieved via CSS clip-path) for primary buttons to add to the cyberpunk hardware aesthetic.

## Components

- **Buttons:** 
  - *Primary:* Solid Electric Cyan background, black text, heavy weight. On hover, add a 4px offset "ghost" border.
  - *Secondary (CTA):* Solid Vibrant Orange background. Use for "Upload" or "Send."
  - *Outline:* 2px stroke, no fill. Text matches stroke color.
- **Input Fields:** Dark background (#050505), 1px border (#333333). On focus, the border turns Electric Cyan with a subtle 2px outer glow.
- **Progress Bars:** 
  - *Track:* Dark grey (#222). 
  - *Fill:* Vibrant Orange. Use a "striped" or "segmented" pattern to indicate high-speed movement.
- **Cards/Containers:** No rounded corners. 1px border. Header areas of cards should have a distinct background color (#252525) and use `label-caps` for titles.
- **Chips/Status Tags:** Square edges. Use high-contrast fills (Cyan for "Online", Green for "Secure").
- **Icons:** Thick-stroke (2pt minimum) outlined icons. Do not use filled icons unless they are active/toggled.
- **Additional Component: "The HUD Terminal":** A sticky footer or sidebar that displays real-time transfer logs in `code-sm` typography, mimicking a developer console.