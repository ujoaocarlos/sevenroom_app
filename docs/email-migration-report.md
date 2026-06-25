# Relatório de Migração de E-mails

## Etapa 1 - Auditoria

Foram encontradas duas Cloud Functions relacionadas a e-mail na antiga pasta `functions/`:

- `sendReservationCreatedEmail`
  - Gatilho: criação de documento em `reservations/{reservationId}`.
  - Payload: documento Firestore da reserva (`roomId`, `userId`, `responsavelNome`, `status`, `data`, `horaInicio`, `horaFim`, `email`).
  - Destinatário: `reservation.email`.
  - Templates: solicitação recebida; reserva confirmada quando `status == aprovado`.
  - Resposta ao frontend: nenhuma, pois era gatilho assíncrono de Firestore.

- `sendReservationApprovedEmail`
  - Gatilho: atualização de documento em `reservations/{reservationId}`.
  - Payload: documento Firestore antes/depois da reserva.
  - Condição: status mudou para `aprovado`.
  - Destinatário: `reservation.email`.
  - Template: reserva autorizada.
  - Resposta ao frontend: nenhuma, pois era gatilho assíncrono de Firestore.

A pasta `functions/` foi removida e `firebase.json` não possui mais configuração de Firebase Functions.

## Etapa 2 - API Node.js

Foi criada a estrutura de backend:

```text
backend/
├── package.json
├── server.js
├── routes/
│   └── email.js
├── services/
│   └── firebaseAuthService.js
│   └── smtpService.js
└── .env.example
```

Endpoint implementado:

```http
POST /api/email/send
Authorization: Bearer TOKEN
Content-Type: application/json
```

Payload:

```json
{
  "to": "usuario@email.com",
  "subject": "Assunto",
  "html": "<p>Mensagem</p>"
}
```

Também aceita múltiplos destinatários em `to` como array.

Resposta de sucesso:

```json
{
  "success": true
}
```

## Etapa 3 - Gmail SMTP

O projeto foi ajustado para usar Gmail SMTP via `nodemailer`, sem Firebase Functions e sem Blaze. O serviço `backend/services/smtpService.js` usa:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASS`
- `EMAIL_FROM`

O remetente é configurado por `EMAIL_FROM`, com segredo mantido no backend/Render.

## Etapa 4 - Segurança

Implementado:

- validação de payload;
- limite de corpo JSON em `32kb`;
- rate limiting básico por IP;
- logs de erro no servidor;
- bloqueio de chamadas sem `Authorization: Bearer TOKEN`;
- variáveis de ambiente em `.env.example`.

O Flutter Web não embute `API_SECRET`. O app envia o ID token do Firebase do usuário logado. O backend valida esse token com Firebase Admin. `API_SECRET` permanece disponível apenas para chamadas server-to-server e testes.

## Etapa 5 - Frontend

Não havia `firebase.functions()`, `httpsCallable()` ou callable functions no frontend.

Foi criado `lib/services/email_service.dart`, que usa `http.post` para chamar:

```text
EMAIL_API_BASE_URL/api/email/send
```

O serviço é acionado:

- após criação de reserva em `ScheduleScreen`;
- após aprovação de reserva pelo admin em `AdminPanelScreen`.

As chamadas são best effort: se o e-mail falhar, a reserva continua criada/aprovada e o erro é registrado com `debugPrint`.

## Etapa 6 - Render

Foi criado `render.yaml` com:

- runtime Node;
- Node 20;
- `npm install`;
- `npm start`;
- variáveis `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `EMAIL_FROM`, `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `ALLOWED_ORIGINS`.

## Etapa 7 - Testes

Executados:

- `npm install` em `backend`: passou.
- `npm run check` em `backend`: passou.
- `dart format`: passou.
- `flutter pub get`: passou.
- `flutter analyze`: passou, sem issues.
- `GET /health`: passou com `{ "ok": true }`.
- `POST /api/email/send` sem token: retornou `401`.
- `POST /api/email/send` com payload inválido: retornou `400`.
- `POST /api/email/send` com destinatário inválido: retornou `400`.
- `POST /api/email/send` com destinatário simples e credencial de provedor falsa: retornou `502`, confirmando que passou pela API e falhou no provedor.
- `POST /api/email/send` com múltiplos destinatários e credencial de provedor falsa: retornou `502`, confirmando que o payload é aceito e falha apenas no provedor.
- Teste de carga leve com rate limit reduzido: retornou `429`.
- Envio real via Gmail SMTP usando Node 20: passou com `SMTP_SEND_OK`.

Pendentes por dependerem de deploy externo:

- deploy real no Render.
- envio real para múltiplos destinatários em produção.

Para concluir esses testes, configurar no Render:

- `SMTP_HOST`;
- `SMTP_PORT`;
- `SMTP_SECURE`;
- `SMTP_USER`;
- `SMTP_PASS`;
- `FIREBASE_PROJECT_ID`;
- `FIREBASE_SERVICE_ACCOUNT_JSON`;
- `EMAIL_FROM` com a conta remetente configurada.
