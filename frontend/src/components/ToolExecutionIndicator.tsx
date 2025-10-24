import { Box, Chip } from '@mui/material';
import type { ToolExecution } from '../types';

interface ToolExecutionIndicatorProps {
  toolExecutions: ToolExecution[];
}

const toolEmojis: Record<string, string> = {
  search_similar_players: '🔍',
  get_player_stats: '📊',
  compare_players: '⚖️',
  get_career_summary: '📈',
};

const toolLabels: Record<string, string> = {
  search_similar_players: 'Searching for similar players',
  get_player_stats: 'Getting player stats',
  compare_players: 'Comparing players',
  get_career_summary: 'Getting career summary',
};

function getToolLabel(tool: ToolExecution): string {
  const emoji = toolEmojis[tool.name] || '🔧';
  let label = `${emoji} ${toolLabels[tool.name] || tool.name}`;
  if (tool.status === 'completed') label += ' ✓';
  if (tool.status === 'error') label += ' ✗';
  if (tool.duration) label += ` (${tool.duration}ms)`;
  return label;
}

export default function ToolExecutionIndicator({ toolExecutions }: ToolExecutionIndicatorProps) {
  if (!toolExecutions || toolExecutions.length === 0) {
    return null;
  }

  return (
    <Box sx={{ mb: 1 }}>
      {toolExecutions.map((tool, index) => (
        <Chip
          key={index}
          label={getToolLabel(tool)}
          size="small"
          variant="outlined"
          sx={{
            mr: 0.5,
            mb: 0.5,
            bgcolor: tool.status === 'completed' ? 'success.50' : 
                     tool.status === 'error' ? 'error.50' : 'grey.100',
            borderColor: tool.status === 'completed' ? 'success.main' : 
                        tool.status === 'error' ? 'error.main' : 'grey.300',
          }}
        />
      ))}
    </Box>
  );
}