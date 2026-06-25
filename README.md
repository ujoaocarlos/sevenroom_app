# SevenRoom

SevenRoom é um aplicativo Flutter com Firebase para reserva de salas universitárias. Ele inclui autenticação, listagem de espaços, solicitação de reservas, painel administrativo, tema claro/escuro e regras de segurança no Firestore.

## Principais recursos

- Login com e-mail/senha, Google e Microsoft.
- Cadastro e perfil de usuário.
- Listagem de salas com capacidade, localização, disponibilidade e regras especiais.
- Reserva por data, horário e duração.
- Bloqueio de conflito de horário com travas de 30 minutos no Firestore.
- Reservas pendentes ou aprovadas conforme regra da sala.
- Painel admin para gerenciar salas e aprovar, recusar ou excluir reservas.
- Tema claro, escuro e seguir sistema.

## Stack

- Flutter 3 / Dart 3
- Firebase Auth
- Cloud Firestore
- Provider
- Shared Preferences

## Configuração

1. Instale as dependências:

```bash
flutter pub get
```

2. Configure o Firebase no projeto:

```bash
flutterfire configure
```

3. Publique regras e índices:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

4. Rode o app:

```bash
flutter run
```

## Estrutura de dados

Coleções usadas no Firestore:

- `users`: perfil do usuário e papel (`user` ou `admin`).
- `rooms`: salas cadastradas pelos administradores.
- `reservations`: reservas criadas pelos usuários.
- `reservationLocks`: travas por sala, data e faixa de 30 minutos para evitar dupla reserva.

## E-mails de reserva

O projeto usa uma API Node.js externa para enviar e-mails automáticos via Gmail SMTP:

- Ao criar uma reserva, o usuário recebe a confirmação da solicitação.
- Se a reserva já nascer aprovada, o usuário recebe confirmação da reserva.
- Quando o administrador muda uma reserva para `aprovado`, o usuário recebe o e-mail de autorização.

Configure as variáveis em `backend/.env`, usando `backend/.env.example` como base:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=sevenroom.app@gmail.com
SMTP_PASS=google-app-password
API_SECRET=optional-server-to-server-token
FIREBASE_PROJECT_ID=app-7room
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account"}
EMAIL_FROM=SevenRoom <sevenroom.app@gmail.com>
ALLOWED_ORIGINS=https://app-7room.web.app
RATE_LIMIT_PER_MINUTE=20
```

Para rodar localmente:

```bash
cd backend
npm install
npm start
```

No Flutter Web, informe apenas a URL do backend Render. O app usa o token de login Firebase do usuário, sem segredo embutido no frontend:

```bash
flutter build web --dart-define=EMAIL_API_BASE_URL=https://SEU-BACKEND.onrender.com
```

## Observações para produção

- Crie pelo menos um usuário admin manualmente no Firestore, alterando `users/{uid}.role` para `admin`.
- Revise os provedores de login habilitados no Firebase Console.
- Mantenha `firestore.rules` e `firestore.indexes.json` versionados e publicados.
- Configure `SMTP_USER`, `SMTP_PASS`, `EMAIL_FROM` e `FIREBASE_SERVICE_ACCOUNT_JSON` no Render antes de publicar o backend.
- Antes de vender ou implantar para cliente, rode `flutter analyze` e teste os fluxos de login, reserva, cancelamento e aprovação.
