import {onValueCreated} from "firebase-functions/v2/database";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import {database} from "firebase-functions/v2";

admin.initializeApp();

exports.sendNotificationOnNewPost = onValueCreated(
  "/streams/{classId}/{postId}",
  async (event: database.DatabaseEvent<database.DataSnapshot>) => {
    const post = event.data.val();
    const classId = event.params.classId;

    logger.info(`New post in class ${classId}`, {post});

    // 1. Find all students enrolled in the class from student_profiles
    const studentProfilesRef = admin.database().ref("student_profiles");
    const studentsSnapshot = await studentProfilesRef
      .orderByChild("classId")
      .equalTo(classId)
      .once("value");

    if (!studentsSnapshot.exists()) {
      logger.info("No students found for class", classId);
      return;
    }

    const studentUids: string[] = [];
    studentsSnapshot.forEach((studentSnapshot) => {
      if (studentSnapshot.key) {
        studentUids.push(studentSnapshot.key);
      }
    });

    if (studentUids.length === 0) {
      logger.info("Could not extract UIDs for students in class", classId);
      return;
    }

    logger.info(`Found ${studentUids.length} students for class ${classId}`);

    // 2. For each student UID, get their FCM token from the 'users' table
    const tokenPromises = studentUids.map(async (uid) => {
      const userSnapshot = await admin.database().ref(`users/${uid}`).once("value");
      const user = userSnapshot.val();
      return user?.fcmToken; // Return the token if it exists
    });

    // Wait for all token lookups to complete and filter out any null/undefined tokens
    const tokens = (await Promise.all(tokenPromises)).filter(
      (token) => token
    ) as string[];

    if (tokens.length === 0) {
      logger.info("No FCM tokens found for any students in class", classId);
      return;
    }

    logger.info(`Found ${tokens.length} tokens to send notifications to.`);

    // 3. Send the notification
    const payload = {
      notification: {
        title: `New ${post.type} in ${post.className || "your class"}`,
        body: post.title,
      },
    };

    try {
      const response = await admin.messaging().sendEachForMulticast({tokens, ...payload});
      logger.info("Successfully sent message:", response);
    } catch (error) {
      logger.error("Error sending message:", error);
    }
  }
);