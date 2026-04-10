# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

interactive-mcp is a Model Context Protocol (MCP) server that enables interactive communication between LLMs and users through local OS interfaces. The server runs locally alongside MCP clients (Claude Desktop, VS Code, Cursor) and provides tools for user input, notifications, and persistent chat sessions.

## Development Commands

```bash
# Install dependencies (uses pnpm)
pnpm install

# Build the project (TypeScript compilation + path alias resolution)
pnpm build

# Run the server (after building)
pnpm start

# Lint code
pnpm lint

# Format code
pnpm format

# Type checking only (no output)
pnpm check-types
```

## Architecture

### Core Components

**MCP Server (src/index.ts)**

- Entry point that initializes the MCP server with StdioServerTransport
- Parses CLI arguments for timeout and tool disabling
- Conditionally registers tools based on command-line flags
- Manages active intensive chat sessions via Map

**Tool Definitions (src/tool-definitions/)**

- Modular tool definitions following ToolDefinition interface
- Each tool exports: capability (for server initialization), description (for registration), and schema (Zod validation)
- Tools: request_user_input, message_complete_notification, intensive_chat (start/ask/stop)

**Commands Layer (src/commands/)**

- `input/`: Platform-specific UI spawning for user input prompts
- `intensive-chat/`: Session management for persistent chat interactions
- Uses file-based IPC (temp files) with heartbeat mechanism for process monitoring

**UI Components (src/ui/ and src/components/)**

- Built with React and Ink for terminal-based interfaces
- InteractiveInput component handles user input with predefined options
- Spawned as detached processes with platform-specific launchers

### Key Architectural Decisions

**Platform-Specific Process Spawning**

- macOS: AppleScript to launch Terminal.app with fallback to .command file + open
- Windows: Detached spawn with windowsHide: false
- Linux: Standard detached spawn
- Rationale: Different OS terminals require different activation methods

**Heartbeat File Mechanism**

- UI processes write heartbeat files at regular intervals
- Parent process monitors heartbeat file modification time
- Detects process crashes/exits even when detached
- 60s initial grace period for slow terminal launches

**Modular Tool Registration**

- Tools defined separately in tool-definitions/ directory
- Server filters and registers only enabled tools
- Supports grouping (e.g., intensive_chat disables all three intensive chat tools)
- Makes tool management and testing easier

**TypeScript Path Aliases**

- `@/*` maps to `src/*` via tsconfig paths
- Requires tsc-alias for post-compilation resolution
- Import example: `import { constant } from '@/constants.js'`

**Timeout Handling**

- Global timeout configurable via CLI (-t flag)
- Each tool can use the global timeout
- Returns `__TIMEOUT__` sentinel value on timeout
- Server translates to user-friendly message

## Code Structure

```
src/
├── index.ts                    # MCP server initialization & tool registration
├── constants.ts                # Shared constants (timeouts, etc.)
├── tool-definitions/           # Tool schemas and capabilities
│   ├── types.ts               # TypeScript interfaces for tools
│   ├── request-user-input.ts
│   ├── message-complete-notification.ts
│   └── intensive-chat.ts
├── commands/                   # Business logic for each tool
│   ├── input/                 # User input with platform-specific spawning
│   └── intensive-chat/        # Session management
├── ui/                        # Ink-based terminal UI entry points
├── components/                # React components for UI
└── utils/
    └── logger.ts              # Pino logger configuration
```

## Working with Tools

### Adding a New Tool

1. Define tool in `src/tool-definitions/new-tool.ts`:

   ```typescript
   export const newTool: ToolDefinition = {
     capability: { description: "...", parameters: {...} },
     description: "...",
     schema: { /* Zod schema */ }
   };
   ```

2. Add to `allToolCapabilities` in `src/index.ts`

3. Register in `src/index.ts` with `server.tool()`:

   ```typescript
   if (isToolEnabled('new_tool')) {
     server.tool(
       'new_tool',
       newTool.description,
       newTool.schema,
       async (args) => {
         /* implementation */
       },
     );
   }
   ```

4. Implement business logic in `src/commands/` if needed

### Disabling Tools

Tools can be disabled via CLI:

```bash
# Disable single tool
node dist/index.js --disable-tools request_user_input

# Disable multiple tools
node dist/index.js -d "message_complete_notification,intensive_chat"
```

## AI Assistant Guidelines

When working with this codebase as an AI assistant:

- Use the `request_user_input` MCP tool to ask clarifying questions during development
- Always ask for clarification when requirements are uncertain
- Update `.notes/` folder when learning something significant (see `.notes/README.md`)
- Respect the modular tool definition pattern when adding features
- Test on target platform when modifying platform-specific spawning logic
