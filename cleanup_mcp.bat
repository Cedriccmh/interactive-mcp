@echo off
echo Cleaning up zombie MCP processes...
wmic process where "commandline like '%%interactive-mcp%%'" call terminate >nul 2>&1
wmic process where "commandline like '%%mcp-sequentialthinking%%'" call terminate >nul 2>&1

echo Done!
