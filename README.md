# Quality Toggle

A small Factorio 2.1 mod that lets an admin turn **quality ON or OFF** at runtime with a single shortcut button.

Handy when you dont want to double-click in all UIs before having even crated a single quality item.

---

## Features

- **Shortcut button** — adds a toggleable button to the shortcut bar.
- **Admin-only** — only admins can flip quality on/off. Non-admins who click it get an info message and nothing changes.
- **Per-force** — each force has its own visibility state, so different teams can be configured independently.
- **Remembers unlocks** — the qualities a force has actually unlocked (through research) are tracked by the mod, so toggling never grants qualities a force hasn't earned.
- **Respects new unlocks** — if a force is toggled OFF and later researches a new quality level, that level is immediately hidden too. Toggle back ON and everything the force unlocked reappears.

## How it works

- When quality is toggled **OFF**, every unlocked quality level above *normal* is locked for that force — hidden from the GUI and unusable.
- When toggled **ON**, all of that force's previously unlocked levels are made accessible again.

---

*Join my [Discord](https://discord.gg/pq6bWs8KTY)*
