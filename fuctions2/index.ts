import {onCall, HttpsError} from "firebase-functions/v2/https";
import {onValueCreated} from "firebase-functions/v2/database";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import * as logger from "firebase-functions/logger";
import {database} from "firebase-functions/v2";


// Initialize the Admin SDK, but only if it hasn't been initialized before.
// This is important for preventing errors during deployment and local emulation.
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.database();
const auth = admin.auth();

/**
 * Interface for the data payload expected by the admitStudent function.
 * This provides strong typing for the incoming request data.
 */
interface StudentAdmissionData {
  email: string;
  password: string;
  fullName: string;
  classId: string;
  fatherName: string;
  motherName: string;
  fatherMobile: string;
  motherMobile: string;
  admissionYear: number | string;
  dob: string;
  gender: string;
  bloodGroup: string;
}

/**
 * Interface for the data payload for creating a new admin or teacher.
 */
interface NewUserData {
  email: string;
  password: string;
  fullName: string;
  role: "admin" | "teacher";
}

/**
 * Interface for the password reset function payload.
 */
interface PasswordResetData {
  email: string;
}

/**
 * Interface for the school configuration object stored in the database.
 * This provides strong typing for configuration values.
 */
interface SchoolConfig {
  studentIdPrefix?: string;
  locationCode?: string;
  branchCode?: string;
}

/**
 * An HttpsCallable function to admit a new student.
 * This function handles creating the Auth user and all associated database profiles
 * in a single, secure, and atomic transaction.
 */
export const admitStudent = onCall<StudentAdmissionData>(async (request) => {
  // 1. Security Check: Ensure the caller is an authenticated admin.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const callerUid = request.auth.uid;
  const callerProfileSnap = await db.ref(`/users/${callerUid}`).get();
  if (!callerProfileSnap.exists() || callerProfileSnap.val().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "You must be an administrator to perform this action.",
    );
  }

  // 2. Validate input data from the client
  const {
    email,
    password,
    fullName,
    fatherName,
    motherName,
    fatherMobile,
    motherMobile,
    classId,
    admissionYear,
    dob,
    gender,
    bloodGroup,
  } = request.data;
  if (!email || !password || !fullName || !classId || !fatherName ||
      !motherName || !fatherMobile || !motherMobile || !admissionYear || !dob || !gender) {
    throw new HttpsError(
      "invalid-argument",
      "Missing required fields for student admission. All fields are mandatory.",
    );
  }

  let newUserUid: string | null = null;

  try {
    // 3. Create the Firebase Auth user with email, password, and display name.
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: fullName,
    });
    newUserUid = userRecord.uid;

    // 4. Generate the unique student ID using a helper function.
    const newStudentId = await generateStudentId();

    // 5. Prepare the data for both profile locations.
    const userProfile = {
      email: email,
      name: fullName,
      role: "student",
      status: "active",
      image: "", // Will be updated by client if a photo is uploaded
      uid: newUserUid,
    };

    const studentProfile = {
      uid: newUserUid,
      studentId: newStudentId,
      email: email,
      fullName: fullName,
      fatherName: fatherName,
      motherName: motherName,
      fatherMobile: fatherMobile,
      motherMobile: motherMobile,
      classId: classId,
      admissionYear: admissionYear,
      dob: dob,
      gender: gender,
      bloodGroup: bloodGroup ?? "", // Allow empty string for blood group
      imageUrl: "", // Will be updated by client
      status: "active",
      rollNumber: null,
    };

    // 6. Use a multi-path update to write to the database atomically.
    const updates: {[key: string]: any} = {};
    updates[`/users/${newUserUid}`] = userProfile;
    updates[`/student_profiles/${newUserUid}`] = studentProfile;
    await db.ref().update(updates);

    // 7. Return the new UID and studentId to the client on success.
    return {uid: newUserUid, studentId: newStudentId};
  } catch (error) {
    // 8. Cleanup and Error Handling: If anything failed, delete the created Auth user.
    if (newUserUid) {
      await auth.deleteUser(newUserUid);
    }
    logger.error("Error in admitStudent function:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while admitting the student. Please try again.",
    );
  }
});

/**
 * An HttpsCallable function to create a new user (Admin or Teacher).
 * This is a privileged operation that can only be performed by an existing admin.
 */
export const createAdminOrTeacher = onCall<NewUserData>(async (request) => {
  // 1. Security Check: Ensure the caller is an authenticated admin.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "The function must be called while authenticated.",
    );
  }

  const callerUid = request.auth.uid;
  const callerProfileSnap = await db.ref(`/users/${callerUid}`).get();
  if (!callerProfileSnap.exists() || callerProfileSnap.val().role !== "admin") {
    throw new HttpsError(
      "permission-denied",
      "You must be an administrator to perform this action.",
    );
  }

  // 2. Validate input data from the client
  const {email, password, fullName, role} = request.data;
  if (!email || !password || !fullName || !role || (role !== "admin" && role !== "teacher")) {
    throw new HttpsError(
      "invalid-argument",
      "Missing or invalid required fields (email, password, fullName, role).",
    );
  }

  let newUserUid: string | null = null;

  try {
    // 3. Create the Firebase Auth user.
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: fullName,
    });
    newUserUid = userRecord.uid;

    // 4. Prepare the user profile data.
    const userProfile = {
      email: email,
      name: fullName,
      role: role, // 'admin' or 'teacher'
      status: "active",
      image: "",
      uid: newUserUid,
    };

    // 5. Create the profile in the Realtime Database.
    await db.ref(`/users/${newUserUid}`).set(userProfile);

    // 6. Return the new UID to the client on success.
    return {uid: newUserUid};
  } catch (error) {
    // 7. Cleanup and Error Handling.
    if (newUserUid) {
      await auth.deleteUser(newUserUid);
    }
    logger.error("Error in createAdminOrTeacher function:", error);
    throw new HttpsError(
      "internal",
      "An error occurred while creating the user. Please try again.",
    );
  }
});

