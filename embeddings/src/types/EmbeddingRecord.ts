export interface EmbeddingRecord {
  player_season_id: string;
  fangraphs_id: number;
  year: number;
  embedding_type: string;
  summary_text: string;
  embedding: number[];
  metadata: Record<string, any>;
}
