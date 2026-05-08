import admin from "firebase-admin";
import { readFileSync } from "fs";

const serviceAccount = JSON.parse(readFileSync("../serviceAccountKey.json", "utf8"));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function check() {
  const topic = process.argv[2] || "topic_it";
  const lessonNum = process.argv[3] || "all";

  // Fetch all vocabularies for lookup
  const vocabSnap = await db.collection("vocabularies").get();
  const vocabMap = new Map();
  vocabSnap.docs.forEach((doc) => {
    vocabMap.set(doc.id, doc.data().word);
  });

  // Fetch lessons
  const lessonsSnap = await db
    .collection("topics")
    .doc(topic)
    .collection("lessons")
    .orderBy("order")
    .get();

  console.log(`\n=== ${topic} (${lessonsSnap.size} lessons) ===\n`);

  lessonsSnap.docs.forEach((doc) => {
    const data = doc.data();
    if (lessonNum !== "all" && doc.id !== `lesson_${lessonNum.padStart(2, "0")}`) return;

    console.log(`${doc.id}: ${data.title}`);
    data.wordIds.forEach((id, i) => {
      const word = vocabMap.get(id) || "(not found)";
      console.log(`  ${i + 1}. ${word} [${id}]`);
    });
    console.log("");
  });

  process.exit(0);
}

check();
