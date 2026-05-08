import admin from "firebase-admin";
import { readFileSync } from "fs";

// --- Config ---
const SERVICE_ACCOUNT_PATH = "../serviceAccountKey.json";
const WORDS_PER_LESSON = 7;
const WORDS_PER_TOPIC = 150;

// --- Keywords for each topic ---
const TOPIC_KEYWORDS = {
  topic_education: [
    "school", "university", "college", "student", "teacher", "professor",
    "learn", "study", "educat", "academic", "classroom", "lecture", "exam",
    "test", "grade", "diploma", "degree", "curriculum", "course", "lesson",
    "homework", "assignment", "research", "scholar", "tutor", "campus",
    "library", "knowledge", "skill", "train", "instruct", "teach",
    "graduate", "undergraduate", "semester", "syllabus", "thesis",
    "dissertation", "enroll", "literacy", "pedagog", "mentor", "pupil",
    "textbook", "certificate", "qualification", "workshop", "seminar",
  ],
  topic_food: [
    "food", "cook", "eat", "meal", "dish", "recipe", "ingredient",
    "kitchen", "restaurant", "chef", "bake", "fry", "boil", "grill",
    "roast", "flavor", "taste", "delicious", "appetit", "breakfast",
    "lunch", "dinner", "snack", "dessert", "fruit", "vegetable", "meat",
    "fish", "bread", "rice", "soup", "sauce", "spice", "sugar", "salt",
    "butter", "cheese", "cream", "beverage", "drink", "coffee", "tea",
    "wine", "beer", "juice", "hungry", "thirst", "nutrition", "diet",
    "organic", "cuisine", "menu", "serve", "plate", "bowl", "fork",
  ],
  topic_health: [
    "health", "medical", "doctor", "hospital", "patient", "disease",
    "illness", "sick", "medicine", "drug", "treatment", "therapy",
    "symptom", "diagnos", "surgery", "nurse", "clinic", "pain",
    "injur", "wound", "blood", "heart", "brain", "lung", "bone",
    "muscle", "exercise", "fitness", "diet", "mental", "stress",
    "anxiety", "depress", "sleep", "immune", "infect", "virus",
    "bacteria", "vaccine", "pill", "prescri", "pharmacy", "dental",
    "vision", "blind", "deaf", "disab", "recover", "heal", "wellness",
  ],
  topic_it: [
    "computer", "software", "hardware", "program", "code", "coding",
    "develop", "algorithm", "data", "database", "server", "network",
    "internet", "web", "website", "app", "application", "digital",
    "technolog", "system", "encrypt", "cyber", "hack", "cloud",
    "artificial", "intelligen", "machine learn", "robot", "automat",
    "processor", "memory", "storage", "download", "upload", "online",
    "virtual", "browser", "email", "password", "security", "firewall",
    "debug", "compile", "deploy", "API", "interface", "device", "mobile",
  ],
  topic_travel: [
    "travel", "trip", "journey", "tour", "tourist", "vacation", "holiday",
    "flight", "airport", "airline", "passport", "visa", "luggage",
    "baggage", "hotel", "hostel", "resort", "booking", "reserv",
    "destin", "sightsee", "adventure", "explor", "cruise", "ferry",
    "train", "railway", "bus", "taxi", "transport", "road", "highway",
    "map", "guide", "souvenir", "beach", "mountain", "island", "foreign",
    "abroad", "immigra", "customs", "border", "depart", "arriv",
    "itinerary", "backpack", "camp", "hike", "landmark", "monument",
  ],
};

// --- Initialize Firebase ---
const serviceAccount = JSON.parse(readFileSync(SERVICE_ACCOUNT_PATH, "utf8"));
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// --- Fetch all vocabularies ---
async function fetchAllWords() {
  console.log("Fetching all words from Firestore...");
  const snapshot = await db.collection("vocabularies").get();
  const words = snapshot.docs.map((doc) => ({
    id: doc.id,
    word: doc.data().word || "",
    definition: doc.data().definition || "",
    type: doc.data().type || "",
  }));
  console.log(`Fetched ${words.length} words.`);
  return words;
}

// --- Classify word by keywords ---
function classifyWord(word, keywords) {
  const text = `${word.word} ${word.definition}`.toLowerCase();
  let score = 0;
  for (const keyword of keywords) {
    if (text.includes(keyword.toLowerCase())) {
      score++;
    }
  }
  return score;
}

// --- Create lessons in Firestore ---
async function createLessons(topicId, wordIds) {
  const lessonsRef = db.collection("topics").doc(topicId).collection("lessons");

  // Delete existing lessons
  const existing = await lessonsRef.get();
  if (!existing.empty) {
    const batch = db.batch();
    existing.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
  }

  // Create new lessons
  const totalLessons = Math.ceil(wordIds.length / WORDS_PER_LESSON);
  for (let i = 0; i < totalLessons; i++) {
    const lessonWordIds = wordIds.slice(i * WORDS_PER_LESSON, (i + 1) * WORDS_PER_LESSON);
    const lessonId = `lesson_${String(i + 1).padStart(2, "0")}`;

    await lessonsRef.doc(lessonId).set({
      title: `Lesson ${i + 1}`,
      order: i + 1,
      totalWords: lessonWordIds.length,
      wordIds: lessonWordIds,
    });
  }

  // Update topic document
  await db.collection("topics").doc(topicId).update({
    totalLessons: totalLessons,
    totalWords: wordIds.length,
  });

  console.log(`  -> Created ${totalLessons} lessons (${wordIds.length} words)`);
}

// --- Main ---
async function main() {
  try {
    const allWords = await fetchAllWords();
    const usedIds = new Set();

    for (const [topicId, keywords] of Object.entries(TOPIC_KEYWORDS)) {
      console.log(`\nClassifying: ${topicId}...`);

      // Score each word
      const scored = allWords
        .filter((w) => !usedIds.has(w.id))
        .map((w) => ({ id: w.id, word: w.word, score: classifyWord(w, keywords) }))
        .filter((w) => w.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, WORDS_PER_TOPIC);

      // Mark as used so no duplicates across topics
      scored.forEach((w) => usedIds.add(w.id));

      const selectedIds = scored.map((w) => w.id);
      console.log(`  Selected ${selectedIds.length} words (top matches)`);

      if (selectedIds.length > 0) {
        await createLessons(topicId, selectedIds);
      } else {
        console.log(`  No words matched for ${topicId}`);
      }
    }

    console.log("\nDone! All topics have been populated with lessons.");
    process.exit(0);
  } catch (error) {
    console.error("Error:", error);
    process.exit(1);
  }
}

main();
