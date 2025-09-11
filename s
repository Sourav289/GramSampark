import imaplib
import email
from email.header import decode_header
import openai

# OpenAI API key
openai.api_key = 'your-openai-api-key'

# Email credentials
EMAIL = 'your-email@example.com'
PASSWORD = 'your-email-password'
IMAP_SERVER = 'imap.gmail.com'  # For Gmail

def clean(text):
    return "".join(c if c.isalnum() else "_" for c in text)

def fetch_emails(n=5):
    mail = imaplib.IMAP4_SSL(IMAP_SERVER)
    mail.login(EMAIL, PASSWORD)
    mail.select("inbox")

    result, data = mail.search(None, "ALL")
    mail_ids = data[0].split()
    fetched_emails = []

    for i in mail_ids[-n:]:  # Get the last n emails
        result, message_data = mail.fetch(i, "(RFC822)")
        raw_email = message_data[0][1]
        msg = email.message_from_bytes(raw_email)

        subject, encoding = decode_header(msg["Subject"])[0]
        if isinstance(subject, bytes):
            subject = subject.decode(encoding or "utf-8")

        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                if content_type == "text/plain":
                    body = part.get_payload(decode=True).decode()
                    break
        else:
            body = msg.get_payload(decode=True).decode()

        fetched_emails.append({"subject": subject, "body": body})

    mail.logout()
    return fetched_emails

def summarize_text(text, max_tokens=100):
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "user", "content": f"Summarize this email:\n\n{text}"}],
        max_tokens=max_tokens,
        temperature=0.5
    )
    return response.choices[0].message['content'].strip()

def main():
    emails = fetch_emails(3)
    for i, email_data in enumerate(emails):
        print(f"\n📨 Email {i+1} - {email_data['subject']}")
        summary = summarize_text(email_data['body'])
        print(f"📝 Summary:\n{summary}")

if __name__ == "__main__":
    main()
