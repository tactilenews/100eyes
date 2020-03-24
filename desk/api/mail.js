import express from 'express'
import { createTransport } from 'nodemailer'
const app = express()
app.use(express.json())

app.post('/', async (req, res) => {
  const {
    body: { subject, text }
  } = req
  const from = '"100eyes" <100eyes@example.org>'
  const to = 'audience@newspaper.example.org'

  const transporter = createTransport({
    host: 'mailserver',
    // TODO: ignore only in development environment
    ignoreTLS: true,
    port: 25,
    secure: false
  })
  await transporter.sendMail({
    from,
    to,
    subject,
    text
  })
})

export default {
  path: '/api/mail',
  handler: app
}
