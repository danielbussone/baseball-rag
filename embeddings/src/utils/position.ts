export function getPositionDescription(position: string): string {
  const posMap: Record<string, string> = {
    'C': 'at catcher',
    'SS': 'at shortstop',
    'CF': 'in center field',
    '2B': 'at second base',
    '3B': 'at third base',
    'RF': 'in right field',
    'LF': 'in left field',
    '1B': 'at first base',
    'DH': 'as a designated hitter',
    'SS/2B': 'as a middle infielder',
    '2B/SS': 'as a middle infielder',
    'SS/2B/CF': 'as an up the middle defender',
    'CF/SS/2B': 'as an up the middle defender',
    '1B/3B': 'as a corner infielder',
    '3B/1B': 'as a corner infielder',
    '1B/2B/3B/SS': 'as a utility infielder',
    '2B/3B/SS/1B': 'as a utility infielder',
    '1B/3B/OF': 'as a corner guy',
    '3B/1B/OF': 'as a corner guy',
    '1B/OF': 'as a corner guy',
    'OF/1B': 'as a corner guy',
    '2B/3B/OF': 'as a utility player',
    '3B/2B/OF': 'as a utility player',
    'OF': 'as an outfielder',
    'IF': 'as an infielder',
  };

  return posMap[position] || `at ${position}`;
}

export function isPremiumDefensivePosition(position: string): boolean {
  const premium = ['C', 'SS', 'CF', '2B'];
  return premium.some(p => position.includes(p));
}

export function getFieldingDescription(
  grade: number | null,
  position: string,
  fieldingRuns: number
): string {
  if (grade === null) {
    return "Did not field (DH)";
  }

  const posDesc = getPositionDescription(position);

  if (grade >= 80) {
    return `All-time great defender ${posDesc} (+${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 70) {
    return `Gold Glove caliber ${posDesc} (+${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 60) {
    return `One of the better defenders ${posDesc} (+${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 55) {
    return `Slightly above average defender ${posDesc} (+${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 50) {
    return `Solid defender ${posDesc} (${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 45) {
    return `Fringy defender ${posDesc} (${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 40) {
    return `Below average defender ${posDesc} (${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else if (grade >= 30) {
    return `Defensive liability ${posDesc} (${Number(fieldingRuns).toFixed(1)} outs above average)`;
  } else {
    return `Extremely poor, borderline unplayable defender ${posDesc} (${Number(fieldingRuns).toFixed(1)} outs above average)`;
  }
}
