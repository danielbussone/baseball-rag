import { pipeline } from '@xenova/transformers';

let embedder: any = null;

export async function initializeEmbedder() {
  console.log('Loading embedding model (all-mpnet-base-v2)...');
  embedder = await pipeline(
    'feature-extraction',
    'Xenova/all-mpnet-base-v2'
  );
  console.log('✓ Embedding model loaded');
}

export async function generateEmbedding(text: string): Promise<number[]> {
  if (!embedder) {
    await initializeEmbedder();
  }

  const output = await embedder(text, { pooling: 'mean', normalize: true });
  return Array.from(output.data);
}

export async function generateEmbeddingsBatch(texts: string[]): Promise<number[][]> {
  if (!embedder) {
    await initializeEmbedder();
  }

  const embeddings: number[][] = [];
  for (const text of texts) {
    const embedding = await generateEmbedding(text);
    embeddings.push(embedding);
  }
  return embeddings;
}