/**
 * An HttpsCallable function to generate a password reset link for a user.
 * This is a privileged operation that can only be performed by an existing admin.
 */
export const createPasswordResetLink = onCall<PasswordResetData>(async (request) => {
      // 1. Security Check: Ensure the caller is an authenticated admin.
    if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "The function must be called while authenticated.",
        );
    }

    const callerUid = request.auth.uid;
    const callerProfileSnap = await db.ref(`/users/${callerUid}`).get();
    if (!callerProfileSnap.exists() || callerProfileSnap.val().role !== "admin") {
        throw new HttpsError(
            "permission-denied",
            "You must be an administrator to perform this action.",
        );
    }

    // 2. Validate input data from the client
    const {email} = request.data;
    if (!email) {
        throw new HttpsError(
            "invalid-argument",
            "Missing required 'email' field.",
        );
    }

    try {
        // 3. Generate the password reset link.
        const link = await auth.generatePasswordResetLink(email);

        // 4. Configure the email transporter using environment variables.
        const mailTransport = nodemailer.createTransport({
            service: "gmail",
            auth: {
                user: "your.email@gmail.com", // Replace with your email or use functions.config().gmail.email
                pass: "your-app-password", // Replace with your App Password or use functions.config().gmail.password
            },
        });

        // 5. Send the email.
        await mailTransport.sendMail({
            from: "\"Pole Star Academy\" <ravi.ranjan.bsy@gmail.com>",
            to: email,
            subject: "Your Password Reset Request",
            html: `
            <!DOCTYPE html>
            <html>
            <head>
              <style>
                body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
                .container { width: 90%; max-width: 600px; margin: 20px auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
                .header { background-color: #4A90E2; color: white; padding: 10px; text-align: center; border-radius: 5px 5px 0 0; }
                .content { padding: 20px; }
                .button { display: inline-block; background-color: #4A90E2; color: white !important; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-weight: bold; }
                .footer { font-size: 0.8em; color: #777; text-align: center; margin-top: 20px; }
              </style>
            </head>
            <body>
              <div class="container">
                <div class="header">
                  <h1>Password Reset</h1>
                </div>
                <div class="content">
                  <p>Hello,</p>
                  <p>We received a request to reset the password for your account at <strong>Your School Name</strong>.</p>
                  <p>Please click the button below to set a new password. This link is valid for one hour.</p>
                  <p style="text-align: center; margin: 30px 0;">
                    <a href="${link}" class="button">Reset Your Password</a>
                  </p>
                  <p>If you did not request a password reset, please ignore this email or contact support if you have concerns.</p>
                  <p>Thank you,<br>The Team at Your School Name</p>
                </div>
                <div class="footer">
                  <p>&copy; ${new Date().getFullYear()} Your School Name. All rights reserved.</p>
                </div>
              </div>
            </body>
            </html>
            `,
        });

        // 6. Return a success message to the client.
        return {message: `Password reset email sent to ${email}.`};
    } catch (error: any) {
        // 7. Error Handling.
        logger.error("Error in createPasswordResetLink function:", error);
        throw new HttpsError(
            "internal",
            "An error occurred while sending the password reset email.",
        );
    }
});

/**
 * Generates a unique student ID using a transactional counter.
 */
async function generateStudentId(): Promise<string> {
  const now = new Date();
  // Assumes academic year starts in April (month 3, 0-indexed)
  const academicYear = now.getMonth() < 3 ?
    `${now.getFullYear() - 1}-${now.getFullYear()}` :
    `${now.getFullYear()}-${now.getFullYear() + 1}`;

  const configSnap = await db.ref("school_config").get();
  const config: SchoolConfig = configSnap.exists() ? configSnap.val() : {};
  const prefix = config.studentIdPrefix ?? "SCHL";
  const locationCode = config.locationCode ?? "NA";
  const branchCode = config.branchCode ?? "NA";

  const counterRef = db.ref(`counters/admission_numbers/${academicYear}`);
  const transactionResult = await counterRef.transaction((currentValue) => {
    return (currentValue || 0) + 1;
  });

  if (!transactionResult.committed) {
    throw new Error("Failed to update student ID counter.");
  }

  const newCount = String(transactionResult.snapshot.val()).padStart(4, "0");
  return `${prefix}-${locationCode}-${branchCode}-S${newCount}`;
}

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
