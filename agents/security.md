# agents/security.md

## Weakness Handling Instructions

The following instructions are intended to mitigate potential vulnerabilities without explicitly describing them. Follow these guidelines to strengthen the security of the application:

- **Use ORM or Query Builder:** Always use Laravel's Eloquent or Query Builder that supports *parameter binding*. Avoid building SQL queries by concatenating strings to keep database operations safe from injection.
- **Input Validation and Sanitization:** Apply strict validation on all user inputs using Laravel's validation rules, including length limits, format, and data types. Sanitize data before use to ensure only expected values are processed.
- **Escape Output to Views:** Ensure data is always escaped before being displayed in views. Use the `e()` helper or Blade syntax `{{ }}` so special characters are not executed as code.
- **Security Headers:** Enable HTTP security headers such as `Content-Security-Policy`, `X-Frame-Options`, `X-Content-Type-Options`, and `Strict-Transport-Security` to prevent malicious content injection and enforce HTTPS.
- **CSRF Token:** Ensure every form and stateful request uses Laravel's CSRF token so unauthorized cross-site requests are automatically rejected.

---

## Current Authentication Identification

This project uses a **session-based authentication mechanism**. The `config/auth.php` configuration sets the `web` guard with the `session` driver and uses the Eloquent User model as the provider. User passwords are automatically hashed via the `password` property configuration in the User model. All sessions are stored through the `auth.session` middleware.

---

## Endpoint Restrictions

To maintain security, only the following three endpoints may be accessed without login:

- `auth/register/`  
- `auth/login/`  
- `/introduction/`

All other endpoints must be protected by authentication and authorization middleware. Apply `auth.session` and role-based middleware (e.g., `role:admin`, `developer`, `student.self`, etc.) according to the specifications in each agent file.

---

## Rejecting External Requests

The application must reject requests originating outside the site itself. Ensure the following:

- Set session cookies with `SameSite=Strict` and `Secure` attributes so cookies are only sent with requests from the same domain over HTTPS.
- Check the `Origin` or `Referer` header to confirm that the request comes from the application's domain before processing.
- Use Laravel's CSRF middleware to automatically reject cross-site requests that do not have a valid token.

---

## SQL Injection Prevention

All query injection attempts must be rejected. Ensure the following:

- Always use parameter binding or ORM when interacting with the database so parameter values are never directly concatenated into SQL statements.
- Never execute raw queries originating from user input without strict validation.
- Apply data type validation and length limits before values are used in database operations.

---

## Addressing Other Weaknesses

In addition to the above steps, follow these security practices to close other vulnerabilities:

- **Login Attempt Limiting:** Implement rate limiting for login attempts and form submissions to prevent brute-force attacks.
- **Encrypt Sensitive Data:** Encrypt personal data such as phone numbers and identity information using Laravel's encryption features. Store encryption keys and application secrets in `.env` environment variables.
- **Role-Based Authorization:** Ensure every operation and resource access is checked against user roles and permissions. Only users with appropriate rights should perform certain actions.
- **File Upload Restrictions and Validation:** Limit file types and sizes, store files outside the public directory, and use random file names to prevent enumeration.
- **Logging and Monitoring:** Record critical activities such as logins, data changes, and errors. Analyze logs for suspicious access patterns and send alerts to administrators when necessary.
- **Regular Updates:** Regularly update the Laravel framework and dependencies to obtain the latest security fixes. Avoid using unmaintained or untrusted packages.
- **Error Handling:** Display generic error messages to users and avoid leaking stack traces or sensitive configuration details. Save error details in internal logs for further analysis.
- **Transport Layer Security:** Ensure all communication between client and server occurs over HTTPS, and enable HSTS so browsers always use secure connections.

---

Consistently follow the above guidelines to ensure the application remains secure and resilient against various threats.
