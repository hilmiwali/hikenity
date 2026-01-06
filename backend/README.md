# Hikenity Backend Server

Payment processing server for Hikenity hiking app.

## Features
- Stripe payment intent creation
- Payment receipt retrieval
- Health check endpoints

## Environment Variables

Required:
- `STRIPE_SECRET_KEY` - Your Stripe secret key
- `PORT` - Server port (default: 4242)

## Installation

```bash
npm install
```

## Running Locally

```bash
npm start
```

## Running in Development (with auto-restart)

```bash
npm run dev
```

## API Endpoints

### Health Check
```
GET /
GET /health
```

### Create Payment Intent
```
POST /create-payment-intent
Body: { "amount": 1000 }
Response: { "clientSecret": "...", "paymentIntentId": "..." }
```

### Retrieve Receipt
```
POST /retrieve-receipt
Body: { "paymentIntentId": "pi_..." }
Response: { "receiptUrl": "https://..." }
```

## Deployment

### Railway
1. Push to GitHub
2. Connect Railway to your repo
3. Set environment variables in Railway dashboard
4. Deploy automatically

### Heroku
```bash
heroku create
heroku config:set STRIPE_SECRET_KEY=sk_test_...
git push heroku main
```

## License
ISC
