FROM ghcr.io/astral-sh/uv:0.13.9-python3.11-trixie-slim@sha256:839b8b68a4bf47933fbd4e64f2550fc6f36d7e15aceca8b1cc7e1ade1eb2f1c5

# Blender MCP server (community mcp-for-blender), run over stdio by VS Code. It connects to the
# add-on in the host's portable Blender through host.docker.internal.

ENV DISABLE_TELEMETRY=true \
    BLENDER_MCP_SAFE_MODE=1 \
    BLENDER_HOST=host.docker.internal \
    BLENDER_PORT=9876 \
    PATH="/opt/mcp/bin:${PATH}"

COPY requirements.txt /tmp/requirements.txt
RUN uv venv /opt/mcp --python /usr/local/bin/python3.11 \
    && uv pip install --python /opt/mcp/bin/python --require-hashes --no-cache \
        -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt \
    && useradd --create-home --uid 1000 mcp

USER mcp
ENTRYPOINT ["mcp-for-blender"]
