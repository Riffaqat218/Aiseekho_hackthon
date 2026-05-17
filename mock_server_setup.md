# Wazifa Mock Server Setup Guide (Frontend Developer)

This guide explains how to spin up a local mock server using the auto-generated backend API contract (`swagger.json`). This allows you to build the frontend application and test the UI without waiting for the backend endpoints to be fully implemented.

## Prerequisites
- Node.js installed on your machine.

## Steps

1. **Locate the API Contract**
   Navigate to the `backend/` directory in this repository. You will see a file named `swagger.json`. This is the single source of truth for our API.

2. **Run Prism Mock Server**
   Use the `npx` command to start the Stoplight Prism mock server. Run this command inside the `backend/` directory:
   ```bash
   npx @stoplight/prism-cli mock swagger.json
   ```

3. **Use the Mock API**
   Prism will start a local server, typically at `http://127.0.0.1:4010`. You can point your Flutter application's base URL to this address.

   Examples:
   - `POST http://127.0.0.1:4010/api/v1/auth/login` (Returns `{ "accessToken": "mock-jwt-token" }`)
   - `GET http://127.0.0.1:4010/api/v1/chat/history` (Returns a mock array of chat history objects)

## Updating the Mock Data
If you need specific mock responses for UI edge cases (e.g., testing long AI replies), you can let me know, and I will add mock examples directly to the NestJS controllers which will update the `swagger.json` file.
