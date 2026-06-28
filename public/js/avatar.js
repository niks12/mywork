const CONFIG_PATH = "avatars/priya/config.json";

const avatarRing = document.getElementById("avatarRing");
const speakingIndicator = document.getElementById("speakingIndicator");
const avatarName = document.getElementById("avatarName");
const avatarDescription = document.getElementById("avatarDescription");
const languageBadges = document.getElementById("languageBadges");
const languageSwitcher = document.getElementById("languageSwitcher");
const messages = document.getElementById("messages");
const composer = document.getElementById("composer");
const messageInput = document.getElementById("messageInput");
const greetBtn = document.getElementById("greetBtn");
const speakBtn = document.getElementById("speakBtn");
const voiceHint = document.getElementById("voiceHint");

let avatarConfig = null;
let currentLocale = null;
let availableVoices = [];
let activeUtterance = null;

function waitForVoices() {
  return new Promise((resolve) => {
    const voices = window.speechSynthesis.getVoices();
    if (voices.length) {
      resolve(voices);
      return;
    }

    window.speechSynthesis.onvoiceschanged = () => {
      resolve(window.speechSynthesis.getVoices());
    };
  });
}

function pickVoice(localeConfig) {
  const femaleHints = ["female", "woman", "neerja", "swara", "dhwani", "priya", "heera", "kajal"];

  const candidates = [
  localeConfig.speechLang,
  localeConfig.fallbackSpeechLang,
  localeConfig.code,
  ].filter(Boolean);

  for (const lang of candidates) {
    const exactMatches = availableVoices.filter((voice) => voice.lang.toLowerCase().startsWith(lang.toLowerCase()));
    if (!exactMatches.length) continue;

    const femaleVoice = exactMatches.find((voice) =>
      femaleHints.some((hint) => voice.name.toLowerCase().includes(hint))
    );

    return femaleVoice || exactMatches[0];
  }

  return null;
}

function setSpeakingState(isSpeaking) {
  avatarRing.classList.toggle("speaking", isSpeaking);
  speakingIndicator.hidden = !isSpeaking;
  speakBtn.disabled = isSpeaking;
  greetBtn.disabled = isSpeaking;
}

function addMessage(role, text, localeCode) {
  const locale = avatarConfig.supportedLocales.find((item) => item.code === localeCode);
  const bubble = document.createElement("article");
  bubble.className = `message ${role}`;

  const meta = document.createElement("span");
  meta.className = "message-meta";
  meta.textContent = role === "assistant"
    ? `${avatarConfig.displayName} · ${locale?.name || localeCode}`
    : `You · ${locale?.name || localeCode}`;

  const body = document.createElement("div");
  body.textContent = text;

  bubble.append(meta, body);
  messages.appendChild(bubble);
  messages.scrollTop = messages.scrollHeight;
}

function speak(text, localeCode) {
  if (!text.trim() || !window.speechSynthesis) {
    voiceHint.textContent = "Speech synthesis is not available in this browser.";
    return Promise.resolve();
  }

  const localeConfig = avatarConfig.supportedLocales.find((item) => item.code === localeCode);
  const voice = pickVoice(localeConfig);
  const prefs = avatarConfig.voicePreferences[localeCode] || {};

  window.speechSynthesis.cancel();

  return new Promise((resolve) => {
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = voice?.lang || localeConfig.speechLang;
    utterance.pitch = prefs.pitch ?? 1;
    utterance.rate = prefs.rate ?? 1;
    if (voice) utterance.voice = voice;

    utterance.onstart = () => {
      activeUtterance = utterance;
      setSpeakingState(true);
    };

    utterance.onend = () => {
      activeUtterance = null;
      setSpeakingState(false);
      resolve();
    };

    utterance.onerror = () => {
      activeUtterance = null;
      setSpeakingState(false);
      resolve();
    };

    window.speechSynthesis.speak(utterance);
  });
}

function renderLanguageControls() {
  languageBadges.innerHTML = "";
  languageSwitcher.innerHTML = "";

  for (const locale of avatarConfig.supportedLocales) {
    const badge = document.createElement("span");
    badge.className = "badge";
    badge.textContent = `${locale.name} (${locale.nativeName})`;
    languageBadges.appendChild(badge);

    const button = document.createElement("button");
    button.type = "button";
    button.className = `lang-btn${locale.code === currentLocale ? " active" : ""}`;
    button.dataset.locale = locale.code;
    button.setAttribute("role", "tab");
    button.setAttribute("aria-selected", locale.code === currentLocale ? "true" : "false");
    button.innerHTML = `${locale.name}<small>${locale.nativeName}</small>`;
    button.addEventListener("click", () => switchLocale(locale.code));
    languageSwitcher.appendChild(button);
  }
}

function switchLocale(localeCode) {
  currentLocale = localeCode;
  const locale = avatarConfig.supportedLocales.find((item) => item.code === localeCode);
  messageInput.placeholder = locale.placeholder;
  renderLanguageControls();
}

async function greet() {
  const locale = avatarConfig.supportedLocales.find((item) => item.code === currentLocale);
  addMessage("assistant", locale.greeting, currentLocale);
  await speak(locale.greeting, currentLocale);
}

async function init() {
  const response = await fetch(CONFIG_PATH);
  avatarConfig = await response.json();
  currentLocale = avatarConfig.defaultLocale;

  avatarName.textContent = avatarConfig.displayName;
  avatarDescription.textContent = avatarConfig.description;

  availableVoices = await waitForVoices();
  renderLanguageControls();
  switchLocale(currentLocale);

  const voice = pickVoice(avatarConfig.supportedLocales[0]);
  voiceHint.textContent = voice
    ? `Ready to speak. Current voice: ${voice.name} (${voice.lang}).`
    : "No dedicated voice found for this language yet; browser fallback will be used.";

  greetBtn.addEventListener("click", greet);

  composer.addEventListener("submit", async (event) => {
    event.preventDefault();
    const text = messageInput.value.trim();
    if (!text) return;

    addMessage("user", text, currentLocale);
    messageInput.value = "";
    await speak(text, currentLocale);
    addMessage("assistant", text, currentLocale);
  });

  await greet();
}

init().catch((error) => {
  voiceHint.textContent = `Failed to load avatar: ${error.message}`;
});
