# Roblox Language Quest — Setup Guide

A language learning companion app that gates Roblox build stages behind vocabulary quizzes.
Supports **Spanish 🇪🇸** and **Arabic 🌙**.

---

## What You Need

- A GitHub account (github.com)
- A Netlify account (netlify.com) — connect it to your GitHub account
- A Roblox account with Roblox Studio installed

---

## 1. Create the GitHub Repository

1. Go to **github.com** and sign in
2. Click the **+** icon in the top right → **New repository**
3. Name it `roblox-language-quest`
4. Set it to **Public**
5. Check **Add a README file**
6. Click **Create repository**

---

## 2. Add the Project Files

You need to create three files directly in the GitHub web editor.

### Create `index.html`
1. In your repo, click **Add file → Create new file**
2. Name it `index.html`
3. Paste this content:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Roblox Language Quest</title>
    <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
    <script src="https://unpkg.com/react@18/umd/react.development.js"></script>
    <script src="https://unpkg.com/react-dom@18/umd/react-dom.development.js"></script>
  </head>
  <body>
    <div id="root"></div>
    <script type="text/babel" data-type="module" src="./App.jsx"></script>
  </body>
</html>
```

4. Click **Commit new file**

### Create `App.jsx`
1. Click **Add file → Create new file**
2. Name it `App.jsx`
3. Paste the full contents of the `App.jsx` file provided in this project
4. Click **Commit new file**

### Create `netlify.toml`
1. Click **Add file → Create new file**
2. Name it `netlify.toml`
3. Paste this content:

```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

4. Click **Commit new file**

---

## 3. Deploy to Netlify

1. Go to **netlify.com** and sign in
2. Click **Add new site → Import an existing project**
3. Click **GitHub** and authorize Netlify if prompted
4. Select your `roblox-language-quest` repository
5. Leave all build settings blank (no build command needed)
6. Click **Deploy site**

Netlify will give you a live URL like `https://your-site-name.netlify.app`.

Every time you edit a file on GitHub and commit it, Netlify will automatically redeploy within about 30 seconds.

---

## 4. Edit Files Later

To update vocabulary, add units, or change anything:

1. Go to your repo on github.com
2. Click on `App.jsx`
3. Click the **pencil icon** (Edit this file) in the top right
4. Make your changes
5. Click **Commit changes**

Netlify picks up the change automatically — no terminal needed.

---

## 5. Set Up Roblox Studio

### Create the Parts
In Roblox Studio, add these named Parts to your Workspace:

| Part Name       | Purpose                        |
|-----------------|--------------------------------|
| `Door_Unit2`    | Wall between Zone 1 and Zone 2 |
| `Door_Unit3`    | Wall between Zone 2 and Zone 3 |
| `Terminal_Unit2`| Code entry terminal near Door 2|
| `Terminal_Unit3`| Code entry terminal near Door 3|

Make the Door parts solid colored walls (CanCollide = true).
Make the Terminal parts a bright color so students can find them easily.

### Add the Unlock Script
1. In Roblox Studio, go to **StarterPlayer → StarterPlayerScripts**
2. Right-click → **Insert Object → LocalScript**
3. Open the script and paste the full contents of `roblox-unlock.lua`
4. Update the `VALID_CODES` table with codes generated from your Netlify app

### Test It
- Click **Play** in Roblox Studio
- Walk up to `Terminal_Unit2`
- Enter a valid code from `VALID_CODES`
- The door should animate upward

---

## 6. Student Workflow

1. Student goes to your Netlify URL
2. Enters their name and class code
3. Selects a language (Spanish or Arabic)
4. Studies vocabulary flashcards
5. Passes the quiz at 80% or higher
6. Copies the unlock code shown on screen
7. Opens Roblox, walks to the terminal, enters the code
8. Door opens — next zone unlocked

---

## 7. Generating Unlock Codes for Your Class

The app generates a unique code per student based on their name, language, unit, and score.
For the MVP, pre-generate codes for your class roster and paste them into the `VALID_CODES`
section of `roblox-unlock.lua`.

You can generate a code manually by opening your browser console on the Netlify site and running:

```js
function generateCode(name, lang, unit, score) {
  let hash = 0;
  const str = `${name.toLowerCase().trim()}-${lang}-unit${unit}-${score}`;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash + str.charCodeAt(i)) | 0;
  }
  const abs = Math.abs(hash).toString(36).toUpperCase().padStart(6, "0");
  return `RBX-${abs.slice(0, 3)}-${abs.slice(3, 6)}`;
}

// Example: Maria, Spanish, Unit 1, score of 5
generateCode("Maria", "es", 1, 5);
```

---

## Expansion Roadmap

| Phase | Feature |
|-------|---------|
| v1 (now) | Spanish + Arabic, browser-only, no backend |
| v2 | Add Supabase for student progress tracking |
| v2 | Teacher dashboard using Supabase class_summary view |
| v3 | Audio pronunciation on flashcards |
| v3 | Writing mode — type the word instead of multiple choice |
| v4 | Additional languages |
