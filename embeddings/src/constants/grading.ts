export const GRADE_DESCRIPTORS: Record<number, string> = {
  80: "elite",
  70: "exceptional",
  60: "plus",
  55: "above average",
  50: "average",
  45: "fringe average",
  40: "below average",
  30: "poor",
  20: "extremely poor"
} as const;

export const GRADE_DESCRIPTORS_VERBOSE: Record<number, string> = {
  80: "generational, elite, otherworldly, best in baseball",
  70: "exceptional, plus-plus, excellent, fantastic",
  60: "strong, plus, very good",
  55: "solid, above average, good",
  50: "average, league average, MLB regular",
  45: "slight negative, fringe average, fringey",
  40: "below average, replacement level, questionable, negative",
  30: "poor, well below MLB standard, bad",
  20: "extremely poor, unplayable, terrible"
} as const;

export const FIELDING_DESCRIPTORS: Record<number, string> = {
  80: "all-time great defender, defensive wizard",
  70: "Gold Glove caliber defender",
  60: "one of the better defenders at his position",
  55: "above average defender",
  50: "solid defender, average",
  45: "adequate defender, fringy",
  40: "below average defender, questionable",
  30: "poor defender, liability",
  20: "extremely poor defender, unplayable"
} as const;
