# Tschichold — Die neue Typographie

## Origin

Jan Tschichold, *Die neue Typographie* (1928) and *Typographische Gestaltung /
Asymmetric Typography* (1935). The manifesto of the **New Typography**: function
over tradition, asymmetry over the centered axis, sans-serif over blackletter.
Born from Bauhaus and Constructivist energy, it weaponizes **white space and a
strong left axis** as active compositional forces. (Tschichold later recanted
toward classicism — see `classical-canons.md` — but the 1928 doctrine is captured here.)

## Grid Structure

Not a multi-column mesh but an **asymmetric two-part division**: a narrow active
column and a wide field, anchored hard to the left and balanced by deliberate
right-hand white.

| Property        | Value           | Notes                                 |
|-----------------|-----------------|---------------------------------------|
| Container       | 1296px          | 64 + field + 192                      |
| Division        | 3fr : 7fr       | Narrow rail + wide field              |
| Gutter          | 32px            | Single gutter between the two parts   |
| Margin (left)   | 64px            | Tight — establishes the left axis     |
| Margin (right)  | 192px           | Wide — the active white space         |
| Baseline        | 12px            | Leading is a multiple                 |

The asymmetry is the point: a **strong left axis** carries the eye, the broad
right margin is tension, not emptiness.

## Typography Rules

Sans-serif by conviction (though Tschichold was non-dogmatic about exact cuts):
**Akzidenz-Grotesk**, **Futura**. Weight and size, not italics or ornament,
create hierarchy.

| Role     | Size  | Leading | Weight             |
|----------|-------|---------|--------------------|
| Display  | 56px  | 60px    | Bold               |
| Heading  | 32px  | 36px    | Bold               |
| Subhead  | 21px  | 28px    | Medium             |
| Body     | 16px  | 24px    | Regular            |
| Caption  | 12px  | 16px    | Regular            |

**Hard rule: flush-left, ragged-right. Justification (both-edges) is forbidden** —
the ragged right edge keeps even word spacing and reinforces the left axis.

## Palette

The Constructivist trio:

| Token   | Hex      | Use                  |
|---------|----------|----------------------|
| Black   | `#000000`| Text, bars, rules    |
| White   | `#FFFFFF`| Active ground        |
| Red     | `#E2001A`| Single accent        |

Black, white, and one red — no fourth color.

## CSS Implementation

```css
:root {
  --tn-container: 1296px;
  --tn-rail: 3fr;
  --tn-field: 7fr;
  --tn-gutter: 32px;
  --tn-margin-left: 64px;
  --tn-margin-right: 192px;
  --tn-baseline: 12px;

  --tn-black: #000000;
  --tn-white: #FFFFFF;
  --tn-red:   #E2001A;

  --tn-font: "Akzidenz-Grotesk", Futura, "Helvetica Neue", Arial, sans-serif;
}

.tn-page {
  max-width: var(--tn-container);
  margin-inline: auto;
  padding-left: var(--tn-margin-left);   /* tight left axis */
  padding-right: var(--tn-margin-right); /* wide active white */
  background: var(--tn-white);
  color: var(--tn-black);
  font-family: var(--tn-font);
}

/* Asymmetric two-part division */
.tn-grid {
  display: grid;
  grid-template-columns: var(--tn-rail) var(--tn-gutter) var(--tn-field);
}
.tn-rail  { grid-column: 1; }
.tn-field { grid-column: 3; }

.tn-display { font: 700 56px/60px var(--tn-font); }
/* Justification is forbidden — always ragged-right */
.tn-body    { font: 400 16px/24px var(--tn-font); text-align: left; }
.tn-accent  { color: var(--tn-red); }

/* Constructivist accent bar */
.tn-bar { height: 8px; background: var(--tn-red); }
```

## Key Differentiators

- **Asymmetry as principle**, not column count — a 3:7 split, not a 12-column mesh.
- **Engineered margin imbalance:** tight 64px left, wide 192px right. The white
  is an active element, the opposite of symmetric Vignelli/Gerstner margins.
- **Justification banned.** Flush-left/ragged-right is mandatory — distinct from
  the justified blocks of `classical-canons.md`.
- **Slightly warmer red** (`#E2001A`) than the Vignelli/Gerstner `#E30613`,
  echoing Constructivist poster red.
- **Doctrinal sans-serif** as ideology, where the classical canon insists on serif.
