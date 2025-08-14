# AIChatMacOS

**AIChatMacOS** is a native macOS application for conversing with large language models through the [OpenAI Chat Completions API](https://platform.openai.com/docs/guides/gpt).  The app provides a clean chat interface built in Swift for macOS while giving you full control over how requests are constructed and responses are interpreted.

## Features

- **Native macOS app** – written in Swift and SwiftUI.  It uses standard `AIChatMacOS.xcodeproj` and runs smoothly on Apple Silicon or Intel‑based Macs.
- **OpenAI integration** – sends your chat history to the OpenAI Chat Completions API.  The model used by default is `gpt‑4o‑mini`, but you can change it by modifying the `model` parameter in `OpenAIService`.
- **Structured JSON responses** – the app expects the AI to return a JSON object matching a universal schema.  A `SystemPromptBuilder` constructs a system prompt that embeds the schema and instructs the model to answer **only** in valid JSON.  If the AI returns malformed JSON, the client automatically retries once with a repair prompt.
- **Conversation context** – messages are modelled using the `ChatMessage` struct with roles (`system`, `user`, `assistant`, `developer`) and are preserved in memory during a chat session.  This allows multi‑turn conversations and supports advanced prompts such as developer hints for error correction.
- **Keychain‑based API key storage** – your OpenAI API key is retrieved via `KeychainHelper.shared.apiKey` so you don’t have to hard‑code it in the source.  You’ll be prompted to enter your API key the first time you run the app.
- **Localization** – many user‑facing strings are in Russian to make the app accessible to Russian‑speaking users.  The universal response schema contains metadata fields such as `language` to help clients know which language was used.
- **Extensible schema** – the universal JSON schema includes fields for answers, citations, follow‑up questions, clarifications, errors and metadata (e.g., confidence and language).  Because responses are returned as structured data, you can build rich features on top of the core chat (for example, displaying citations or follow‑up questions separately from the answer text).

## Getting started

1. **Clone the repository** and open `AIChatMacOS.xcodeproj` in Xcode.
2. **Add your OpenAI API key** – run the app once and open the **Settings** window; paste your key so it can be stored securely in the Keychain.
3. **Run the app** – build and run the project.  Enter your question in the chat field and press **Return** to send it to the AI.  The response will be displayed as soon as the request completes.

The project requires Xcode 15 or later and macOS 12 (Monterey) or later.  The `OpenAIService` uses async/await and the built‑in `URLSession` for HTTP requests, so earlier versions of Swift are not supported.
## Contributing

Contributions are welcome!  Feel free to open issues or pull requests to improve the UI, add features or support other language models.  When proposing changes to the universal schema, please ensure that your modifications remain backward‑compatible or bump the version string accordingly.

## License

This project is provided under the MIT License (see `LICENSE` for details).
