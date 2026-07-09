"use strict";

const express = require("express");
const { sendEmail } = require("../services/smtpService");
const {
  verifyFirebaseToken,
  getFirebaseUserRole,
} = require("../services/firebaseAuthService");

const router = express.Router();
const WINDOW_MS = 60 * 1000;
const MAX_REQUESTS = Number(process.env.RATE_LIMIT_PER_MINUTE || 20);
const attempts = new Map();

router.post("/send", authenticate, rateLimit, async (req, res) => {
  const validation = validatePayload(req);
  if (!validation.valid) {
    res.status(400).json({ success: false, error: validation.error });
    return;
  }

  try {
    await sendEmail(validation.email);
    res.json({ success: true });
  } catch (error) {
    console.error("Email send failed:", {
      code: error.code,
      message: error.message,
      response: error.response,
      to: req.body && req.body.to,
      subject: req.body && req.body.subject,
    });
    const payload = { success: false, error: "Failed to send email" };
    if (req.authenticatedWithApiSecret) {
      payload.details = {
        code: error.code,
        response: error.response,
        message: error.message,
      };
    }
    res.status(502).json(payload);
  }
});

async function authenticate(req, res, next) {
  const expectedToken = process.env.API_SECRET;
  const auth = req.get("authorization") || "";
  const token = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";

  if (!token) {
    res.status(401).json({ success: false, error: "Unauthorized" });
    return;
  }

  if (expectedToken && token === expectedToken) {
    req.authenticatedWithApiSecret = true;
    next();
    return;
  }

  try {
    req.user = await verifyFirebaseToken(token);
    req.userRole = await getFirebaseUserRole(req.user.uid);
    next();
  } catch (error) {
    console.error("Invalid auth token:", error.message);
    res.status(401).json({ success: false, error: "Unauthorized" });
  }
}

function rateLimit(req, res, next) {
  const key = req.ip || "unknown";
  const now = Date.now();
  const record = attempts.get(key) || { count: 0, resetAt: now + WINDOW_MS };

  if (now > record.resetAt) {
    record.count = 0;
    record.resetAt = now + WINDOW_MS;
  }

  record.count += 1;
  attempts.set(key, record);

  if (record.count > MAX_REQUESTS) {
    res.status(429).json({ success: false, error: "Too many requests" });
    return;
  }

  next();
}

function validatePayload(req) {
  const body = req.body;
  if (!body || typeof body !== "object") {
    return { valid: false, error: "Payload must be an object" };
  }

  if (req.authenticatedWithApiSecret) {
    return body.template
      ? validateTrustedTemplatePayload(body)
      : validateRawPayload(body);
  }

  return validateTemplatePayload(body, req);
}

function validateRawPayload(body) {
  const recipients = Array.isArray(body.to) ? body.to : [body.to];
  if (recipients.length === 0 || recipients.length > 10) {
    return { valid: false, error: "Provide between 1 and 10 recipients" };
  }

  if (!recipients.every(isValidEmail)) {
    return { valid: false, error: "Invalid recipient" };
  }

  if (typeof body.subject !== "string" || body.subject.trim().length === 0) {
    return { valid: false, error: "Subject is required" };
  }

  if (body.subject.length > 160) {
    return { valid: false, error: "Subject is too long" };
  }

  if (typeof body.html !== "string" || body.html.trim().length === 0) {
    return { valid: false, error: "HTML body is required" };
  }

  if (body.html.length > 20000) {
    return { valid: false, error: "HTML body is too large" };
  }

  return {
    valid: true,
    email: {
      to: recipients.map((recipient) => recipient.trim()),
      subject: body.subject,
      html: body.html,
    },
  };
}

function validateTemplatePayload(body, req) {
  const allowedTemplates = new Set([
    "reservation_created",
    "reservation_approved",
  ]);

  if (!allowedTemplates.has(body.template)) {
    return { valid: false, error: "Invalid email template" };
  }

  const reservation = body.reservation;
  if (!reservation || typeof reservation !== "object") {
    return { valid: false, error: "Reservation data is required" };
  }

  const userOwnsReservation = reservation.userId === req.user.uid;
  const isAdmin = req.userRole === "admin";
  if (!userOwnsReservation && !isAdmin) {
    return { valid: false, error: "Reservation does not belong to user" };
  }

  if (body.template === "reservation_approved" && !isAdmin) {
    return { valid: false, error: "Admin permission is required" };
  }

  if (req.user.email && userOwnsReservation && reservation.email !== req.user.email) {
    return { valid: false, error: "Reservation email does not match user" };
  }

  const validation = validateReservationData(reservation);
  if (!validation.valid) return validation;

  const email = buildReservationEmail(body.template, reservation);
  return { valid: true, email };
}

