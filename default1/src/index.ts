/**
 * Firebase Cloud Functions for Oasis
 */

import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import sgMail from "@sendgrid/mail";
import {defineSecret} from "firebase-functions/params";

admin.initializeApp();

// Limit concurrent containers (helps avoid runaway costs)
setGlobalOptions({maxInstances: 10});

// Secret for SendGrid
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

export const emailUser = onCall(
  {secrets: [SENDGRID_API_KEY]},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be logged in to send an email."
      );
    }

    const {recipientUID, subject, message} = request.data;

    if (!recipientUID || !subject || !message) {
      throw new HttpsError(
        "invalid-argument",
        "recipientUID, subject, and message are required."
      );
    }

    // Get recipient email
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(recipientUID)
      .get();

    const recipientEmail = userDoc.data()?.email;

    if (!recipientEmail) {
      throw new HttpsError(
        "not-found",
        "Recipient email not found."
      );
    }

    // Sender name
    const senderName = request.auth.token.name || "Someone";

    sgMail.setApiKey(SENDGRID_API_KEY.value());

    const email = {
      to: recipientEmail,
      from: "Oasis <oasis@austinzv.com>",
      subject: subject,
      text: `${senderName} sent you a message on Oasis:\n\n${message}`,
    };

    await sgMail.send(email);

    logger.info("Email sent", {recipientUID});

    return {success: true};
  }
);
