export const toolDefinitions = [
  {
    type: 'function',
    function: {
      name: 'search_similar_players',
      description: 'Search for baseball players with similar characteristics using semantic search and filters. Use the query for semantic meaning (e.g., "elite slugger") and filters for precise numerical constraints (e.g., minPowerGrade: 70).',
      parameters: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'Natural language description of the type of player to find (e.g., "elite power hitter", "defensive shortstop")'
          },
          filters: {
            type: 'object',
            description: 'Optional filters to narrow results. Only use the properties defined below - do not invent new filter fields.',
            properties: {
              position: { 
                type: 'string', 
                description: 'Player position (e.g., "1B", "SS", "OF")',
                enum: ['1B', '2B', '3B', 'SS', 'C', 'OF', 'LF', 'CF', 'RF', 'DH', 'P', 'SP', 'RP']
              },
              minWAR: { type: 'number', description: 'Minimum Wins Above Replacement value.' },
              maxWAR: { type: 'number', description: 'Maximum Wins Above Replacement value.' },
              minOverallGrade: { type: 'number', description: 'Minimum overall grade (20-80 scale).' },
              maxOverallGrade: { type: 'number', description: 'Maximum overall grade (20-80 scale).' },
              minHitGrade: { type: 'number', description: 'Minimum hit grade (20-80 scale). Hit grade correlates with contact ability. 70+ is elite, 55-60 is above average, 50 is average, 30- is poor.' },
              maxHitGrade: { type: 'number', description: 'Maximum hit grade (20-80 scale). Hit grade correlates with contact ability. 70+ is elite, 55-60 is above average, 50 is average, 30- is poor.' },
              minPowerGrade: { type: 'number', description: 'Minimum power grade (20-80 scale). Power grade correlates with slugging ability. 70+ is elite, 55-60 is above average, 50 is average, 30- is poor.' },
              maxPowerGrade: { type: 'number', description: 'Maximum power grade (20-80 scale). Power grade correlates with slugging ability. 70+ is elite, 55-60 is above average, 50 is average, 30- is poor.' },
              minFieldingGrade: { type: 'number', description: 'Minimum fielding grade (20-80 scale).' },
              maxFieldingGrade: { type: 'number', description: 'Maximum fielding grade (20-80 scale).' },
              minSpeedGrade: { type: 'number', description: 'Minimum speed grade (20-80 scale).' },
              maxSpeedGrade: { type: 'number', description: 'Maximum speed grade (20-80 scale).' },
              yearRange: { 
                type: 'array', 
                items: { type: 'number' },
                minItems: 2,
                maxItems: 2,
                description: 'Year range as [startYear, endYear]. Example: [2015, 2020] for 2015-2020 seasons'
              }
            }
          },
          limit: { type: 'number', description: 'Maximum number of results (default: 10)' }
        },
        required: ['query']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'get_player_stats',
      description: 'Get specific season stats for a player',
      parameters: {
        type: 'object',
        properties: {
          playerName: { type: 'string', description: 'Player name (partial matches allowed)' },
          year: { type: 'number', description: 'Specific year (optional, returns all seasons if omitted)' }
        },
        required: ['playerName']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'get_career_summary',
      description: 'Get career totals and summary statistics for a player',
      parameters: {
        type: 'object',
        properties: {
          playerName: { type: 'string', description: 'Player name (partial matches allowed)' }
        },
        required: ['playerName']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'compare_players',
      description: 'Compare two players side-by-side with career stats and analysis',
      parameters: {
        type: 'object',
        properties: {
          player1: { type: 'string', description: 'First player name' },
          player2: { type: 'string', description: 'Second player name' }
        },
        required: ['player1', 'player2']
      }
    }
  }
];