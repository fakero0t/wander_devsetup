const API_BASE = import.meta.env.VITE_API_URL || 'http://localhost:4000';

export async function apiGet<T>(path: string): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(`${API_BASE}${path}`, { signal: controller.signal });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

export async function apiPost<T>(path: string, data: any): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
      signal: controller.signal
    });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

export async function apiPut<T>(path: string, data: any): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
      signal: controller.signal
    });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

export async function apiDelete<T>(path: string): Promise<T> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(`${API_BASE}${path}`, {
      method: 'DELETE',
      signal: controller.signal
    });
    clearTimeout(timeout);
    if (!res.ok) throw new Error(await res.text());
    return res.json();
  } catch (error) {
    clearTimeout(timeout);
    throw error;
  }
}

