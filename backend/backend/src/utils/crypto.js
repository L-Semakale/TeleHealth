import crypto from "crypto";

const algorithm = "aes-256-cbc";

const getKey = () => {
  const raw = process.env.AES_ENCRYPTION_KEY || "";
  if (raw.length !== 32) {
    throw new Error("AES_ENCRYPTION_KEY must be 32 characters");
  }
  return Buffer.from(raw, "utf-8");
};

export const encrypt = (plainText) => {
  const iv = crypto.randomBytes(16);
  const key = getKey();
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  const encrypted = Buffer.concat([cipher.update(plainText, "utf8"), cipher.final()]);
  return `${iv.toString("hex")}:${encrypted.toString("hex")}`;
};

export const decrypt = (cipherText) => {
  const [ivHex, encryptedHex] = cipherText.split(":");
  const iv = Buffer.from(ivHex, "hex");
  const encryptedText = Buffer.from(encryptedHex, "hex");
  const key = getKey();
  const decipher = crypto.createDecipheriv(algorithm, key, iv);
  const decrypted = Buffer.concat([decipher.update(encryptedText), decipher.final()]);
  return decrypted.toString("utf8");
};