function validateTrustedTemplatePayload(body) {
  const allowedTemplates = new Set([
    "reservation_created",
    "reservation_approved",
  ]);

  if (!allowedTemplates.has(body.template)) {
    return { valid: false, error: "Invalid email template" };
  }

  const reservation = body.reservation;
  if (!reservation || typeof reservation !== "object") {
    return { valid: false, error: "Reservation data is required" };
  }

  const validation = validateReservationData(reservation);
  if (!validation.valid) return validation;

  return {
    valid: true,
    email: buildReservationEmail(body.template, reservation),
  };
}

function validateReservationData(reservation) {
  const requiredStrings = [
    "roomId",
    "roomDocId",
    "userId",
    "responsavelNome",
    "status",
    "email",
  ];

  for (const field of requiredStrings) {
    if (typeof reservation[field] !== "string" || reservation[field].trim() === "") {
      return { valid: false, error: `Reservation ${field} is required` };
    }
  }

  if (!isValidEmail(reservation.email)) {
    return { valid: false, error: "Invalid reservation email" };
  }

  if (!["aprovado", "pendente", "recusado", "cancelado"].includes(reservation.status)) {
    return { valid: false, error: "Invalid reservation status" };
  }

  for (const field of ["data", "horaInicio", "horaFim"]) {
    if (Number.isNaN(Date.parse(reservation[field]))) {
      return { valid: false, error: `Reservation ${field} is invalid` };
    }
  }

  return { valid: true };
}

function buildReservationEmail(template, reservation) {
  const isApproved = template === "reservation_approved";
  const subject = isApproved
    ? "Reserva autorizada - SevenRoom"
    : reservation.status === "aprovado"
      ? "Reserva confirmada - SevenRoom"
      : "Solicitação de reserva recebida - SevenRoom";
  const title = isApproved
    ? "Sua reserva foi autorizada"
    : reservation.status === "aprovado"
      ? "Sua reserva foi confirmada"
      : "Recebemos sua solicitação de reserva";
  const intro = isApproved
    ? "Um administrador aprovou sua reserva. Confira os detalhes abaixo:"
    : reservation.status === "aprovado"
      ? "Sua reserva foi criada e confirmada automaticamente. Confira os detalhes abaixo:"
      : "Sua solicitação foi registrada e será analisada por um administrador. Confira os detalhes abaixo:";

  return {
    to: reservation.email.trim(),
    subject,
    html: buildReservationHtml({ reservation, title, intro }),
  };
}

function buildReservationHtml({ reservation, title, intro }) {
  const date = formatDate(reservation.data);
  const start = formatTime(reservation.horaInicio);
  const end = formatTime(reservation.horaFim);

  return `
<div style="font-family: Arial, sans-serif; color: #1E2838; line-height: 1.5;">
  <h2 style="color: #1D51A1;">${escapeHtml(title)}</h2>
  <p>${escapeHtml(intro)}</p>
  <table style="border-collapse: collapse; margin-top: 16px;">
    ${detailRow("Sala", reservation.roomId)}
    ${detailRow("Responsável", reservation.responsavelNome)}
    ${detailRow("Data", date)}
    ${detailRow("Horário", `${start} - ${end}`)}
    ${detailRow("Status", statusLabel(reservation.status))}
  </table>
  <p style="margin-top: 24px; color: #7A7F85; font-size: 13px;">SevenRoom</p>
</div>
`;
}

function detailRow(label, value) {
  return `
<tr>
  <td style="padding: 6px 16px 6px 0; color: #7A7F85;">${escapeHtml(label)}</td>
  <td style="padding: 6px 0; font-weight: 700;">${escapeHtml(value)}</td>
</tr>
`;
}

function formatDate(value) {
  return new Intl.DateTimeFormat("pt-BR", {
    timeZone: "America/Bahia",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));
}

function formatTime(value) {
  return new Intl.DateTimeFormat("pt-BR", {
    timeZone: "America/Bahia",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

function statusLabel(status) {
  switch (status) {
    case "aprovado":
      return "Aprovada";
    case "pendente":
      return "Pendente";
    case "recusado":
      return "Recusada";
    case "cancelado":
      return "Cancelada";
    default:
      return status;
  }
}

function escapeHtml(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function isValidEmail(value) {
  return (
    typeof value === "string" &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim())
  );
}

module.exports = router;
