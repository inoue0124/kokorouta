import * as admin from "firebase-admin";

admin.initializeApp();

export { generateTanka } from "./generateTanka";
export { fetchFeed } from "./fetchFeed";
export { fetchMyTanka } from "./fetchMyTanka";
export { likeTanka } from "./likeTanka";
export { unlikeTanka } from "./unlikeTanka";
export { reportTanka } from "./reportTanka";
export { blockUser } from "./blockUser";
export { unblockUser } from "./unblockUser";
export { fetchBlockedUsers } from "./fetchBlockedUsers";
export { deleteAccount } from "./deleteAccount";
