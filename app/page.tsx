"use client";

import { useEffect, useState } from "react";

type Item = { id: number; text: string; votes: number; created_at: number };

export default function Page() {
  const [items, setItems] = useState<Item[]>([]);
  const [text, setText] = useState("");

  async function load() {
    const res = await fetch("/api/feedback", { cache: "no-store" });
    setItems(await res.json());
  }

  useEffect(() => { load(); }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!text.trim()) return;
    await fetch("/api/feedback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text }),
    });
    setText(""); load();
  }

  async function upvote(id: number) {
    await fetch(`/api/feedback/${id}/upvote`, { method: "POST" });
    load();
  }

  return (
    <main className="mx-auto max-w-xl p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Tiny Feedback Board</h1>
      <form onSubmit={submit} className="flex gap-2">
        <input
          className="flex-1 border rounded px-3 py-2"
          placeholder="Leave feedback…"
          value={text}
          onChange={(e) => setText(e.target.value)}
        />
        <button className="border rounded px-4 py-2" type="submit">Post</button>
      </form>
      <ul className="space-y-3">
        {items.map((it) => (
          <li key={it.id} className="border rounded p-3 flex justify-between">
            <span>{it.text}</span>
            <button className="text-sm" onClick={() => upvote(it.id)}>
              ▲ {it.votes}
            </button>
          </li>
        ))}
      </ul>
    </main>
  );
}

