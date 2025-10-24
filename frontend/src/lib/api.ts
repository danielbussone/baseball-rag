import type { ChatResponse } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001';

/**
 * Sends a chat message to the backend API
 * @param message - The user's message text
 * @returns Promise resolving to the API response containing the assistant's reply
 * @throws Error if the API request fails or returns an error status
 *
 * @example
 * ```ts
 * const response = await sendChatMessage("Compare Mike Trout and Ken Griffey Jr");
 * console.log(response.response); // Assistant's reply
 * ```
 */
export async function sendChatMessage(message: string): Promise<ChatResponse> {
  const response = await fetch(`${API_BASE_URL}/api/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ message }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Unknown error' }));
    throw new Error(error.error || `HTTP ${response.status}: ${response.statusText}`);
  }

  return response.json();
}
