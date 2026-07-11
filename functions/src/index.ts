import { initializeApp } from "firebase-admin/app";

initializeApp();

export { onRequirementCreated } from "./onRequirementCreated";
export { clearInvalidFcmTokens } from "./cleanupInvalidTokens";
